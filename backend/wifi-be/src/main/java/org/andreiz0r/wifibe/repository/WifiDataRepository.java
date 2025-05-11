package org.andreiz0r.wifibe.repository;

import jakarta.transaction.Transactional;
import org.andreiz0r.wifibe.entity.WifiData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface WifiDataRepository extends JpaRepository<WifiData, UUID> {

    @Transactional
    @Modifying
    @Query(value = "delete from WifiData u where u.mac=:mac")
    Integer deleteByMac(final String mac);

    Optional<WifiData> findByMac(final String mac);
}
