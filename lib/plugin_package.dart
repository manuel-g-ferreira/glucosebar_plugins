import 'dart:io';

import 'package:path/path.dart' as p;

const String glucosePluginExtension = '.glucoseplugin';

String pluginPackageFileName(String identifier) =>
    '$identifier$glucosePluginExtension';

bool isPluginPackageFile(String path) {
  if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
    return false;
  }
  return path.toLowerCase().endsWith(glucosePluginExtension);
}
