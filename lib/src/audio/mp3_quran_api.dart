import 'dart:convert';

import 'package:http/http.dart' as http;

import '../riwayah.dart';

/// MP3Quran identifies these catalog entries separately. An unspecified Warsh
/// entry does not establish whether its reader follows Azraq or Asbahani.
enum Mp3QuranWarshRoute { unspecified, azraq, asbahani }

class Mp3QuranRiwayah {
  const Mp3QuranRiwayah({required this.id, required this.name});

  factory Mp3QuranRiwayah.fromJson(Map<String, dynamic> json) =>
      Mp3QuranRiwayah(
        id: _integer(json['id'], 'riwayah.id'),
        name: _string(json['name'], 'riwayah.name'),
      );

  final int id;
  final String name;

  QuranRiwayah? get supportedRiwayah => _supportedRiwayah(id);

  Mp3QuranWarshRoute? get warshRoute => _warshRoute(id);
}

/// Surah names from MP3Quran. Page numbers in that service describe its own
/// Madinah metadata and must not replace the displayed Warsh edition's pages.
class Mp3QuranSurah {
  const Mp3QuranSurah({required this.number, required this.name});

  factory Mp3QuranSurah.fromJson(Map<String, dynamic> json) => Mp3QuranSurah(
    number: _surahNumber(json['id'], 'surah.id'),
    name: _string(json['name'], 'surah.name'),
  );

  final int number;
  final String name;
}

/// A single recording collection. Available surahs come from `surah_list`,
/// rather than the reported total or an assumption that all readers are full.
class Mp3QuranMoshaf {
  Mp3QuranMoshaf({
    required this.id,
    required this.name,
    required Uri server,
    required Iterable<int> availableSurahs,
    this.riwayahId,
    this.moshafType,
    this.reportedSurahTotal,
  }) : server = _directory(server),
       availableSurahs = _availableSurahs(availableSurahs);

  factory Mp3QuranMoshaf.fromJson(Map<String, dynamic> json) {
    final list = _string(json['surah_list'], 'moshaf.surah_list');
    final surahs =
        list.trim().isEmpty
            ? <int>[]
            : list.split(',').map((entry) => _surahNumber(entry, 'surah_list'));
    return Mp3QuranMoshaf(
      id: _integer(json['id'], 'moshaf.id'),
      name: _string(json['name'], 'moshaf.name'),
      server: Uri.parse(_string(json['server'], 'moshaf.server')),
      availableSurahs: surahs,
      riwayahId: _optionalInteger(json['rewaya_id'], 'moshaf.rewaya_id'),
      moshafType: _optionalInteger(json['moshaf_type'], 'moshaf.moshaf_type'),
      reportedSurahTotal: _optionalInteger(
        json['surah_total'],
        'moshaf.surah_total',
      ),
    );
  }

  final int id;
  final String name;
  final Uri server;
  final int? riwayahId;
  final int? moshafType;
  final int? reportedSurahTotal;
  final List<int> availableSurahs;

  QuranRiwayah? get supportedRiwayah => _supportedRiwayah(riwayahId);

  Mp3QuranWarshRoute? get warshRoute => _warshRoute(riwayahId);

  bool get isComplete => availableSurahs.length == 114;

  bool hasSurah(int surahNumber) => availableSurahs.contains(surahNumber);

  /// Builds the streaming URL without requesting the MP3 file.
  Uri surahUri(int surahNumber) {
    _checkSurah(surahNumber);
    if (!hasSurah(surahNumber)) {
      throw SurahAudioUnavailableException(id, surahNumber);
    }
    return server.resolve('${surahNumber.toString().padLeft(3, '0')}.mp3');
  }

  /// Available surahs in Quran order; an incomplete collection stays incomplete.
  List<Uri> get playlist =>
      List<Uri>.unmodifiable(availableSurahs.map(surahUri));
}

class Mp3QuranReciter {
  Mp3QuranReciter({
    required this.id,
    required this.name,
    required Iterable<Mp3QuranMoshaf> moshafs,
    this.letter,
  }) : moshafs = List<Mp3QuranMoshaf>.unmodifiable(moshafs);

  factory Mp3QuranReciter.fromJson(Map<String, dynamic> json) =>
      Mp3QuranReciter(
        id: _integer(json['id'], 'reciter.id'),
        name: _string(json['name'], 'reciter.name'),
        letter: _optionalString(json['letter'], 'reciter.letter'),
        moshafs: _objects(
          json['moshaf'],
          'reciter.moshaf',
        ).map(Mp3QuranMoshaf.fromJson),
      );

  final int id;
  final String name;
  final String? letter;
  final List<Mp3QuranMoshaf> moshafs;
}

class Mp3QuranApiException implements Exception {
  const Mp3QuranApiException(this.message, {this.uri, this.statusCode});

  final String message;
  final Uri? uri;
  final int? statusCode;

  @override
  String toString() => 'Mp3QuranApiException: $message';
}

class SurahAudioUnavailableException implements Exception {
  const SurahAudioUnavailableException(this.moshafId, this.surahNumber);

  final int moshafId;
  final int surahNumber;

  @override
  String toString() =>
      'Surah $surahNumber is not listed in MP3Quran collection $moshafId.';
}

/// The official MP3Quran v3 JSON catalog. The client only sends GET requests to
/// catalog endpoints, never to recording URLs. Inject [client] for tests or an
/// app-specific HTTP implementation. An injected client remains caller-owned.
class Mp3QuranApi {
  Mp3QuranApi({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       baseUri = _directory(
         baseUri ?? Uri.parse('https://www.mp3quran.net/api/v3/'),
       );

  final http.Client _client;
  final bool _ownsClient;
  final Uri baseUri;
  final Duration timeout;
  bool _closed = false;

  Future<List<Mp3QuranRiwayah>> getRiwayat({String language = 'ar'}) =>
      _catalog('riwayat', 'riwayat', {
        'language': language,
      }, Mp3QuranRiwayah.fromJson);

  Future<List<Mp3QuranSurah>> getSurahs({String language = 'ar'}) => _catalog(
    'suwar',
    'suwar',
    {'language': language},
    Mp3QuranSurah.fromJson,
  );

  /// Filters are applied to individual recording collections as well as sent
  /// to the API, preventing a reader's other riwayat from entering the result.
  /// Use explicit IDs for Warsh paths: 2 (unspecified), 18 (Azraq), 10 (Asbahani).
  Future<List<Mp3QuranReciter>> getReciters({
    String language = 'ar',
    int? reciterId,
    int? riwayahId,
    int? surahNumber,
  }) async {
    if (reciterId != null && reciterId < 1) {
      throw RangeError.value(reciterId, 'reciterId', 'Must be positive');
    }
    if (riwayahId != null && riwayahId < 1) {
      throw RangeError.value(riwayahId, 'riwayahId', 'Must be positive');
    }
    if (surahNumber != null) _checkSurah(surahNumber);
    final query = <String, String>{
      'language': language,
      if (reciterId != null) 'reciter': '$reciterId',
      if (riwayahId != null) 'rewaya': '$riwayahId',
      if (surahNumber != null) 'sura': '$surahNumber',
    };
    final readers = await _catalog(
      'reciters',
      'reciters',
      query,
      Mp3QuranReciter.fromJson,
    );
    final result = <Mp3QuranReciter>[];
    for (final reciter in readers) {
      if (reciterId != null && reciter.id != reciterId) continue;
      final collections = reciter.moshafs.where(
        (collection) =>
            (riwayahId == null || collection.riwayahId == riwayahId) &&
            (surahNumber == null || collection.hasSurah(surahNumber)),
      );
      if (collections.isEmpty) continue;
      result.add(
        Mp3QuranReciter(
          id: reciter.id,
          name: reciter.name,
          letter: reciter.letter,
          moshafs: collections,
        ),
      );
    }
    return List<Mp3QuranReciter>.unmodifiable(result);
  }

  Future<List<T>> _catalog<T>(
    String endpoint,
    String key,
    Map<String, String> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    if (_closed) throw StateError('MP3Quran API is closed.');
    if (query['language']?.trim().isEmpty ?? true) {
      throw ArgumentError.value(
        query['language'],
        'language',
        'Cannot be empty',
      );
    }
    final uri = baseUri.resolve(endpoint).replace(queryParameters: query);
    final response = await _client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw Mp3QuranApiException(
        'Catalog request returned HTTP ${response.statusCode}.',
        uri: uri,
        statusCode: response.statusCode,
      );
    }
    try {
      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      // Materialize every model inside this boundary so malformed row fields
      // produce the same catalog failure as malformed JSON or top-level keys.
      return List<T>.unmodifiable(_objects(payload[key], key).map(parse));
    } on FormatException catch (error) {
      throw Mp3QuranApiException('Invalid catalog: ${error.message}', uri: uri);
    } on ArgumentError catch (error) {
      throw Mp3QuranApiException('Invalid catalog: ${error.message}', uri: uri);
    }
  }

  /// Closes only a client created by this provider. Safe to call more than once.
  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }
}

QuranRiwayah? _supportedRiwayah(int? id) => switch (id) {
  1 => QuranRiwayah.hafs,
  2 || 10 || 18 => QuranRiwayah.warsh,
  _ => null,
};

Mp3QuranWarshRoute? _warshRoute(int? id) => switch (id) {
  2 => Mp3QuranWarshRoute.unspecified,
  18 => Mp3QuranWarshRoute.azraq,
  10 => Mp3QuranWarshRoute.asbahani,
  _ => null,
};

Uri _directory(Uri uri) {
  if ((uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.userInfo.isNotEmpty) {
    throw ArgumentError.value(uri, 'uri', 'Expected an HTTP(S) directory URL.');
  }
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

List<int> _availableSurahs(Iterable<int> surahs) {
  final result = surahs.toSet().toList()..sort();
  for (final number in result) {
    _checkSurah(number);
  }
  return List<int>.unmodifiable(result);
}

void _checkSurah(int surah) {
  if (surah < 1 || surah > 114) {
    throw RangeError.range(surah, 1, 114, 'surahNumber');
  }
}

int _integer(Object? value, String field) {
  final number = value is int ? value : int.tryParse('$value');
  if (number == null) throw FormatException('Expected integer at $field.');
  return number;
}

int? _optionalInteger(Object? value, String field) =>
    value == null ? null : _integer(value, field);

int _surahNumber(Object? value, String field) {
  final number = _integer(value, field);
  if (number < 1 || number > 114) {
    throw FormatException('Invalid surah number at $field.');
  }
  return number;
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('Expected string at $field.');
  return value;
}

String? _optionalString(Object? value, String field) =>
    value == null ? null : _string(value, field);

List<Map<String, dynamic>> _objects(Object? value, String field) {
  if (value is! List) throw FormatException('Expected array at $field.');
  return value
      .map((row) {
        if (row is! Map<String, dynamic>) {
          throw FormatException('Expected object in $field.');
        }
        return row;
      })
      .toList(growable: false);
}
