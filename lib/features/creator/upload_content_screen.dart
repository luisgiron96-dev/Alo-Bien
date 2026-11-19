import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../models/content_item.dart';

class UploadContentScreen extends StatefulWidget {
  const UploadContentScreen({super.key});
  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  static const maxBytes = 50 * 1024 * 1024; // 50 MB (plan gratuito de Supabase)

  static const _allowed = <ContentType, List<String>>{
    ContentType.video: ['mp4', 'mov', 'm4v'],
    ContentType.audio: ['mp3', 'wav'],
    ContentType.image: ['jpg', 'jpeg', 'png', 'webp'],
    ContentType.pdf: ['pdf'],
  };

  static const _mime = <String, String>{
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4v': 'video/x-m4v',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
  };

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _category = TextEditingController();
  final _artist = TextEditingController();

  ContentType _type = ContentType.video;
  PlatformFile? _file;
  PlatformFile? _cover;
  int _fileBytes = 0;
  int _coverBytes = 0;
  bool _publishNow = true;
  bool _featured = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _category.dispose();
    _artist.dispose();
    super.dispose();
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  String _ext(String name) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';

  String _safe(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  Future<void> _pickFile() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowed[_type],
    );
    if (f == null) return;
    final size = await f.length() ?? 0;
    if (size > maxBytes) {
      setState(() => _error =
          'El archivo pesa ${_mb(size)} MB. El máximo actual es 50 MB.');
      return;
    }
    setState(() {
      _file = f;
      _fileBytes = size;
      _error = null;
    });
  }

  Future<void> _pickCover() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowed[ContentType.image],
    );
    if (f == null) return;
    final size = await f.length() ?? 0;
    if (size > maxBytes) {
      setState(() => _error = 'La portada pesa demasiado (máximo 50 MB).');
      return;
    }
    setState(() {
      _cover = f;
      _coverBytes = size;
      _error = null;
    });
  }

  Future<void> _cleanup(String? media, String? cover) async {
    try {
      if (media != null) await db.storage.from('media').remove([media]);
      if (cover != null) await db.storage.from('covers').remove([cover]);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un título.');
      return;
    }
    if (_file == null || _file!.path == null) {
      setState(() => _error = 'Elige el archivo principal.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    String? uploadedMedia;
    String? uploadedCover;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final main = _file!;
      final mediaPath = '${_type.name}/${ts}_${_safe(main.name)}';
      await db.storage.from('media').upload(
            mediaPath,
            File(main.path!),
            fileOptions: FileOptions(
                contentType: _mime[_ext(main.name)], upsert: false),
          );
      uploadedMedia = mediaPath;

      // Portada: la elegida, o la misma imagen si el contenido es una imagen.
      final coverSource = _cover ?? (_type == ContentType.image ? main : null);
      String? coverPath;
      if (coverSource != null && coverSource.path != null) {
        coverPath = '${ts}_${_safe(coverSource.name)}';
        await db.storage.from('covers').upload(
              coverPath,
              File(coverSource.path!),
              fileOptions: FileOptions(
                  contentType: _mime[_ext(coverSource.name)], upsert: false),
            );
        uploadedCover = coverPath;
      }

      // Solo un creador puede insertar (lo impone la base de datos).
      await db.from('content').insert({
        'type': _type.name,
        'title': _title.text.trim(),
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'category':
            _category.text.trim().isEmpty ? null : _category.text.trim(),
        'artist': _artist.text.trim().isEmpty ? null : _artist.text.trim(),
        'file_path': mediaPath,
        'cover_path': coverPath,
        'featured': _featured,
        'status': _publishNow ? 'published' : 'draft',
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StorageException catch (e) {
      await _cleanup(uploadedMedia, uploadedCover);
      if (mounted) {
        setState(() => _error = 'No se pudo subir el archivo: ${e.message}');
      }
    } on PostgrestException catch (e) {
      await _cleanup(uploadedMedia, uploadedCover);
      if (mounted) {
        setState(
            () => _error = 'No se pudo guardar la publicación: ${e.message}');
      }
    } catch (_) {
      await _cleanup(uploadedMedia, uploadedCover);
      if (mounted) {
        setState(() => _error = 'Ocurrió un error. Revisa tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exts = _allowed[_type]!.join(', ');
    return Scaffold(
      appBar: AppBar(title: const Text('Subir contenido')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Tipo de contenido',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final t in ContentType.values)
                ChoiceChip(
                  avatar: Icon(t.icon, size: 18),
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() {
                    _type = t;
                    _file = null;
                    _fileBytes = 0;
                    _error = null;
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_file == null
                  ? 'Elegir archivo ($exts)'
                  : '${_file!.name} • ${_mb(_fileBytes)} MB'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(_cover == null
                  ? (_type == ContentType.image
                      ? 'Portada (opcional: se usa la misma imagen)'
                      : 'Elegir portada (opcional)')
                  : '${_cover!.name} • ${_mb(_coverBytes)} MB'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Título *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Descripción', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Categoría (ej. Entrevistas)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artist,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Artista o autor', border: OutlineInputBorder()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publicar ahora'),
              subtitle: Text(_publishNow
                  ? 'Los usuarios lo verán de inmediato.'
                  : 'Se guarda como borrador, solo tú lo ves.'),
              value: _publishNow,
              onChanged: (v) => setState(() => _publishNow = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Destacar en el Inicio'),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Subiendo... no cierres esta pantalla.',
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(_publishNow ? 'Publicar' : 'Guardar borrador'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AloColors.violet),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}