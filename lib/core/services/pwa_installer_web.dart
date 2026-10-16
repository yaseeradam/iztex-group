import 'dart:js' as js;

/// Web implementation of PWA installer interacting with window JS functions.
class PwaInstallerPlatform {
  static bool get isPwaInstalled {
    try {
      if (js.context.hasProperty('isPwaInstalled')) {
        final result = js.context.callMethod('isPwaInstalled');
        return result == true;
      }
    } catch (_) {}
    return false;
  }

  static bool get canPrompt {
    try {
      if (js.context.hasProperty('canPromptPwaInstall')) {
        final result = js.context.callMethod('canPromptPwaInstall');
        return result == true;
      }
    } catch (_) {}
    return false;
  }

  static bool get isAppleDevice {
    try {
      if (js.context.hasProperty('isAppleDevice')) {
        final result = js.context.callMethod('isAppleDevice');
        return result == true;
      }
    } catch (_) {}
    return false;
  }

  static bool triggerInstall() {
    try {
      if (js.context.hasProperty('triggerPwaInstall')) {
        final result = js.context.callMethod('triggerPwaInstall');
        return result == true;
      }
    } catch (_) {}
    return false;
  }
}
