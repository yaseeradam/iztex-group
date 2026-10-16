/// Stub implementation of PWA installer for non-web platforms.
class PwaInstallerPlatform {
  static bool get isPwaInstalled => true;
  static bool get canPrompt => false;
  static bool get isAppleDevice => false;
  static bool triggerInstall() => false;
}
