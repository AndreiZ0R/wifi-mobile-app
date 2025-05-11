package org.andreiz0r.wifibe.service;

import lombok.RequiredArgsConstructor;
import org.andreiz0r.wifibe.entity.WifiData;
import org.andreiz0r.wifibe.repository.WifiDataRepository;
import org.andreiz0r.wifibe.request.CreateWifiDataRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class WifiDataService {
    private final WifiDataRepository wifiDataRepository;

    public List<WifiData> findAll() {
        return wifiDataRepository.findAll();
    }

    public WifiData create(final CreateWifiDataRequest request, final String clientIp) {
        var wifiData = WifiData.builder()
                .withSsid(request.ssid())
                .withMac(request.mac())
                .withClientIp(clientIp)
                .withSecurity(request.security())
                .withSignalStrength(request.signalStrength())
                .build();

        return wifiDataRepository.save(wifiData);
    }

    public Optional<WifiData> deleteByMac(final String mac) {
        return wifiDataRepository.findByMac(mac)
                .filter(__ -> wifiDataRepository.deleteByMac(mac) != 0);
    }
}
