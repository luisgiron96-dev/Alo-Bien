import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

/// Se muestra cuando la persona abre el enlace del correo de recuperación.
class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ResetPasswordScreen({super.key, required this.onDone});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.setNewPassword(_new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Contraseña actualizada. Ya puedes usar la app.')));
      widget.onDone();
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      setState(() => _error = (m.contains('same') || m.contains('different'))
          ? 'La nueva contraseña debe ser diferente a la anterior.'
          : e.message);
    } catch (_) {
      setState(() => _error = 'No pudimos conectar. Revisa tu internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    await AuthService.signOut();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva contraseña'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Crea una nueva contraseña para tu cuenta.'),
          const SizedBox(height: 20),
          TextField(
            controller: _new,
            obscureText: !_show,
            decoration: const InputDecoration(
                labelText: 'Nueva contraseña', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: !_show,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
                labelText: 'Repite la contraseña',
                border: OutlineInputBorder()),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _show,
            onChanged: (v) => setState(() => _show = v ?? false),
            title: const Text('Mostrar contraseñas'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: const TextStyle(color: Color(0xFFFF8A80))),
            ),
          FilledButton(
            onPressed: _busy ? null : _save,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AloColors.violet),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar contraseña'),
          ),
          TextButton(
            onPressed: _busy ? null : _cancel,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
