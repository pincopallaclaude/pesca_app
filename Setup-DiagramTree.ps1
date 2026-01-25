# 1. Verifica del percorso di esecuzione
$requiredPath = "C:\Projects\pesca_workspace\pesca_app"
if ($PSScriptRoot -ne $requiredPath -and $PWD.Path -ne $requiredPath) {
    Write-Error "Lo script deve essere eseguito in: $requiredPath"
    return
}

# Definizione della radice del widget
$basePath = "lib/widgets/live_diagram"

# 2. Verifica dell'esistenza della cartella lib
if (-not (Test-Path "lib")) {
    Write-Warning "Cartella 'lib' non trovata. Creazione in corso..."
    New-Item -ItemType Directory -Path "lib" | Out-Null
}

# Lista delle cartelle da creare
$directories = @(
    "$basePath/ai/models",
    "$basePath/ai/geometry",
    "$basePath/components",
    "$basePath/data",
    "$basePath/logic",
    "$basePath/painters",
    "$basePath/schema",
    "$basePath/ui",
    "$basePath/examples"
)

# Lista dei file da creare (se non esistono)
$files = @(
    "$basePath/ai/diagram_ai_agent.dart",
    "$basePath/ai/scenario_request_v2.dart",
    "$basePath/ai/semantic_engine.dart",
    "$basePath/ai/quality_metrics.dart",
    "$basePath/ai/models/node_metadata.dart",
    "$basePath/ai/geometry/curve_optimizer.dart",
    "$basePath/components/diagram_nodes.dart",
    "$basePath/components/diagram_overlay_builder.dart",
    "$basePath/data/ml_scenario.dart",
    "$basePath/logic/diagram_registry_enhanced.dart",
    "$basePath/logic/diagram_registry.dart",
    "$basePath/logic/diagram_topology.dart",
    "$basePath/painters/flow_diagram_painter.dart",
    "$basePath/painters/ml_story_renderer.dart",
    "$basePath/schema/diagram_schema.dart",
    "$basePath/ui/diagram_ai_console.dart",
    "$basePath/examples/ai_agent_example.dart",
    "$basePath/live_flow_diagram.dart"
)

Write-Host "--- Avvio creazione alberatura Live Diagram ---" -ForegroundColor Cyan

# 3. Creazione Cartelle
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory | Out-Null
        Write-Host "[NUOVO] Cartella creata: $dir" -ForegroundColor Green
    }
}

# 4. Creazione File
foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        New-Item -Path $file -ItemType File | Out-Null
        # Aggiungiamo un piccolo commento placeholder nei file nuovi/enhanced
        if ($file -like "*ai/*" -or $file -like "*enhanced*") {
            Set-Content -Path $file -Value "// File generato: $(Get-Date -Format 'dd/MM/yyyy')`n// TODO: Implementare logica specifica."
        }
        Write-Host "[OK] File creato: $file" -ForegroundColor Green
    } else {
        Write-Host "[ESISTENTE] Saltato: $file" -ForegroundColor Gray
    }
}

Write-Host "`nOperazione completata con successo!" -ForegroundColor Cyan