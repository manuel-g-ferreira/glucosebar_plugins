// LibreLink Up — JSON line protocol v1.
// Build: dart run tool/glucose_plugin.dart build plugins/LibreLink
import 'dart:convert';
import 'dart:io';

import 'package:librelink_plugin/protocol_dispatch.dart';

void main() {
  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
    if (line.trim().isEmpty) {
      return;
    }
    try {
      final request = jsonDecode(line) as Map<String, dynamic>;
      final response = await ProtocolDispatch.dispatch(request);
      stdout.writeln(jsonEncode(response));
    } on Object catch (e) {
      stdout.writeln(jsonEncode({'success': false, 'error': e.toString()}));
    }
  });
}
