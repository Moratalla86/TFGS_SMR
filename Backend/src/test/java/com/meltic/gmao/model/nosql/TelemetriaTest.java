package com.meltic.gmao.model.nosql;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
// Remove unused LocalDateTime import

class TelemetriaTest {

    @Test
    void testTelemetriaFields() {
        Telemetria t = new Telemetria();
        t.setTemperatura(25.5);
        t.setHumedad(60.0);
        t.setMotorOn(true);
        t.setMaquinaId(1L);
        
        assertEquals(25.5, t.getTemperatura(), 0.01);
        assertEquals(60.0, t.getHumedad(), 0.01);
        assertEquals(Boolean.TRUE, t.getMotorOn());
        assertEquals(Long.valueOf(1L), t.getMaquinaId());
        assertNotNull(t.getTimestamp());
    }
}
