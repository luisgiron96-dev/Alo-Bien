import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false;
  bool _loading = false;
  bool _hide = true;
  String? _msg;
  bool _isError = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _friendly(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Correo o contraseña incorrectos.';
    if (m.contains('not confirmed')) return 'Tu correo aún no está confirmado.';
    if (m.contains('already registered')) return 'Ese correo ya tiene una cuenta.';
    if (m.contains('rate limit')) {
      return 'Se enviaron muchos correos en poco tiempo. Intenta de nuevo en unos minutos.';
    }
    return e.message;
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _isError = true;
        _msg = 'Escribe tu correo en el campo de arriba y vuelve a tocar "¿Olvidaste tu contraseña?".';
      });
      return;
    }
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _isError = false;
          _msg = 'Si el correo está registrado, te enviamos un enlace. Ábrelo desde este celular para crear una nueva contraseña.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _msg = _friendly(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _msg = 'No pudimos conectar. Revisa tu internet.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.length < 6) {
      setState(() {
        _isError = true;
        _msg = 'Escribe tu correo y una contraseña de al menos 6 caracteres.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      if (_register) {
        final res = await AuthService.signUp(email, pass, _name.text.trim());
        if (res.session == null && mounted) {
          setState(() {
            _register = false;
            _isError = false;
            _msg = 'Cuenta creada. Abre el correo desde este celular, toca "Confirmar" y la app se abrirá sola.';
          });
        }
      } else {
        await AuthService.signIn(email, pass);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _msg = _friendly(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _msg = 'No pudimos conectar. Revisa tu internet.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData.light(useMaterial3: true);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AloColors.bgDeep, AloColors.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 64,
                    errorBuilder: (_, __, ___) => const Text('ALO BIEN',
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 28),
                  Theme(
                    data: light.copyWith(
                      colorScheme:
                          const ColorScheme.light(primary: AloColors.violet),
                      textTheme: GoogleFonts.montserratTextTheme(light.textTheme),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [AloColors.bg, AloColors.lavender]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _register ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_register) ...[
                            TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _pass,
                            obscureText: _hide,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_hide
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(() => _hide = !_hide),
                              ),
                            ),
                          ),
                          if (_msg != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _msg!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: _isError
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _GradientButton(
                            label: _register ? 'CREAR CUENTA' : 'ENTRAR',
                            loading: _loading,
                            onTap: _loading ? null : _submit,
                          ),
                          if (!_register)
                            TextButton(
                              onPressed: _loading ? null : _forgot,
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                      _register = !_register;
                                      _msg = null;
                                    }),
                            child: Text(_register
                                ? 'Ya tengo cuenta'
                                : 'Crear una cuenta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AloColors.bg, AloColors.violet]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: SizedBox(
              height: 50,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
              ),
            ),
          ),
        ),
      );
}