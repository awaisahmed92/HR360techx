import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class CalendarState extends ChangeNotifier {
  CalendarState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  int tab = 0;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> types = [];
  Map<String, dynamic> overlays = {};
  Map<String, dynamic> settings = {};
  Map<String, dynamic> reports = {};
  String? icsToken;
  String? googleConnectUrl;
  Set<String> overlayToggles = {
    'leave',
    'holiday',
    'birthday',
    'anniversary',
    'training',
    'interview',
  };

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
    load();
  }

  void toggleOverlay(String key) {
    if (overlayToggles.contains(key)) {
      overlayToggles.remove(key);
    } else {
      overlayToggles.add(key);
    }
    notifyListeners();
  }

  void selectDay(DateTime day, DateTime focused) {
    selectedDay = day;
    focusedDay = focused;
    notifyListeners();
  }

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    final from = DateTime(focusedDay.year, focusedDay.month, 1);
    final to = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final fromS = _d(from);
    final toS = _d(to);
    try {
      final results = await Future.wait([
        _api.dio.get('/calendar/feed', queryParameters: {'from': fromS, 'to': toS}),
        _api.dio.get('/calendar/overlays', queryParameters: {'from': fromS, 'to': toS}),
        _api.dio.get('/calendar/events'),
        _api.dio.get('/calendar/meetings'),
        _api.dio.get('/calendar/types'),
        _api.dio.get('/calendar/settings'),
        _api.dio.get('/calendar/reports', queryParameters: {'month': '${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}'}),
      ]);
      final feed = results[0].data;
      if (feed is Map && feed['success'] == true) {
        events = ((feed['events'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        meetings = ((feed['meetings'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final ov = results[1].data;
      if (ov is Map && ov['success'] == true) {
        overlays = asStringKeyedMap(ov['overlays']);
      }
      final ev = results[2].data;
      if (ev is Map && ev['success'] == true) {
        events = ((ev['events'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final mt = results[3].data;
      if (mt is Map && mt['success'] == true) {
        meetings = ((mt['meetings'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final ty = results[4].data;
      if (ty is Map && ty['success'] == true) {
        types = ((ty['types'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final st = results[5].data;
      if (st is Map && st['success'] == true) {
        settings = asStringKeyedMap(st['settings']);
        final defs = settings['default_overlays'];
        if (defs is List && defs.isNotEmpty) {
          overlayToggles = defs.map((e) => '$e').toSet();
        }
      }
      final rp = results[6].data;
      if (rp is Map && rp['success'] == true) {
        reports = asStringKeyedMap(rp['reports']);
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> saveEvent(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/calendar/events', data: body)
          : await _api.dio.post('/calendar/events/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteEvent(int id) async {
    try {
      await _api.dio.post('/calendar/events/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveMeeting(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/calendar/meetings', data: body)
          : await _api.dio.post('/calendar/meetings/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        final tm = d['teams_message'];
        return tm == null ? null : tm.toString();
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteMeeting(int id) async {
    try {
      await _api.dio.post('/calendar/meetings/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveSettings(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/calendar/settings', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<void> loadIcsToken({bool regenerate = false}) async {
    try {
      final res = regenerate
          ? await _api.dio.post('/calendar/ics-token', data: {'regenerate': true})
          : await _api.dio.get('/calendar/ics-token');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        icsToken = d['token']?.toString();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadGoogleConnect() async {
    try {
      final res = await _api.dio.get('/calendar/google/connect');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        googleConnectUrl = d['url']?.toString();
      } else {
        googleConnectUrl = null;
        error = (d is Map ? d['message'] : null)?.toString();
      }
      notifyListeners();
    } on DioException catch (e) {
      googleConnectUrl = null;
      error = _msg(e);
      notifyListeners();
    }
  }

  Future<String?> googleSync() async {
    try {
      final res = await _api.dio.post('/calendar/google/sync');
      final d = res.data;
      await load();
      return (d is Map ? d['message'] : null)?.toString() ?? 'Synced';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  List<Map<String, dynamic>> itemsForDay(DateTime day) {
    final key = _d(day);
    final out = <Map<String, dynamic>>[];
    for (final e in events) {
      final s = '${e['start_at'] ?? ''}';
      if (s.startsWith(key)) out.add({...e, 'kind': 'event'});
    }
    for (final m in meetings) {
      if ('${m['meeting_date']}' == key) out.add({...m, 'kind': 'meeting'});
    }
    for (final k in overlayToggles) {
      final list = overlays[k];
      if (list is! List) continue;
      for (final item in list) {
        final map = asStringKeyedMap(item);
        if ('${map['date']}' == key || '${map['datetime']}'.startsWith(key)) {
          out.add({...map, 'kind': k});
        }
      }
    }
    return out;
  }

  String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _msg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    return e.message ?? 'Network error';
  }
}
