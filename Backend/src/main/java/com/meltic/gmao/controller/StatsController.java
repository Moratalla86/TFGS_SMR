package com.meltic.gmao.controller;

import com.meltic.gmao.model.OrdenTrabajo;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.OrdenTrabajoRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/stats")
@CrossOrigin(origins = "*")
@Tag(name = "Analítica - Estadísticas Industriales", description = "Dashboard de KPIs para la toma de decisiones basada en datos (MTTR, Carga de Trabajo, Criticidad)")
public class StatsController {

    @Autowired
    private OrdenTrabajoRepository otRepo;

    @Operation(summary = "Obtener KPIs Globales", description = "Calcula el MTTR medio y la distribución de estados de las órdenes de trabajo.")
    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        List<OrdenTrabajo> todas = otRepo.findAll();
        
        // 1. MTTR (Mean Time To Repair) en minutos
        long mttrMinutos = 0;
        List<OrdenTrabajo> cerradas = todas.stream()
                .filter(ot -> ot.getFechaInicio() != null && ot.getFechaFin() != null)
                .collect(Collectors.toList());
        
        if (!cerradas.isEmpty()) {
            long totalMinutos = cerradas.stream()
                    .mapToLong(ot -> Duration.between(ot.getFechaInicio(), ot.getFechaFin()).toMinutes())
                    .sum();
            mttrMinutos = totalMinutos / cerradas.size();
        }

        // 2. MTBF (Mean Time Between Failures) aproximado
        // Calculamos tiempo entre el fin de una OT y la creación de la siguiente para la misma máquina
        long mtbfMinutos = 0;
        Map<Long, List<OrdenTrabajo>> porMaquina = cerradas.stream()
                .filter(ot -> ot.getMaquina() != null)
                .collect(Collectors.groupingBy(ot -> ot.getMaquina().getId()));
        
        List<Long> intervalosMtbf = new ArrayList<>();
        for (List<OrdenTrabajo> otsMaquina : porMaquina.values()) {
            otsMaquina.sort(Comparator.comparing(OrdenTrabajo::getFechaCreacion));
            for (int i = 0; i < otsMaquina.size() - 1; i++) {
                LocalDateTime finActual = otsMaquina.get(i).getFechaFin();
                LocalDateTime inicioSiguiente = otsMaquina.get(i + 1).getFechaCreacion();
                if (finActual != null && inicioSiguiente != null) {
                    intervalosMtbf.add(Duration.between(finActual, inicioSiguiente).toMinutes());
                }
            }
        }
        if (!intervalosMtbf.isEmpty()) {
            mtbfMinutos = intervalosMtbf.stream().mapToLong(Long::longValue).sum() / intervalosMtbf.size();
        }

        // 3. Lead Time (Tiempo de Respuesta medio)
        long leadTimeMinutos = 0;
        List<OrdenTrabajo> iniciadas = todas.stream()
                .filter(ot -> ot.getFechaCreacion() != null && ot.getFechaInicio() != null)
                .collect(Collectors.toList());
        if (!iniciadas.isEmpty()) {
            leadTimeMinutos = iniciadas.stream()
                    .mapToLong(ot -> Duration.between(ot.getFechaCreacion(), ot.getFechaInicio()).toMinutes())
                    .sum() / iniciadas.size();
        }

        // 4. Ratio Preventivo vs Correctivo
        long preventivas = todas.stream().filter(ot -> "PREVENTIVA".equals(ot.getTipo())).count();
        long correctivas = todas.stream().filter(ot -> "CORRECTIVA".equals(ot.getTipo())).count();
        double ratioPreventivo = todas.isEmpty() ? 0 : (double) preventivas / todas.size();

        // 5. Distribución por Estado
        Map<String, Long> porEstado = todas.stream()
                .collect(Collectors.groupingBy(OrdenTrabajo::getEstado, Collectors.counting()));

        // 6. Máquinas con más incidencias (Top 3)
        Map<String, Long> fallosPorMaquina = todas.stream()
                .filter(ot -> ot.getMaquina() != null)
                .collect(Collectors.groupingBy(ot -> ot.getMaquina().getNombre(), Collectors.counting()));
        
        List<Map.Entry<String, Long>> topMaquinas = fallosPorMaquina.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(3)
                .collect(Collectors.toList());

        // 7. Evolutivo de los últimos 6 meses (Preventivo vs Correctivo)
        List<String> mesesLabels = new ArrayList<>();
        List<Long> evolutivoCorrectivo = new ArrayList<>();
        List<Long> evolutivoPreventivo = new ArrayList<>();
        
        LocalDateTime hoy = LocalDateTime.now();
        for (int i = 5; i >= 0; i--) {
            YearMonth ym = YearMonth.from(hoy.minusMonths(i));
            String mesLabel = ym.getMonth().getDisplayName(TextStyle.SHORT, new Locale("es", "ES")).toUpperCase();
            mesesLabels.add(mesLabel);
            
            long correctivasMes = todas.stream()
                .filter(ot -> "CORRECTIVA".equals(ot.getTipo()))
                .filter(ot -> YearMonth.from(ot.getFechaCreacion()).equals(ym))
                .count();
                
            long preventivasMes = todas.stream()
                .filter(ot -> "PREVENTIVA".equals(ot.getTipo()))
                .filter(ot -> YearMonth.from(ot.getFechaCreacion()).equals(ym))
                .count();
                
            evolutivoCorrectivo.add(correctivasMes);
            evolutivoPreventivo.add(preventivasMes);
        }

        Map<String, Object> evolutivo = new HashMap<>();
        evolutivo.put("labels", mesesLabels);
        evolutivo.put("correctivo", evolutivoCorrectivo);
        evolutivo.put("preventivo", evolutivoPreventivo);

        Map<String, Object> stats = new HashMap<>();
        stats.put("mttr", mttrMinutos);
        stats.put("mtbf", mtbfMinutos);
        stats.put("leadTime", leadTimeMinutos);
        stats.put("ratioPreventivo", ratioPreventivo);
        stats.put("preventivasTotal", preventivas);
        stats.put("correctivasTotal", correctivas);
        stats.put("totalOTs", todas.size());
        stats.put("distribucionEstado", porEstado);
        stats.put("topMaquinas", topMaquinas);
        stats.put("evolutivo", evolutivo);
        stats.put("fechaCalculo", new Date());

        return ResponseEntity.ok(stats);
    }
}
