#!/bin/bash
# =============================================================================
# Script para preparar OdinInventoryReadOnly para Powerpipe
# Ejecutar desde la VM con Semaphore_Role (Instance Profile)
# =============================================================================
set -e

TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::013960975594:role/Semaphore_Role"},
    "Action": "sts:AssumeRole"
  }]
}'

READONLY_POLICY="arn:aws:iam::aws:policy/ReadOnlyAccess"

# Cuentas donde OdinInventoryReadOnly YA EXISTE (solo ampliar permisos)
EXISTING_ACCOUNTS=(
  "223634394676"   # prd
  "339712901782"   # preprod
  "590183713498"   # garantias
  "471112907214"   # ciberseguridad
  "050752654368"   # mvno
  "866445667300"   # poc-innovacion
  "910617026399"   # qa
  "047719642223"   # macrolock
  "851725206747"   # sap
  "024268545623"   # gt-dev
  "797760781722"   # gt-prod
  "202210529120"   # gt-qa
  "876982715609"   # prendario-dev
  "960341592326"   # prendario-prod
  "587128718552"   # prendario-qa
  "013960975594"   # shared
)

# Cuentas donde NO EXISTE (crear + permisos)
MISSING_ACCOUNTS=(
  "248760527160"   # dev
  "611723039826"   # network
  "890956688577"   # audit
  "780452841926"   # log-archive
  "935133738204"   # macropay-root
)

assume_role() {
  local account_id=$1
  local role_arn="arn:aws:iam::${account_id}:role/OdinInventoryReadOnly"
  
  # Para las cuentas existentes, asumimos un rol con permisos admin
  # Usamos OrganizationAccountAccessRole o similar
  local creds
  creds=$(aws sts assume-role \
    --role-arn "arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole" \
    --role-session-name "powerpipe-setup" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text 2>/dev/null) || {
    echo "  ⚠️  No se pudo asumir OrganizationAccountAccessRole en $account_id"
    echo "     Intentando con Role-net-analyzer..."
    return 1
  }
  
  export AWS_ACCESS_KEY_ID=$(echo "$creds" | awk '{print $1}')
  export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | awk '{print $2}')
  export AWS_SESSION_TOKEN=$(echo "$creds" | awk '{print $3}')
}

clear_creds() {
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

echo "=============================================="
echo " PASO 1: Ampliar permisos en cuentas existentes"
echo "=============================================="

for account in "${EXISTING_ACCOUNTS[@]}"; do
  echo ""
  echo "→ Cuenta: $account"
  
  if assume_role "$account"; then
    # Adjuntar ReadOnlyAccess al rol existente
    if aws iam attach-role-policy \
      --role-name OdinInventoryReadOnly \
      --policy-arn "$READONLY_POLICY" 2>/dev/null; then
      echo "  ✅ ReadOnlyAccess adjuntado"
    else
      echo "  ℹ️  ReadOnlyAccess ya estaba adjuntado o error"
    fi
    clear_creds
  fi
done

echo ""
echo "=============================================="
echo " PASO 2: Crear rol en cuentas faltantes"
echo "=============================================="

for account in "${MISSING_ACCOUNTS[@]}"; do
  echo ""
  echo "→ Cuenta: $account"
  
  if assume_role "$account"; then
    # Crear el rol
    if aws iam create-role \
      --role-name OdinInventoryReadOnly \
      --assume-role-policy-document "$TRUST_POLICY" \
      --description "Read-only role for Powerpipe/Odin - cross-account from Semaphore" \
      --tags Key=Project,Value=Odin Key=ManagedBy,Value=Semaphore 2>/dev/null; then
      echo "  ✅ Rol creado"
    else
      echo "  ℹ️  Rol ya existe o error al crear"
    fi
    
    # Adjuntar ReadOnlyAccess
    if aws iam attach-role-policy \
      --role-name OdinInventoryReadOnly \
      --policy-arn "$READONLY_POLICY" 2>/dev/null; then
      echo "  ✅ ReadOnlyAccess adjuntado"
    else
      echo "  ℹ️  Error al adjuntar policy"
    fi
    clear_creds
  fi
done

echo ""
echo "=============================================="
echo " PASO 3: Actualizar policy de Semaphore_Role"
echo "=============================================="
echo ""
echo "Agregar las cuentas faltantes a OdinAssumeInventory_Policy:"
echo ""
for account in "${MISSING_ACCOUNTS[@]}"; do
  echo "  arn:aws:iam::${account}:role/OdinInventoryReadOnly"
done
echo ""
echo "⚠️  Esto debe hacerse manualmente en la cuenta shared (013960975594)"
echo "    IAM → Roles → Semaphore_Role → OdinAssumeInventory_Policy → Edit"
echo ""

echo "=============================================="
echo " VERIFICACIÓN"
echo "=============================================="

ALL_ACCOUNTS=("${EXISTING_ACCOUNTS[@]}" "${MISSING_ACCOUNTS[@]}")
echo ""
echo "Probando AssumeRole a cada cuenta..."
for account in "${ALL_ACCOUNTS[@]}"; do
  if aws sts assume-role \
    --role-arn "arn:aws:iam::${account}:role/OdinInventoryReadOnly" \
    --role-session-name "test-powerpipe" \
    --query 'Credentials.AccessKeyId' \
    --output text >/dev/null 2>&1; then
    echo "  ✅ $account - OK"
  else
    echo "  ❌ $account - FALLO"
  fi
done

echo ""
echo "Done!"
