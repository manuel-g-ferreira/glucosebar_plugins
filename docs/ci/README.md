# GlucoseBar Plugins CI & releases

## Workflows

Modular layout — shared jobs live in reusable workflows; entry points only wire triggers.

| Workflow | When it runs | Role |
|----------|----------------|------|
| [plugins.yml](../../.github/workflows/plugins.yml) | PR and push to `main` | Quality checks + cross-platform plugin builds |
| [prepare-release.yml](../../.github/workflows/prepare-release.yml) | Manual (**Run workflow**) | Opens a `release/*` PR (version + changelog, no tag) |
| [finish-release.yml](../../.github/workflows/finish-release.yml) | `release/*` PR merged to `main` | Tags merge commit, runs **Release** |
| [release.yml](../../.github/workflows/release.yml) | Chained from Finish release, or manual | Quality + plugin builds + GitHub Release |
| [quality.yml](../../.github/workflows/quality.yml) | *(reusable only)* | Formatting and unit tests |
| [build-plugins.yml](../../.github/workflows/build-plugins.yml) | *(reusable only)* | MockCGM / LibreLink / Nightscout build matrix + protocol smoke |

Desktop app CI and releases run in [glucosebar](https://github.com/manuel-g-ferreira/glucosebar).

## Release channels

### Stable

- **Tag:** `v1.0.0`, `v1.0.1`, … (semver, no suffix)
- **GitHub:** normal release (`prerelease: false`)

### Beta

- **Tag:** `v1.1.0-beta.1`, `v1.1.0-beta.2`, …
- **GitHub:** pre-release (`prerelease: true`)

## Creating a release (maintainers)

### Recommended flow (works with branch protection)

1. Open **Actions** → **Prepare release** → **Run workflow**
2. Choose **channel** (`stable` or `beta`) and **bump** (`patch`, `minor`, `major`)
3. Review the opened **Release X.Y.Z** pull request (branch `release/X.Y.Z`)
4. **Merge** the PR when ready

After merge, **Finish release** automatically:

- Creates and pushes tag `vX.Y.Z`
- Runs **Release** (quality → plugin builds → `.glucoseplugin` assets → GitHub Release)

No direct push to `main` from Actions.

Optional: add notes under `## [Unreleased]` before step 1, or edit the `release/*` branch before merging.

### Recovery

If **Release** fails after the tag exists: **Actions** → **Release** → **Run workflow** and enter the tag (e.g. `v1.0.4-beta.1`).

### Manual release (advanced)

<details>
<summary>Without Prepare release workflow</summary>

1. PR with version bump + changelog to `main`, merge
2. `git tag vX.Y.Z && git push origin vX.Y.Z`
3. Dispatch **Release** with that tag if the tag push did not start it

</details>

## Local CI (before push)

```bash
chmod +x tool/ci_local.sh   # once
./tool/ci_local.sh
```

Covers the same steps as the **Quality checks** CI job plus local protocol smoke (when supported on your OS).

## Release tooling

Release automation lives in `tool/release.dart` (Dart CLI). Common commands:

```bash
dart run tool/release.dart prepare --channel stable --bump patch --no-tag
dart run tool/release.dart tag
dart run tool/release.dart changelog extract 1.0.0
dart run tool/release.dart publish stage --dist dist --output release
```

Run `dart pub get` (or CI **dart-setup**) before `dart run tool/release.dart`.

## CI jobs

| Job | Runner | Steps |
|-----|--------|-------|
| **Quality checks** | `ubuntu-latest` | format → unit tests |
| **Plugin build (macOS / Windows / Linux)** | matrix | compile plugin binaries |
| **Protocol smoke** | `ubuntu-latest` | build all plugins → `getPluginInfo` smoke |

Release runs the same reusable jobs with packaging enabled, then publishes versioned `.glucoseplugin` assets on a GitHub Release.

## Version alignment check

Release workflow validates:

```text
tag v1.2.3  →  pubspec version 1.2.3  (exact match)
```

Mismatch → failed release.

All first-party plugins are versioned together with the repo tag (monorepo release).

## Release assets

Each platform ships a versioned `.glucoseplugin` file. Each file has a **`.sha256` sidecar** on the same GitHub Release.

Naming pattern (same idea as GlucoseBar app archives):

```text
GlucoseBarPlugins-{version}-{plugin-id}-{platform}.glucoseplugin
GlucoseBarPlugins-{version}-{plugin-id}-{platform}.glucoseplugin.sha256
```

Examples for `1.0.1-beta.1`:

| Plugin | macOS | Windows | Linux |
|--------|-------|---------|-------|
| MockCGM | `GlucoseBarPlugins-1.0.1-beta.1-mockcgm-macos.glucoseplugin` | `…-windows.glucoseplugin` | `…-linux.glucoseplugin` |
| LibreLink | `…-librelink-macos.glucoseplugin` | `…-windows.glucoseplugin` | `…-linux.glucoseplugin` |
| Nightscout | `…-nightscout-macos.glucoseplugin` | `…-windows.glucoseplugin` | `…-linux.glucoseplugin` |

**Note:** GitHub Actions **workflow artifacts** are for CI debugging — not for end users. Download assets from the **GitHub Release** page instead.

Install into GlucoseBar via Settings → Plugins or `dart run tool/install_plugin.dart` from the app repo.

## Not in CI (MVP)

- macOS notarization for plugin binaries (ad-hoc codesign on macOS runners only)
- Automated plugin catalog sync into the GlucoseBar app repo
