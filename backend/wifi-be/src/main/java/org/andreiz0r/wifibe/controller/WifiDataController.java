package org.andreiz0r.wifibe.controller;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.andreiz0r.wifibe.entity.WifiData;
import org.andreiz0r.wifibe.request.CreateWifiDataRequest;
import org.andreiz0r.wifibe.service.WifiDataService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/networks")
@RequiredArgsConstructor
public class WifiDataController {
    private final WifiDataService wifiDataService;

    @PostMapping
    public ResponseEntity<WifiData> processNetworkInfo(@RequestBody final CreateWifiDataRequest createWifiDataRequest, final HttpServletRequest request) {
        return ResponseEntity.ok(wifiDataService.create(createWifiDataRequest, request.getRemoteAddr()));
    }

    @GetMapping
    public ResponseEntity<List<WifiData>> getNetworks() {
        return ResponseEntity.ok(wifiDataService.findAll());
    }

    @DeleteMapping("/{mac}")
    public ResponseEntity<WifiData> deleteNetwork(@PathVariable final String mac) {
        return wifiDataService.deleteByMac(mac)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
