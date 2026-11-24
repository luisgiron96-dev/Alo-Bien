import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

/// Configuración de la cuenta (usuarios y creador).
class SettingsScreen extends StatelessWidget {
  final String email;
  const SettingsScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Cuenta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline_rounded,
                color: AloColors.lavender),
            title: const Text('Correo'),
            subtitle: Text(email),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.lock_outline_rounded, color: AloColors.lavender),
            title: const Text('Cambiar contraseña'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(email: email),
            )),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_current.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña actual.');
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Las contraseñas nuevas no coinciden.');
      return;
    }
    if (_new.text == _current.text) {
      setState(() => _error = 'La nueva contraseña debe ser diferente a la actual.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.changePassword(
        email: widget.email,
        currentPassword: _current.text,
        newPassword: _new.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Contraseña actualizada.')));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      setState(() {
        if (m.contains('invalid login')) {
          _error = 'La contraseña actual no es correcta.';
        } else if (m.contains('same') || m.contains('different')) {
          _error = 'La nueva contraseña debe ser diferente a la actual.';
        } else if (m.contains('rate limit')) {
          _error = 'Demasiados intentos. Espera unos minutos.';
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      setState(() => _error = 'No pudimos conectar. Revisa tu internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _current,
            obscureText: !_show,
            decoration: _dec('Contraseña actual'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _new,
            obscureText: !_show,
            decoration: _dec('Nueva contraseña'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: !_show,
            decoration: _dec('Repite la nueva contraseña'),
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
        ],
      ),
    );
  }
}
