#!/bin/bash
set -e

echo "=== Powerpipe Entrypoint ==="
echo "Fecha: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# Actualizar mods a la última versión
echo "Actualizando Powerpipe mods..."
if powerpipe mod update 2>&1; then
  echo "Mods actualizados correctamente."
else
  echo "WARN: No se pudieron actualizar los mods (usando versión instalada en build)."
fi

echo "Iniciando Powerpipe server..."
exec powerpipe server --port 9033 --listen network --database "postgres://steampipe@steampipe:9193/steampipe"
