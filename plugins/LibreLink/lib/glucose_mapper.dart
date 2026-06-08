import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/services/graph_service.dart';

/// Maps LibreLink `GlucoseItem` JSON to GlucoseBar plugin protocol fields.
abstract final class GlucoseMapper {
  static FetchReadingsResult snapshotFromGraph(
    Map<String, dynamic> graph, {
    required int hours,
  }) {
    final current = _currentFromGraph(graph);
    if (current == null) {
      throw LluException('No current glucose reading');
    }
    return FetchReadingsResult(
      current: current,
      history: historyFromGraph(graph, hours: hours),
    );
  }

  static Map<String, dynamic>? _currentFromGraph(Map<String, dynamic> graph) {
    final connection = graph['connection'];
    Map<String, dynamic>? measurement;
    if (connection is Map<String, dynamic>) {
      measurement = connection['glucoseMeasurement'] as Map<String, dynamic>?;
      measurement ??= connection['glucoseItem'] as Map<String, dynamic>?;
    }
    return toProtocolReading(measurement);
  }

  static List<Map<String, dynamic>> historyFromGraph(
    Map<String, dynamic> graph, {
    required int hours,
  }) {
    final graphData = graph['graphData'];
    if (graphData is! List) {
      return [];
    }
    final clampedHours = hours.clamp(1, 24);
    final cutoff = DateTime.now().toUtc().subtract(
          Duration(hours: clampedHours),
        );
    final readings = <Map<String, dynamic>>[];
    for (final item in graphData) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final mapped = toProtocolReading(item);
      if (mapped == null) {
        continue;
      }
      final ts = DateTime.parse(mapped['timestamp'] as String);
      if (ts.isBefore(cutoff)) {
        continue;
      }
      readings.add(mapped);
    }
    readings.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );
    return readings;
  }

  static Map<String, dynamic>? toProtocolReading(Map<String, dynamic>? item) {
    if (item == null) {
      return null;
    }
    final special = _specialValue(item);
    final mgdl = item['ValueInMgPerDl'];
    if (special == null && mgdl is! num) {
      return null;
    }
    final timestamp = _parseTimestamp(item);
    if (timestamp == null) {
      return null;
    }
    return {
      'value': special == null ? (mgdl as num).round() : 0,
      'trend': _mapTrend(item['TrendArrow']),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'specialValue': special,
    };
  }

  static String? _specialValue(Map<String, dynamic> item) {
    final type = item['type'];
    final value = item['ValueInMgPerDl'];
    if (value is num) {
      if (value <= 0) {
        return 'LO';
      }
      if (value >= 501) {
        return 'HI';
      }
    }
    if (type == 2) {
      return 'LO';
    }
    if (type == 1) {
      return 'HI';
    }
    return null;
  }

  static DateTime? _parseTimestamp(Map<String, dynamic> item) {
    final factory = item['FactoryTimestamp'];
    if (factory is String && factory.isNotEmpty) {
      final normalized = factory.contains('UTC') || factory.endsWith('Z')
          ? factory.replaceFirst(' UTC', 'Z').replaceFirst(' ', 'T')
          : '${factory.replaceFirst(' ', 'T')}Z';
      try {
        return DateTime.parse(normalized);
      } on Object {
        // fall through
      }
    }
    final display = item['Timestamp'];
    if (display is String && display.isNotEmpty) {
      try {
        return DateTime.parse(display);
      } on Object {
        return null;
      }
    }
    return null;
  }

  static String _mapTrend(Object? arrow) {
    return switch (arrow) {
      1 => 'singleDown',
      2 => 'fortyFiveDown',
      3 => 'flat',
      4 => 'fortyFiveUp',
      5 => 'singleUp',
      _ => 'notComputable',
    };
  }
}
