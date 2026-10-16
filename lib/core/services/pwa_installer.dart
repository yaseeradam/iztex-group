import 'package:flutter/foundation.dart';
import 'pwa_installer_stub.dart'
    if (dart.library.js) 'pwa_installer_web.dart';

class PwaService {
  static bool _hasPromptedThisSession = false;

  static bool get hasPromptedThisSession => _hasPromptedThisSession;

  static void markPrompted() {
    _hasPromptedThisSession = true;
  }

  /// Returns true if running as an installed PWA or running natively on mobile.
  static bool get isInstalled {
    if (!kIsWeb) return true;
    return PwaInstallerPlatform.isPwaInstalled;
  }

  /// Returns true if running on iOS / Safari.
  static bool get isAppleDevice {
    if (!kIsWeb) return false;
    return PwaInstallerPlatform.isAppleDevice;
  }

  /// Returns true if native browser prompt event is ready.
  static bool get canPrompt {
    if (!kIsWeb) return false;
    return PwaInstallerPlatform.canPrompt;
  }

  /// Triggers the native browser install dialog if available.
  static bool triggerInstall() {
    if (!kIsWeb) return false;
    return PwaInstallerPlatform.triggerInstall();
  }
}
