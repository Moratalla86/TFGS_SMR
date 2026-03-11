package com.meltic.gmao.controller;

import com.meltic.gmao.model.OrdenTrabajo;
import com.meltic.gmao.service.MantenimientoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ordenes")
@CrossOrigin(origins = "*")
public class OrdenTrabajoController {

    @Autowired
    private MantenimientoService mantenimientoService;

    // ── Consultas ──────────────────────────────────────────────────────────────
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

    // ── Creación (Jefe) ────────────────────────────────────────────────────────
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
    @PatchMapping("/{id}/cerrar")
    public ResponseEntity<OrdenTrabajo> cerrar(
            @PathVariable Long id,
            @RequestBody Map<String, String> payload) {
        return mantenimientoService.cerrarOT(id, payload)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Guardar firmas ─────────────────────────────────────────────────────────
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
