class WifiUtil {
  static String getSecurityTypeString(String capabilities) {
    if (capabilities.contains("WPA3")) {
      return "WPA3";
    } else if (capabilities.contains("WPA2")) {
      return "WPA2";
    } else if (capabilities.contains("WPA")) {
      return "WPA";
    } else if (capabilities.contains("WEP")) {
      return "WEP";
    } else if (capabilities.contains("ESS") &&
        !capabilities.contains("WPA") &&
        !capabilities.contains("WEP")) {
      return "Open (No Security)";
    } else {
      return "Unknown";
    }
  }

  static String getFrequencyBand(int frequency) {
    if (frequency >= 2400 && frequency <= 2500) {
      return "2.4 GHz";
    } else if (frequency >= 5000 && frequency <= 5900) {
      return "5 GHz";
    } else if (frequency >= 6000) {
      return "6 GHz";
    } else {
      return "Unknown";
    }
  }

  static String getSignalStrengthText(int level) {
    if (level >= -50) {
      return "Excellent";
    } else if (level >= -60) {
      return "Good";
    } else if (level >= -70) {
      return "Fair";
    } else {
      return "Poor";
    }
  }

  static int calculateApproximateChannel(int frequency) {
    if (frequency >= 2400 && frequency <= 2500) {
      // 2.4 GHz channels are separated by 5 MHz
      return ((frequency - 2407) ~/ 5);
    } else if (frequency >= 5000 && frequency <= 5900) {
      // 5 GHz first channel starts at 5180 MHz (channel 36)
      // and channels are separated by 20 MHz
      if (frequency >= 5180) {
        return 36 + ((frequency - 5180) ~/ 20) * 4;
      }
    }
    return 0;
  }
}
