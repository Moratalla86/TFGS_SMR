package com.meltic.gmao.controller;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.meltic.gmao.model.OrdenTrabajo;
import com.meltic.gmao.service.MantenimientoService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/ordenes")
@CrossOrigin(origins = "*")
@Tag(name = "Gestión - Órdenes de Trabajo", description = "Ciclo de vida completo del mantenimiento industrial (Correctivo/Predictivo)")
public class OrdenTrabajoController {

    @Autowired
    private MantenimientoService mantenimientoService;

    // ── Consultas ──────────────────────────────────────────────────────────────
    @Operation(summary = "Listar todas las OTs", description = "Obtiene el catálogo completo de órdenes (requiere rol JEFE)")
    @GetMapping
    public List<OrdenTrabajo> listarTodas() {
        return mantenimientoService.obtenerTodas();
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrdenTrabajo> obtenerPorId(@PathVariable Long id) {
        return mantenimientoService.obtenerPorId(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/tecnico/{tecnicoId}")
    public List<OrdenTrabajo> listarPorTecnico(@PathVariable Long tecnicoId) {
        return mantenimientoService.obtenerPorTecnico(tecnicoId);
    }

    @GetMapping("/maquina/{maquinaId}")
    public List<OrdenTrabajo> listarPorMaquina(@PathVariable Long maquinaId) {
        return mantenimientoService.obtenerPorMaquina(maquinaId);
    }

    @Operation(summary = "Búsqueda avanzada de OTs", description = "Filtra órdenes por técnico, máquina, estado o prioridad.")
    @GetMapping("/buscar")
    public List<OrdenTrabajo> buscar(
            @RequestParam(required = false) Long tecnicoId,
            @RequestParam(required = false) Long maquinaId,
            @RequestParam(required = false) String estado,
            @RequestParam(required = false) String prioridad,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fechaDesde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fechaHasta) {

        return mantenimientoService.buscarConFiltros(tecnicoId, maquinaId, estado, prioridad, fechaDesde, fechaHasta);
    }

    // ── Creación (Jefe) ────────────────────────────────────────────────────────
    @Operation(summary = "Crear nueva OT", description = "Registra una orden en el sistema. Se usa para mantenimientos planificados o avisos de avería.")
    @PostMapping
    public ResponseEntity<OrdenTrabajo> crear(@RequestBody OrdenTrabajo ordenTrabajo) {
        return ResponseEntity.ok(mantenimientoService.crearOrden(ordenTrabajo));
    }

    // ── Asignación (Jefe) ──────────────────────────────────────────────────────
    @PatchMapping("/{id}/asignar")
    public ResponseEntity<OrdenTrabajo> asignar(
            @PathVariable Long id,
            @RequestParam(required = false) Long tecnicoId,
            @RequestParam(required = false) Long maquinaId) {
        return mantenimientoService.asignarTecnicoYMaquina(id, tecnicoId, maquinaId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Cambio de estado genérico (Jefe) ──────────────────────────────────────
    @PatchMapping("/{id}/estado")
    public ResponseEntity<OrdenTrabajo> actualizarEstado(
            @PathVariable Long id,
            @RequestParam String estado) {
        return mantenimientoService.actualizarEstado(id, estado)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Iniciar OT (Técnico) ───────────────────────────────────────────────────
    @Operation(summary = "Iniciar Trabajo", description = "Acción del Técnico para marcar el inicio real del trabajo en campo")
    @PatchMapping("/{id}/iniciar")
    public ResponseEntity<OrdenTrabajo> iniciar(@PathVariable Long id) {
        return mantenimientoService.iniciarOT(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Actualizar acciones / trabajos realizados (Técnico) ───────────────────
    @PatchMapping("/{id}/acciones")
    public ResponseEntity<OrdenTrabajo> actualizarAcciones(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String trabajos = body.get("trabajosRealizados");
        return mantenimientoService.actualizarTrabajosRealizados(id, trabajos)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Cerrar OT (Técnico) ────────────────────────────────────────────────────
    @Operation(summary = "Cerrar Orden", description = "Finaliza el trabajo. Calcula tiempo transcurrido y cambia estado a CERRADA.")
    @PatchMapping("/{id}/cerrar")
    public ResponseEntity<OrdenTrabajo> cerrar(
            @PathVariable Long id,
            @RequestBody Map<String, String> payload) {
        return mantenimientoService.cerrarOT(id, payload)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @Operation(summary = "Descargar Reporte PDF", description = "Recupera el archivo PDF de la OT. Si no existe, se genera dinámicamente.")
    @GetMapping("/{id}/reporte")
    public ResponseEntity<byte[]> descargarReporte(@PathVariable Long id) {
        byte[] pdfData = mantenimientoService.obtenerReportePdf(id);
        return ResponseEntity.ok()
                .header("Content-Type", "application/pdf")
                .header("Content-Disposition", "attachment; filename=OT_" + id + ".pdf")
                .body(pdfData);
    }

    // ── Guardar firmas ─────────────────────────────────────────────────────────
    @Operation(summary = "Protocolo de Firmas", description = "Almacena las rúbricas digitales del técnico y del cliente (Base64)")
    @PatchMapping("/{id}/firmas")
    public ResponseEntity<OrdenTrabajo> guardarFirmas(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        return mantenimientoService.guardarFirmas(id, body.get("firmaTecnico"), body.get("firmaCliente"))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Eliminar (Jefe) ────────────────────────────────────────────────────────
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        mantenimientoService.eliminarOrden(id);
        return ResponseEntity.noContent().build();
    }
}
