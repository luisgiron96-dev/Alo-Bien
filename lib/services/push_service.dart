import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Los mensajes con bloque "notification" los muestra el sistema solo.
}

/// Payload esperado desde el sitio (FCM):
/// notification: {title, body}
/// data: {url: "https://alobienplataforma.com/...", type: "video|contenido|novedad|comunidad", content_id: "123"}
class PushService {
  PushService._();
  static final instance = PushService._();

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  /// Enlace pendiente de abrir (tap en notificación).
  final ValueNotifier<Uri?> pendingLink = ValueNotifier(null);

  /// Mensaje recibido con la app abierta.
  final ValueNotifier<RemoteMessage?> foregroundMessage = ValueNotifier(null);

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((m) => foregroundMessage.value = m);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
    final initial = await _fm.getInitialMessage(); // app abierta desde cerrada
    if (initial != null) _onTap(initial);
  }

  void _onTap(RemoteMessage m) {
    final link = AppConfig.safeLink(m.data['url'] as String?);
    if (link != null) pendingLink.value = link;
  }

  /// Pide permiso (Android 13+/iOS) y suscribe a los temas.
  Future<bool> requestPermissionAndSubscribe() async {
    final s = await _fm.requestPermission();
    final ok = s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
    if (ok) {
      for (final t in AppConfig.pushTopics) {
        await _fm.subscribeToTopic(t);
      }
      debugPrint('FCM token: ${await _fm.getToken()}');
    }
    return ok;
  }
}