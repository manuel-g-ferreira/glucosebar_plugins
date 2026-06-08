# glucosebar_plugins

First-party CGM plugins for [GlucoseBar](https://github.com/manuel-g-ferreira/glucosebar).

Plugins are standalone Dart executables that communicate with the host app via [JSON line protocol v1](https://github.com/manuel-g-ferreira/glucosebar/blob/main/docs/plugins/PLUGIN-PROTOCOL-V1.md).

## Plugins

| Plugin | ID | Description |
|--------|-----|-------------|
| `plugins/MockCGM/` | `mockcgm` | Synthetic CGM for development and tests |
| `plugins/LibreLink/` | `librelink` | LibreLink Up integration |
| `plugins/Nightscout/` | `nightscout` | Nightscout integration |

## Local setup

Clone next to the app repo:

```text
Gluco/
├── glucosebar/
└── glucosebar_plugins/   ← this repo
```

## Build a plugin

```bash
dart pub get
dart run tool/glucose_plugin.dart build plugins/MockCGM
```

Produces `plugins/<Name>/bin/<platform-id>/<binary>` and optionally `dist/<id>.glucoseplugin`.

Skip packaging during CI-style builds:

```bash
dart run tool/glucose_plugin.dart build --no-package plugins/MockCGM
```

## Install into GlucoseBar

Build a `.glucoseplugin` package, then install from the **glucosebar** repo:

```bash
cd ../glucosebar
dart run tool/install_plugin.dart ../glucosebar_plugins/plugins/MockCGM/dist/mockcgm.glucoseplugin
```

Or drag the `.glucoseplugin` file into Settings → Plugins in the app.

## Local CI

See [docs/ci/README.md](docs/ci/README.md) — run the same `dart format`, `dart test`, and plugin build steps as the PR workflow.

## Docs

See [`docs/`](docs/) for authoring guides and vendor API notes. The host protocol contract lives in the glucosebar repo.
