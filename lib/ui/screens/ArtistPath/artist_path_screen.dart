import 'package:flutter/material.dart';
import 'package:harmonymusic/utils/artist_path_finder.dart';

class ArtistPathScreen extends StatefulWidget {
  const ArtistPathScreen({super.key});

  @override
  State<ArtistPathScreen> createState() => _ArtistPathScreenState();
}

class _ArtistPathScreenState extends State<ArtistPathScreen> {
  final _keyCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  List<String>? _path;
  bool _loading = false;
  String? _error;

  Future<void> _find() async {
    final key = _keyCtrl.text.trim();
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();
    if (key.isEmpty || from.isEmpty || to.isEmpty) {
      setState(() => _error = 'Fill in the API key and both artists.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _path = null;
    });
    try {
      final path = await ArtistPathFinder(key).findPath(from, to);
      setState(() {
        _path = path;
        if (path == null) _error = 'No path found within 6 steps.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 85, 20, 200),
      children: [
        Text('ArtistPath', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _keyCtrl,
          decoration: const InputDecoration(labelText: 'Last.fm API key'),
        ),
        TextField(
          controller: _fromCtrl,
          decoration: const InputDecoration(labelText: 'From artist'),
        ),
        TextField(
          controller: _toCtrl,
          decoration: const InputDecoration(labelText: 'To artist'),
          onSubmitted: (_) => _find(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _find,
          child: Text(_loading ? 'Searching...' : 'Find path'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_error!),
          ),
        if (_path != null)
          for (var i = 0; i < _path!.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(_path![i]),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Playback for ${_path![i]} comes next')),
                ),
              ),
            ),
      ],
    );
  }
}
