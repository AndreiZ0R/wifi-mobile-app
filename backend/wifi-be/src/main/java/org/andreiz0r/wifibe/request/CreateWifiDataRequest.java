package org.andreiz0r.wifibe.request;

public record CreateWifiDataRequest(String ssid, String mac, String security, Integer signalStrength) {
}
