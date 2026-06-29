// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'BlinkKind';

  @override
  String get start => 'Comenzar';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get stopTimer => 'Detener temporizador';

  @override
  String get skip => 'Omitir';

  @override
  String get postpone => 'Posponer';

  @override
  String get snooze => 'Posponer aviso';

  @override
  String get breaksTakenToday => 'Descansos tomados hoy';

  @override
  String get readyForNextFocusSession =>
      'Listo para la próxima sesión de enfoque';

  @override
  String get snoozed => 'Pospuesto';

  @override
  String get schedulePaused => 'Horario pausado';

  @override
  String get idle => 'Inactivo';

  @override
  String get paused => 'Pausado';

  @override
  String get idlePaused => 'Pausado por inactividad';

  @override
  String get breakLabel => 'Descanso';

  @override
  String get workLabel => 'Trabajo';

  @override
  String breaksSnoozed(int minutes) {
    return 'Descansos pospuestos ($minutes min restantes)';
  }

  @override
  String get timerPausedBySchedule => 'Temporizador pausado por horario';

  @override
  String get breakPaused => 'Descanso pausado';

  @override
  String get workPaused => 'Trabajo pausado';

  @override
  String get workPausedIdle => 'Trabajo pausado (inactivo)';

  @override
  String get breakTimeMessage =>
      'Hora del descanso - mira a 20 pies de distancia';

  @override
  String get workTimeMessage => 'Hora de trabajar - enfócate en tu tarea';

  @override
  String get onboardingSubtitle =>
      'Sigue el hábito 20-20-20 con recordatorios sutiles mientras trabajas.';

  @override
  String get onboardingFocusFirstTitle => 'Enfócate primero';

  @override
  String get onboardingFocusFirstBody =>
      'Inicia una sesión de enfoque y mantén el temporizador funcionando en la aplicación.';

  @override
  String get onboardingRestEyesTitle => 'Descansa la vista';

  @override
  String get onboardingRestEyesBody =>
      'Cuando termine el tiempo de trabajo, mira hacia otro lado y relaja la vista durante el descanso.';

  @override
  String get onboardingAllowRemindersTitle => 'Permitir recordatorios';

  @override
  String get onboardingNotificationsBlocked =>
      'Las notificaciones están bloqueadas en los ajustes del sistema. Puedes activarlas desde Ajustes más tarde.';

  @override
  String get onboardingNotificationsHelp =>
      'Las notificaciones ayudan a que el temporizador te recuerde incluso cuando la aplicación no está en pantalla.';

  @override
  String get onboardingAllowAndStart => 'Permitir recordatorios e iniciar';

  @override
  String get onboardingContinueWithoutReminders =>
      'Continuar sin recordatorios';

  @override
  String get historyTitle => 'Historial y estadísticas';

  @override
  String get sevenDays => '7 días';

  @override
  String get thirtyDays => '30 días';

  @override
  String get allTime => 'Todo';

  @override
  String get dailyActivityPattern => 'Patrón de actividad diaria';

  @override
  String get noActivityRange => 'No se registró actividad en este rango';

  @override
  String get focusDuration => 'Duración de enfoque';

  @override
  String get goalRate => 'Tasa de objetivos';

  @override
  String get longestStreakLabel => 'Racha más larga';

  @override
  String get peakFocusHourLabel => 'Hora pico de enfoque';

  @override
  String get breakComplianceLabel => 'Puntuación de salud ocular';

  @override
  String get complianceRate => 'Puntuación de salud ocular';

  @override
  String get milestonesEarnedLabel => 'Logros alcanzados';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String get productivityInsights => 'Estadísticas de productividad';

  @override
  String get completedFocusSessions => 'Sesiones de enfoque completadas';

  @override
  String get cancelledSessions => 'Sesiones canceladas';

  @override
  String get skippedBreaks => 'Descansos omitidos';

  @override
  String get postponedBreaks => 'Descansos pospuestos';

  @override
  String get consciousBlinksLogged => 'Parpadeos conscientes registrados';

  @override
  String get recentCompletedSessions => 'Sesiones completadas recientemente';

  @override
  String get newSessionsAppearHere =>
      'Las nuevas sesiones completadas aparecerán aquí';

  @override
  String get exportActivityData => 'Exportar datos de actividad';

  @override
  String get exportActivityDescription =>
      'Exporta tus sesiones de enfoque y eventos de descanso. Puedes guardarlos directamente en tu carpeta de Descargas o copiarlos al portapapeles.';

  @override
  String get saveCsv => 'Guardar CSV';

  @override
  String get saveJson => 'Guardar JSON';

  @override
  String get copyCsv => 'Copiar CSV';

  @override
  String get copyJson => 'Copiar JSON';

  @override
  String get clearActivityHistory => 'Borrar historial de actividad';

  @override
  String get clearHistoryConfirmTitle => '¿Borrar historial de actividad?';

  @override
  String get clearHistoryConfirmBody =>
      'Esto eliminará los totales diarios y los detalles de las sesiones completadas. Esta acción no se puede deshacer.';

  @override
  String get clear => 'Borrar';

  @override
  String copiedToClipboard(String formatName) {
    return '¡$formatName copiado al portapapeles!';
  }

  @override
  String exportedToFile(String fileName) {
    return 'Exportado al archivo: $fileName';
  }

  @override
  String get openFolder => 'Abrir carpeta';

  @override
  String failedToExport(String error) {
    return 'Error al exportar al archivo: $error';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSearchPlaceholder => 'Buscar ajustes...';

  @override
  String settingsNoResults(String query) {
    return 'No hay ajustes que coincidan con \"$query\"';
  }

  @override
  String get settingsCategoryGeneralSchedule => 'Horario general';

  @override
  String get settingsCategoryBreakBehavior =>
      'Pantalla y comportamiento de descanso';

  @override
  String get settingsCategoryThemeAppearance => 'Tema y apariencia';

  @override
  String get settingsCategoryNotificationsSounds => 'Notificaciones y sonidos';

  @override
  String get settingsCategoryAutoRunLongBreaks =>
      'Ejecución automática y descansos largos';

  @override
  String get settingsCategoryDesktopOptions => 'Opciones de escritorio';

  @override
  String get settingsCategoryAiMotivation => 'Motivación por IA y avisos';

  @override
  String get settingsCategorySystemOptions => 'Opciones del sistema';

  @override
  String get settingsQuickPresets => 'Ajustes rápidos';

  @override
  String get settingsQuickPresetsSubtitle =>
      '20-20-20, 25/5, 45/5, 10s/10s (Prueba)';

  @override
  String get settingsWorkDuration => 'Duración del trabajo';

  @override
  String get settingsWorkDurationChoose => 'Elegir intervalo de trabajo';

  @override
  String get settingsPauseCancelToChange =>
      'Pausa/cancela el temporizador para cambiar';

  @override
  String get settingsPauseCancelToChangeDesc =>
      'Pausa o cancela el temporizador para modificar esto';

  @override
  String get settingsBreakDuration => 'Duración del descanso';

  @override
  String get settingsBreakDurationChoose => 'Elegir longitud del descanso';

  @override
  String get settingsDailyGoal => 'Objetivo diario';

  @override
  String settingsDailyGoalProgress(int streak, int goal) {
    return '$streak / $goal descansos hoy';
  }

  @override
  String get settingsCustom => 'Personalizar...';

  @override
  String get settingsHistory => 'Historial';

  @override
  String get settingsHistorySubtitle =>
      'Revisa tus descansos oculares recientes';

  @override
  String settingsTodayProgress(int count) {
    return 'Hoy: $count ciclos';
  }

  @override
  String get settingsTodayProgressTitle => 'Progreso de hoy';

  @override
  String get settingsResetStreak => 'Restablecer racha de hoy';

  @override
  String get settingsReset => 'Restablecer';

  @override
  String get settingsActiveWorkHours => 'Horas y días de trabajo activos';

  @override
  String get settingsActiveWorkHoursSubtitle =>
      'Solo ejecutar los ciclos del temporizador durante horas y días específicos';

  @override
  String get settingsActiveDays => 'Días activos';

  @override
  String get settingsStartTime => 'Hora de inicio';

  @override
  String get settingsEndTime => 'Hora de finalización';

  @override
  String get settingsAutoStartSchedule => 'Inicio automático del horario';

  @override
  String get settingsAutoStartScheduleSubtitle =>
      'Iniciar el temporizador automáticamente al arrancar';

  @override
  String get settingsOsFocusMode => 'Modo de enfoque del SO (No molestar)';

  @override
  String get settingsOsFocusModeSubtitle =>
      'Activar el modo No molestar (DND) automáticamente durante las fases de trabajo (Linux GNOME)';

  @override
  String get settingsOsFocusModeToggle =>
      'Activar No molestar durante las fases de trabajo';

  @override
  String get settingsOsFocusModeGnomeNote =>
      'Nota: Ubuntu/GNOME no admite de forma nativa excepciones o listas blancas de No molestar. Si deseas que aplicaciones específicas omitan No molestar, desactiva esta opción y silencia manualmente las aplicaciones ruidosas en Ajustes de Ubuntu -> Notificaciones.';

  @override
  String get settingsBreakScreenMode => 'Modo de pantalla de descanso';

  @override
  String get settingsBreakScreenModeSubtitle =>
      'Modo de descanso: Desactivado, Sutil o Estricto';

  @override
  String get settingsStrictBlocksExit =>
      'El modo estricto bloquea la salida fácil';

  @override
  String get settingsPreBreakAlert => 'Alerta de notificación pre-descanso';

  @override
  String get settingsPreBreakAlertSubtitle =>
      'Recibe una advertencia 10 segundos antes de comenzar el descanso';

  @override
  String get settingsAllowSkip => 'Permitir omitir';

  @override
  String get settingsAllowSkipSubtitle =>
      'Permitir omitir el descanso antes de tiempo';

  @override
  String get settingsAllowPostpone => 'Permitir posponer';

  @override
  String get settingsAllowPostponeSubtitle => 'Permitir posponer el descanso';

  @override
  String get settingsSmartPausePostpone => 'Pausa y posposición inteligente';

  @override
  String get settingsSmartPausePostponeSubtitle =>
      'Pausar el temporizador de trabajo automáticamente al estar inactivo';

  @override
  String get settingsNaturalBreakCredit => 'Crédito de descanso natural';

  @override
  String get settingsNaturalBreakCreditSubtitle =>
      'Acreditar el tiempo fuera como descanso si estás ausente más de 5 minutos';

  @override
  String get settingsBreakVisualizerStyle =>
      'Estilo de visualizador de descanso';

  @override
  String get settingsBreakVisualizerStyleSubtitle =>
      'Elige el efecto ambiental durante los descansos';

  @override
  String get settingsBreakScreenContent =>
      'Contenido de la pantalla de descanso';

  @override
  String get settingsBreakScreenContentSubtitle =>
      'Elige los widgets que se muestran en el descanso';

  @override
  String get settingsShowCountdown => 'Mostrar reloj de cuenta regresiva';

  @override
  String get settingsShowTips => 'Mostrar consejos de cuidado ocular';

  @override
  String get settingsShowProgress => 'Mostrar anillo de progreso';

  @override
  String get settingsCustomReminderText =>
      'Texto de recordatorio personalizado';

  @override
  String get settingsBuiltInRotatingMessages =>
      'Usando mensajes rotativos integrados';

  @override
  String get settingsPostponeDuration => 'Duración de posposición';

  @override
  String get settingsPostponeDurationSubtitle =>
      'Cuánto tiempo retrasar el descanso';

  @override
  String get settingsDisplayOverApps => 'Mostrar sobre otras aplicaciones';

  @override
  String get settingsAllow => 'Permitir';

  @override
  String get settingsPreviewBreakScreen =>
      'Vista previa de la pantalla de descanso';

  @override
  String get settingsPreviewBreakScreenSubtitle =>
      'Mostrar una pantalla negra de 10 segundos';

  @override
  String get settingsTest20sBreak => 'Probar pantalla de descanso de 20s';

  @override
  String get settingsTest20sBreakSubtitle =>
      'Iniciar un descanso real de 20 segundos';

  @override
  String get settingsUsageAccess => 'Acceso de uso';

  @override
  String get settingsUsageAccessEnabled => 'Detección de aplicaciones activada';

  @override
  String get settingsUsageAccessRequired =>
      'Requerido para detectar juegos y videos';

  @override
  String get settingsDarkMode => 'Modo oscuro';

  @override
  String get settingsDarkModeSubtitle =>
      'Alternar interfaz de tema oscuro o claro';

  @override
  String get settingsAmoledDarkMode => 'Modo oscuro AMOLED';

  @override
  String get settingsAmoledDarkModeSubtitle =>
      'Usar fondos negros puros para ahorrar batería';

  @override
  String get settingsUseSystemAccent => 'Usar color de acento del sistema';

  @override
  String get settingsUseSystemAccentSubtitle =>
      'Seguir los colores dinámicos de acento del SO';

  @override
  String get settingsColorPreset => 'Ajuste de color';

  @override
  String get settingsColorPresetSubtitle =>
      'Elige tu tema de color de acento preferido';

  @override
  String get settingsCustomAccentPalette => 'Paleta de acento personalizada';

  @override
  String get settingsAccentColorHex => 'Código hexadecimal del color de acento';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsSubtitle =>
      'Recordarme cuando termine el tiempo de trabajo o descanso';

  @override
  String get settingsNotificationSound => 'Sonido de notificación';

  @override
  String get settingsNotificationSoundSubtitle =>
      'Usa la configuración de sonido de notificación del sistema';

  @override
  String get settingsTestReminderAlert => 'Probar alerta de recordatorio';

  @override
  String get settingsPlayReminderSound =>
      'Reproducir el sonido del recordatorio ahora';

  @override
  String get settingsTestReminder => 'Probar recordatorio';

  @override
  String get settingsPermissionStatus => 'Estado de permisos';

  @override
  String get settingsOpenSystemSettings => 'Abrir ajustes del sistema';

  @override
  String get settingsTimerAlertsOff =>
      'Las alertas del temporizador están desactivadas. La cuenta regresiva sigue funcionando en la aplicación.';

  @override
  String get settingsPreciseReminders => 'Recordatorios precisos';

  @override
  String get settingsPreciseAllowed => 'Tiempo exacto permitido';

  @override
  String get settingsPreciseLate => 'Puede llegar un poco tarde';

  @override
  String get settingsBackgroundReliability => 'Fiabilidad en segundo plano';

  @override
  String get settingsBatteryUnrestricted =>
      'El uso de batería no tiene restricciones';

  @override
  String get settingsBatteryOptimized =>
      'La optimización de batería puede retrasar las alertas';

  @override
  String get settingsReview => 'Revisar';

  @override
  String get settingsHaptics => 'Vibración';

  @override
  String get settingsVibratePhaseEnd =>
      'Vibrar cuando finaliza una fase del temporizador';

  @override
  String get settingsInAppSound => 'Sonido en la aplicación';

  @override
  String get settingsPlayExtraAlert =>
      'Reproducir una alerta del sistema adicional mientras BlinkKind está abierto';

  @override
  String get settingsChimeStyle => 'Estilo de timbre';

  @override
  String get settingsChimeStyleSubtitle =>
      'Sonido que suena cuando comienza o termina un descanso';

  @override
  String get settingsConsciousBlinkingReminders =>
      'Recordatorios de parpadeo consciente';

  @override
  String get settingsConsciousBlinkingSubtitle =>
      'Muestra banners de recordatorio visibles durante el trabajo para mantener los ojos húmedos y reducir la fatiga';

  @override
  String get settingsBannerInterval => 'Intervalo de banners';

  @override
  String get settingsShowBlinkBanner =>
      'Con qué frecuencia mostrar el banner de parpadeo del SO';

  @override
  String get settingsInteractiveBlinkReminders =>
      'Acciones de parpadeo interactivas';

  @override
  String get settingsInteractiveBlinkRemindersSubtitle =>
      'Añadir un botón para marcar los recordatorios de parpadeo directamente desde las notificaciones';

  @override
  String get settingsTrayBlinkNudges => 'Avisos de parpadeo en la bandeja';

  @override
  String get settingsTrayBlinkNudgesSubtitle =>
      'Parpadea el icono de la bandeja del sistema independientemente de las notificaciones del SO';

  @override
  String get settingsTrayNudgeInterval => 'Intervalo de avisos en la bandeja';

  @override
  String get settingsTrayIconPulse =>
      'Con qué frecuencia debe parpadear el icono de la bandeja';

  @override
  String get settingsRunScheduleAutomatically =>
      'Ejecutar horario automáticamente';

  @override
  String get settingsRunScheduleAutomaticallySubtitle =>
      'Continuar los ciclos de trabajo y descanso hasta que se detenga o se alcance el límite';

  @override
  String get settingsCycleLimit => 'Límite de ciclos';

  @override
  String get settingsCycleLimitSubtitle =>
      'Ciclos de trabajo completados en una ejecución';

  @override
  String get settingsLongBreakMode => 'Modo de descanso largo';

  @override
  String settingsLongBreakModeSubtitle(int count, String duration) {
    return 'Después de $count ciclos de trabajo, descansar durante $duration';
  }

  @override
  String get settingsCycleInterval => 'Intervalo de ciclos';

  @override
  String get settingsLongBreakDuration => 'Duración del descanso largo';

  @override
  String get settingsLaunchAtStartup => 'Iniciar al arrancar';

  @override
  String get settingsStartBlinkKindAutomatically =>
      'Iniciar BlinkKind automáticamente al iniciar sesión';

  @override
  String get settingsStartMinimized => 'Iniciar minimizado';

  @override
  String get settingsOpenIntoTray =>
      'Abrir en la bandeja al iniciar la aplicación';

  @override
  String get settingsEnableAiMotivation => 'Activar motivación por IA';

  @override
  String get settingsAiProvider => 'Proveedor de IA';

  @override
  String get settingsAiApiKey => 'Clave API';

  @override
  String get settingsAiApiKeyHint => 'Pega tu clave API aquí';

  @override
  String get settingsAiModel => 'Modelo';

  @override
  String get settingsAiSystemPrompt => 'Mensaje del sistema';

  @override
  String get settingsAiSystemPromptHint =>
      'Describe qué tipo de frase deseas...';

  @override
  String get settingsResetSettings => 'Restablecer ajustes';

  @override
  String get settingsRestoreFactoryDefaults =>
      'Restablecer todos los ajustes a los valores predeterminados';

  @override
  String get settingsBackupSettings => 'Copia de seguridad de ajustes';

  @override
  String get settingsExportDownloadsFolder =>
      'Exportar ajustes a tu carpeta de Descargas';

  @override
  String get settingsRestoreSettings => 'Restablecer ajustes';

  @override
  String get settingsLoadBackupJson =>
      'Cargar ajustes desde un archivo JSON de copia de seguridad';

  @override
  String get settingsCustomModelDialogTitle => 'Modelo personalizado';

  @override
  String get settingsModelName => 'Nombre del modelo';

  @override
  String get settingsModelNameHint => 'p. ej. gpt-4o, gemini-2.0-flash';

  @override
  String get settingsSet => 'Establecer';

  @override
  String get settingsRestoreDefaultsTitle =>
      '¿Restablecer valores predeterminados?';

  @override
  String get settingsRestoreDefaultsDesc =>
      'Esto restablecerá todas las preferencias (duraciones, preajustes, ajustes de sonido, temas, configuraciones de IA, opciones de inicio automático) a los valores predeterminados de fábrica.\n\nTu racha, historial y actividad registrada NO se borrarán.';

  @override
  String get settingsRestoredSnackbar =>
      'Ajustes restablecidos a los valores predeterminados de fábrica';

  @override
  String get settingsRestoredSuccessSnackbar =>
      '¡Ajustes restablecidos con éxito!';

  @override
  String settingsRestoredFailedSnackbar(String error) {
    return 'Error al restablecer los ajustes: $error';
  }

  @override
  String get settingsCustomDailyGoalTitle => 'Objetivo diario personalizado';

  @override
  String get settingsNumberOfBreaks => 'Número de descansos';

  @override
  String get settingsNumberOfBreaksHint => 'p. ej. 15, 20';

  @override
  String get settingsCustomBlinkReminderTitle =>
      'Recordatorio de parpadeo personalizado';

  @override
  String get settingsCustomBlinkReminderHint =>
      'p. ej. ¡Hora de parpadear! Descansa la vista.';

  @override
  String get settingsCustomBlinkReminderHelper =>
      'Dejar en blanco para usar mensajes integrados';

  @override
  String get settingsSave => 'Guardar';

  @override
  String get settingsCameraAutoPostponeSnackbar =>
      'Cámara en uso — descanso pospuesto automáticamente';

  @override
  String get settingsAllowOverlaySnackbar =>
      'Permite mostrar sobre otras aplicaciones primero.';

  @override
  String settingsDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String settingsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String settingsDurationEverySeconds(int seconds) {
    return 'Cada $seconds seg';
  }

  @override
  String settingsDurationEveryMinutes(int minutes) {
    return 'Cada $minutes min';
  }

  @override
  String get settingsCycleNoLimit => 'Sin límite';

  @override
  String settingsCycleLimitCount(int count) {
    return '$count ciclos';
  }

  @override
  String get settingsWellnessReminders => 'Recordatorios de bienestar';

  @override
  String get settingsWellnessRemindersSubtitle =>
      'Recordatorios periódicos de hidratación, postura y estiramiento durante el trabajo';

  @override
  String get settingsWellnessRemindersDesc =>
      'Alterna recordatorios de hidratación, postura y estiramiento durante las sesiones de trabajo';

  @override
  String get settingsReminderInterval => 'Intervalo de recordatorios';

  @override
  String get settingsReminderIntervalDesc =>
      'Con qué frecuencia enviar un recordatorio de bienestar';

  @override
  String get settingsCameraMicAutoPostpone =>
      'Pospuesto automático por cámara/micrófono';

  @override
  String get settingsCameraMicAutoPostponeSubtitle =>
      'Posponer descansos automáticamente cuando la cámara esté en uso (videollamadas)';

  @override
  String get settingsCameraMicAutoPostponeDesc =>
      'Posponer automáticamente los descansos cuando tu cámara o micrófono estén en uso (por ejemplo, videollamadas). Solo en Linux y Android.';

  @override
  String get settingsAutoPauseOnMedia =>
      'Pausa automática por reproducción de medios';

  @override
  String get settingsAutoPauseOnMediaSubtitle =>
      'Pausar descansos automáticamente cuando se reproduce video o música';

  @override
  String get settingsAutoPauseOnMediaDesc =>
      'Pausar automáticamente el temporizador cuando hay medios en segundo plano activos (música o video). Solo en Android y Linux.';

  @override
  String get settingsWellnessEvery30Min => 'Cada 30 min';

  @override
  String get settingsWellnessEvery45Min => 'Cada 45 min';

  @override
  String get settingsWellnessEvery1Hour => 'Cada 1 hora';

  @override
  String get settingsWellnessEvery15Hours => 'Cada 1,5 horas';

  @override
  String get settingsWellnessEvery2Hours => 'Cada 2 horas';

  @override
  String get settingsAiBlinkMessages =>
      'Mensajes de parpadeo potenciados por IA';

  @override
  String get settingsAiBlinkMessagesSubtitle =>
      'Generar un recordatorio fresco y único cada vez usando IA';

  @override
  String get settingsCustomReminder => 'Recordatorio de parpadeo personalizado';

  @override
  String get settingsPermissionAllowed => 'Permiso del sistema permitido';

  @override
  String get settingsPermissionBlocked => 'Permiso del sistema bloqueado';

  @override
  String get settingsPermissionUnavailable =>
      'Estado no disponible en esta plataforma';

  @override
  String get settingsPermissionChecking => 'Comprobando permiso del sistema';

  @override
  String get settingsOverlayAllowed => 'Permitido en este dispositivo';

  @override
  String get settingsOverlayRequired =>
      'Permiso requerido para descansos forzados';

  @override
  String get settingsOverlayChecking => 'Comprobando permiso de superposición';

  @override
  String get settingsOverlayUnavailable => 'No disponible en esta plataforma';

  @override
  String get settingsBreakModeOff => 'Desactivado';

  @override
  String get settingsBreakModeGentle => 'Sutil';

  @override
  String get settingsBreakModeStrict => 'Estricto';

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mié';

  @override
  String get thu => 'Jue';

  @override
  String get fri => 'Vie';

  @override
  String get sat => 'Sáb';

  @override
  String get sun => 'Dom';

  @override
  String get settingsVisualizerRandom => 'Aleatorio/Todos';

  @override
  String get settingsVisualizerBreathing => 'Respiración tranquila';

  @override
  String get settingsVisualizerBoxBreathing => 'Respiración cuadrada (4-4-4-4)';

  @override
  String get settingsVisualizerEyeExercise => 'Ejercicios oculares';

  @override
  String get settingsVisualizerBlinkTraining =>
      'Entrenamiento de parpadeo (Paso de parpadeo)';

  @override
  String get settingsVisualizerAmbient => 'Flujo ambiental';

  @override
  String get settingsVisualizerStarry => 'Cielo estrellado';

  @override
  String get settingsShowCountdownDesc =>
      'Mostrar el tiempo restante del descanso';

  @override
  String get settingsShowTipsDesc => 'Rotar consejos durante el descanso';

  @override
  String get settingsShowProgressDesc =>
      'Visualizar el progreso del descanso en diseños clásicos';

  @override
  String get settingsCustomBreakMessage => 'Mensaje de descanso personalizado';

  @override
  String get settingsCustomBreakMessageSubtitle =>
      'Texto opcional mostrado antes de los consejos rotativos';

  @override
  String get settingsCustomBreakMessageHint =>
      'Cierra los ojos y respira lentamente.';

  @override
  String get settingsChimeTibetanBowl => 'Cuenco tibetano';

  @override
  String get settingsChimeWindChimes => 'Campanas de viento';

  @override
  String get settingsChimeZenBell => 'Campana Zen';

  @override
  String get settingsChimeSystemAlert => 'Alerta del sistema';

  @override
  String get settingsConsciousBlinkingDesc =>
      'Envía notificaciones periódicas del sistema para recordarte que parpadees durante las sesiones de trabajo';

  @override
  String get settingsAiMotivationTitle => 'Motivación por IA y avisos';

  @override
  String get settingsAiMotivationSubtitle =>
      'Generar frases personalizadas de cuidado ocular durante los descansos';

  @override
  String get settingsAiMotivationEnabledSubtitle =>
      'Generar frases personalizadas durante los descansos';

  @override
  String get settingsAiProviderGemini => 'Google Gemini';

  @override
  String get settingsAiProviderOpenAi => 'OpenAI (ChatGPT)';

  @override
  String get settingsAiProviderGroq => 'Groq (Rápido)';

  @override
  String get settingsAiModelCustom => 'Personalizado...';

  @override
  String get settingsAiLoadModelsError =>
      'No se pudieron cargar los modelos. Usando los valores predeterminados.';

  @override
  String settingsExportedSnackbar(String fileName) {
    return 'Ajustes exportados a: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Error al realizar copia de seguridad de ajustes: $error';
  }

  @override
  String get settingsLongBreakModeDesc =>
      'Toma un descanso más largo después de un número determinado de ciclos de trabajo';

  @override
  String get settingsDesktopStartupBehavior =>
      'Comportamiento de inicio en escritorio';

  @override
  String get settingsDesktopStartupBehaviorSubtitle =>
      'Controlar el inicio al iniciar sesión y el comportamiento de inicio minimizado';

  @override
  String get settingsBackup => 'Copia de seguridad';

  @override
  String get settingsRestore => 'Restablecer';

  @override
  String get timerTakeBreakNow => 'Tomar descanso ahora';

  @override
  String get timerCancelSnooze => 'Cancelar posposición';

  @override
  String get timerSnooze1h => 'Posponer 1h';

  @override
  String get timerTomorrow => 'Mañana';

  @override
  String get timerNaturalBreakCredited =>
      '¡Descanso natural detectado y acreditado! Temporizador restablecido.';

  @override
  String get notificationPermissionTitle => '¿Activar notificaciones?';

  @override
  String get notificationPermissionMessage =>
      'BlinkKind utiliza notificaciones para recordarte cuándo está por comenzar tu descanso ocular. Sin este permiso, el recordatorio solo aparecerá mientras la aplicación esté abierta.\n\nPuedes cambiar esto en cualquier momento en Ajustes.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get openSettings => 'Abrir Ajustes';

  @override
  String get settingsCategoryAbout => 'Acerca de BlinkKind';

  @override
  String get settingsAboutVersion => 'Versión de la aplicación';

  @override
  String get settingsAboutPrivacyTitle => 'Política de privacidad';

  @override
  String get settingsAboutPrivacySubtitle => '100% sin conexión y local-first';

  @override
  String get settingsAboutPrivacyBody =>
      'BlinkKind es una aplicación local-first y 100% sin conexión. Tus sesiones de enfoque, configuración e historial se guardan exclusivamente en tu dispositivo local. No recopilamos, almacenamos ni transmitimos ningún dato personal, métricas de uso ni transmisiones de cámara o micrófono.';

  @override
  String get settingsAboutLicensesTitle => 'Licencias de código abierto';

  @override
  String get settingsAboutLicensesSubtitle =>
      'Bibliotecas de software de terceros utilizadas';

  @override
  String get close => 'Cerrar';
}
