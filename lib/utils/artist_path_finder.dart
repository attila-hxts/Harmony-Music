import 'dart:convert';
import 'dart:io';

class ArtistPathFinder {
  final String apiKey;
  final HttpClient _client = HttpClient();
  final Map<String, List<String>> _cache = {};

  ArtistPathFinder(this.apiKey);

  Future<List<String>> _similar(String artist) async {
    final key = artist.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
      'method': 'artist.getsimilar',
      'artist': artist,
      'api_key': apiKey,
      'format': 'json',
      'limit': '30',
      'autocorrect': '1',
    });
    final request = await _client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (data is Map && data['error'] != null) {
      throw Exception(data['message'] ?? 'Last.fm error');
    }
    final names = <String>[];
    final artists = data['similarartists']?['artist'];
    if (artists is List) {
      for (final a in artists) {
        names.add(a['name'] as String);
      }
    }
    _cache[key] = names;
    return names;
  }

  /// Breadth-first search: shortest chain of similar artists from [from] to [to].
  Future<List<String>?> findPath(String from, String to,
      {int maxDepth = 6}) async {
    final target = to.toLowerCase();
    if (from.toLowerCase() == target) return [from];
    final parent = <String, String?>{from: null};
    var frontier = <String>[from];
    for (var depth = 0; depth < maxDepth; depth++) {
      final next = <String>[];
      for (final artist in frontier) {
        for (final n in await _similar(artist)) {
          if (parent.containsKey(n)) continue;
          parent[n] = artist;
          if (n.toLowerCase() == target) {
            final path = <String>[];
            for (String? c = n; c != null; c = parent[c]) {
              path.add(c);
            }
            return path.reversed.toList();
          }
          next.add(n);
        }
      }
      frontier = next;
    }
    return null;
  }
}
