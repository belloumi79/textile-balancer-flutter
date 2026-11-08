/// Écran d'accueil : import de projet (JSON / CSV / Excel) + lancement de l'équilibrage.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fileName;
  String? _jsonError;

  Future<void> _pickFile(AppState state) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      dialogTitle: 'Importer un projet SAM (JSON/CSV/Excel)',
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes != null) {
      _parse(utf8.decode(file.bytes!), state, file.name);
    } else if (file.path != null) {
      _parse(File(file.path!).readAsStringSync(), state, file.name);
    }
  }

  void _parse(String text, AppState state, String name) {
    try {
      final data = ProjectData.fromJson(jsonDecode(text));
      state.projectData = data;
      _fileName = name;
      _jsonError = null;
      if (mounted) setState(() {});
    } catch (e) {
      _jsonError = 'JSON invalide: $e';
      _fileName = name;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('🧵 Équilibrage de Ligne Textile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Text(
                'Équilibrage de lignes de production (ALBP)',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Solveurs RPW (heuristique) et CP-SAT (optimal, OR-Tools)',
                style: TextStyle(color: Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file, size: 48, color: Color(0xFF1E3A5F)),
                      const SizedBox(height: 12),
                      const Text('Importer un projet SAM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Formats : JSON, CSV, Excel (.xlsx)', style: TextStyle(color: Color(0xFF667085))),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: state.balanceLoading ? null : () => _pickFile(state),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Choisir un fichier'),
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 12),
                        Text('Fichier : $_fileName', style: const TextStyle(color: Color(0xFF039855))),
                      ],
                      if (_jsonError != null) ...[
                        const SizedBox(height: 8),
                        Text(_jsonError!, style: const TextStyle(color: Color(0xFFF04438))),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (state.projectData != null)
                FilledButton(
                  onPressed: state.balanceLoading ? null : () => Navigator.pushNamed(context, '/balance'),
                  child: const Text('Continuer vers l\'équilibrage →'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}