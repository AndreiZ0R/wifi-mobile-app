package org.andreiz0r.wifibe.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

import java.util.UUID;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder(setterPrefix = "with")
@ToString
public class WifiData {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String ssid;

    @Column(nullable = false, unique = true)
    private String mac;

    @Column(nullable = false)
    private String clientIp;

    @Column(nullable = false)
    private String security;

    @Column(nullable = false)
    private int signalStrength;
}
