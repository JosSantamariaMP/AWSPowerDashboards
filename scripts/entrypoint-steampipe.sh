#!/bin/bash
set -e

echo "=== Steampipe Entrypoint ==="
echo "Fecha: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# Actualizar plugin AWS a la última versión
echo "Actualizando plugin AWS..."
if steampipe plugin update aws 2>&1; then
  echo "Plugin AWS actualizado correctamente."
else
  echo "WARN: No se pudo actualizar el plugin (usando versión instalada en build)."
fi

echo "Iniciando Steampipe service..."
exec steampipe service start --foreground --database-listen network --database-port 9193
