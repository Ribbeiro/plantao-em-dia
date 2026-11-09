import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificação local de medicações atrasadas (Android e iOS).
/// No navegador o recurso fica desativado e o alerta aparece só na tela.
class NotificacoesService {
  NotificacoesService._();
  static final instancia = NotificacoesService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  /// Evita repetir o aviso das mesmas doses a cada atualização da tela.
  final Set<String> _jaAvisadas = {};

  bool get suportado =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> iniciar() async {
    if (!suportado || _pronto) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _pronto = true;
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  /// Mostra um aviso se houver doses atrasadas que ainda não foram notificadas.
  Future<void> avisarAtrasadas({required String setorNome, required List<String> idsAtrasadas}) async {
    if (!_pronto) return;
    final novas = idsAtrasadas.where((id) => !_jaAvisadas.contains(id)).toList();
    if (novas.isEmpty) return;
    _jaAvisadas.addAll(novas);
    await _plugin.show(
      id: 1001,
      title: 'Medicações atrasadas – $setorNome',
      body: '${idsAtrasadas.length} dose(s) aguardando administração. Toque para conferir.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicacoes_atrasadas',
          'Medicações atrasadas',
          channelDescription: 'Aviso quando há doses pendentes após o horário',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void limpar() => _jaAvisadas.clear();
}
