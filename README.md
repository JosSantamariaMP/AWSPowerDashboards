# Powerpipe Server - Multi-Cuenta AWS con EntraID

Servidor Powerpipe dockerizado que consulta **21 cuentas AWS** vía IAM Roles cross-account, protegido con Microsoft EntraID (control por grupo) y TLS automático.

## Arquitectura

```
┌──────────┐      ┌───────────┐      ┌──────────────┐      ┌───────────┐
│  Browser │─443─▶│   Caddy   │─4180▶│ OAuth2-Proxy │─9033▶│ Powerpipe │
│  (HTTPS) │      │ (TLS auto)│      │(EntraID+Group)│      │  (server) │
└──────────┘      └───────────┘      └──────────────┘      └─────┬─────┘
                                                                  │ 9193
                                                            ┌─────▼─────┐
                                                            │ Steampipe │
                                                            │(AssumeRole)│
                                                            └─────┬─────┘
                                                                  │
                              ┌────────────────────────────────────┼──────────────────┐
                              ▼                                    ▼                  ▼
                    ┌──────────────┐                    ┌──────────────┐    ┌──────────────┐
                    │  Cuenta Dev  │                    │  Cuenta PRD  │    │  ... (x21)   │
                    │PowerpipeRead │                    │PowerpipeRead │    │PowerpipeRead │
                    └──────────────┘                    └──────────────┘    └──────────────┘
```

## Cadena de confianza IAM

```
EC2 Instance Profile
  └─▶ Semaphore_Role (013960975594)
        ├─ Trust: ec2.amazonaws.com
        ├─ Policy: sts:AssumeRole → PowerpipeReadOnly en cada cuenta
        │
        └─▶ PowerpipeReadOnly (en cada cuenta destino)
              ├─ Trust: arn:aws:iam::013960975594:role/Semaphore_Role
              └─ Permissions: ReadOnlyAccess (o SecurityAudit)
```

### Verificación del rol actual Semaphore_Role

El rol `arn:aws:iam::013960975594:role/Semaphore_Role` ya existe y tiene:
- **Trust Policy**: `ec2.amazonaws.com` (permite Instance Profile)
- **Inline Policy `AsumirRoleRemoto_Policy`**: Permite `sts:AssumeRole` a roles en múltiples cuentas
- **Inline Policy `OdinAssumeInventory_Policy`**: Permite asumir `OdinInventoryReadOnly` en 17 cuentas

**Acción requerida**: Agregar permiso para asumir `PowerpipeReadOnly` en las 21 cuentas:

```json
{
  "Sid": "PowerpipeAssumeRoles",
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": [
    "arn:aws:iam::013960975594:role/PowerpipeReadOnly",
    "arn:aws:iam::248760527160:role/PowerpipeReadOnly",
    "arn:aws:iam::611723039826:role/PowerpipeReadOnly",
    "arn:aws:iam::890956688577:role/PowerpipeReadOnly",
    "arn:aws:iam::339712901782:role/PowerpipeReadOnly",
    "arn:aws:iam::590183713498:role/PowerpipeReadOnly",
    "arn:aws:iam::471112907214:role/PowerpipeReadOnly",
    "arn:aws:iam::780452841926:role/PowerpipeReadOnly",
    "arn:aws:iam::935133738204:role/PowerpipeReadOnly",
    "arn:aws:iam::050752654368:role/PowerpipeReadOnly",
    "arn:aws:iam::866445667300:role/PowerpipeReadOnly",
    "arn:aws:iam::223634394676:role/PowerpipeReadOnly",
    "arn:aws:iam::910617026399:role/PowerpipeReadOnly",
    "arn:aws:iam::047719642223:role/PowerpipeReadOnly",
    "arn:aws:iam::851725206747:role/PowerpipeReadOnly",
    "arn:aws:iam::024268545623:role/PowerpipeReadOnly",
    "arn:aws:iam::797760781722:role/PowerpipeReadOnly",
    "arn:aws:iam::202210529120:role/PowerpipeReadOnly",
    "arn:aws:iam::876982715609:role/PowerpipeReadOnly",
    "arn:aws:iam::960341592326:role/PowerpipeReadOnly",
    "arn:aws:iam::587128718552:role/PowerpipeReadOnly"
  ]
}
```

Agregar este statement a la inline policy `AsumirRoleRemoto_Policy` del `Semaphore_Role`, o crear una nueva inline policy.

## 1. Crear rol PowerpipeReadOnly en cada cuenta

### Trust Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::013960975594:role/Semaphore_Role"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions

Opción A (amplio): Adjuntar `arn:aws:iam::aws:policy/ReadOnlyAccess`

Opción B (compliance-focused): Adjuntar `arn:aws:iam::aws:policy/SecurityAudit`

Opción C (ambos):
```bash
aws iam attach-role-policy --role-name PowerpipeReadOnly \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

aws iam attach-role-policy --role-name PowerpipeReadOnly \
  --policy-arn arn:aws:iam::aws:policy/SecurityAudit
```

### Script para crear el rol en todas las cuentas

```bash
ACCOUNTS="248760527160 611723039826 890956688577 339712901782 590183713498 471112907214 780452841926 935133738204 050752654368 866445667300 223634394676 910617026399 047719642223 851725206747 024268545623 797760781722 202210529120 876982715609 960341592326 587128718552"

TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::013960975594:role/Semaphore_Role"},
    "Action": "sts:AssumeRole"
  }]
}'

for ACCOUNT in $ACCOUNTS; do
  echo "Creando PowerpipeReadOnly en $ACCOUNT..."
  # Requiere acceso admin a cada cuenta (usar SSO profiles o StackSets)
  aws iam create-role \
    --role-name PowerpipeReadOnly \
    --assume-role-policy-document "$TRUST_POLICY" \
    --description "Read-only role for Powerpipe compliance scanning" \
    --profile "aws-sso-$(echo $ACCOUNT | xargs)"

  aws iam attach-role-policy \
    --role-name PowerpipeReadOnly \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess \
    --profile "aws-sso-$(echo $ACCOUNT | xargs)"
done
```

> **Recomendación**: Usar AWS CloudFormation StackSets para desplegar el rol en todas las cuentas de la organización de forma consistente.

### Cuentas configuradas

| Nombre | Account ID | Region |
|--------|-----------|--------|
| shared | 013960975594 | us-east-1 |
| dev | 248760527160 | us-east-1 |
| network | 611723039826 | us-east-1 |
| audit | 890956688577 | us-east-1 |
| preprod | 339712901782 | us-east-1 |
| garantias | 590183713498 | us-east-1 |
| ciberseguridad | 471112907214 | us-east-1 |
| log-archive | 780452841926 | us-east-1 |
| macropay-root | 935133738204 | us-east-1 |
| mvno | 050752654368 | us-east-1 |
| poc-innovacion | 866445667300 | us-east-1 |
| prd | 223634394676 | us-east-1 |
| qa | 910617026399 | us-east-1 |
| macrolock | 047719642223 | us-east-1 |
| sap | 851725206747 | us-east-1, us-west-2 |
| gt-dev | 024268545623 | us-east-1 |
| gt-prod | 797760781722 | us-east-1 |
| gt-qa | 202210529120 | us-east-1 |
| prendario-dev | 876982715609 | us-east-1 |
| prendario-prod | 960341592326 | us-east-1 |
| prendario-qa | 587128718552 | us-east-1 |

## 2. Configurar EntraID con filtro de grupo

### App Registration

1. **Azure Portal** → Microsoft Entra ID → App registrations → New registration
2. Nombre: `Powerpipe Server`
3. Redirect URI: `Web` → `https://<DOMINIO>/oauth2/callback`
4. En **Certificates & secrets** → New client secret
5. En **Token configuration** → Add groups claim:
   - Seleccionar "Security groups"
   - En ID token: check "Group ID"
6. En **API permissions** → Add permission → Microsoft Graph → `GroupMember.Read.All` (delegated)
7. En **Manifest** → verificar `"groupMembershipClaims": "SecurityGroup"`

### Obtener el Group Object ID

1. Azure Portal → Microsoft Entra ID → Groups
2. Buscar o crear el grupo (ej: `SG-Powerpipe-Viewers`)
3. Copiar el **Object ID** (ej: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
4. Pegar en `.env` como `ENTRA_ALLOWED_GROUP_ID`

> Solo usuarios miembros de ese grupo podrán acceder a Powerpipe.

## 3. Variables de entorno

```bash
cp .env.example .env
```

```bash
# Generar cookie secret
python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
```

| Variable | Dónde obtenerla |
|----------|----------------|
| `AZURE_TENANT_ID` | Azure Portal → Entra ID → Overview → Tenant ID |
| `OAUTH2_PROXY_CLIENT_ID` | App Registration → Application (client) ID |
| `OAUTH2_PROXY_CLIENT_SECRET` | App Registration → Certificates & secrets |
| `ENTRA_ALLOWED_GROUP_ID` | Entra ID → Groups → Object ID del grupo |
| `DOMAIN` | DNS apuntando a la IP de tu VM |

## 4. Despliegue con Docker Compose (directo)

```bash
cd docker/
cp .env.example .env
# Editar .env con valores reales

docker compose up -d
docker compose logs -f
```

## 5. Despliegue en Coolify

### Opción A: Docker Compose (recomendada)

1. En Coolify → **Projects** → Crear nuevo proyecto → **Add Resource** → **Docker Compose**
2. **Source**: Apuntar al repositorio git que contenga esta carpeta `docker/`, o subir directamente
3. **Base Directory**: `docker/` (si está dentro de un repo más grande)
4. **Environment Variables**: Agregar las variables del `.env.example`:
   - `AZURE_TENANT_ID`
   - `OAUTH2_PROXY_CLIENT_ID`
   - `OAUTH2_PROXY_CLIENT_SECRET`
   - `OAUTH2_PROXY_COOKIE_SECRET`
   - `ENTRA_ALLOWED_GROUP_ID`
   - `DOMAIN`
5. **Network**: Coolify asigna una red automáticamente
6. **Domains**: Configurar el dominio en la sección de Caddy/proxy de Coolify

### Opción B: Usar proxy de Coolify (sin Caddy)

Si prefieres usar el Traefik/Caddy integrado de Coolify en lugar del Caddy de este compose:

1. En `docker-compose.yml`, **eliminar** el servicio `caddy`
2. Exponer el puerto de `oauth2-proxy`:
   ```yaml
   oauth2-proxy:
     ports:
       - "4180:4180"
   ```
3. En Coolify, configurar el dominio y que apunte al puerto `4180`
4. Coolify gestionará TLS automáticamente
5. Actualizar `OAUTH2_PROXY_REDIRECT_URL` al dominio asignado por Coolify

### Opción C: Docker Compose con proxy Coolify (hybrid)

Archivo alternativo `docker-compose.coolify.yml`:

```yaml
services:
  steampipe:
    build:
      context: .
      dockerfile: Dockerfile.steampipe
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -p 9193 -U steampipe"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    restart: unless-stopped

  powerpipe:
    build:
      context: .
      dockerfile: Dockerfile.powerpipe
    depends_on:
      steampipe:
        condition: service_healthy
    restart: unless-stopped

  oauth2-proxy:
    image: quay.io/oauth2-proxy/oauth2-proxy:v7.7.1
    command:
      - --provider=oidc
      - --oidc-issuer-url=https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
      - --client-id=${OAUTH2_PROXY_CLIENT_ID}
      - --client-secret=${OAUTH2_PROXY_CLIENT_SECRET}
      - --cookie-secret=${OAUTH2_PROXY_COOKIE_SECRET}
      - --redirect-url=https://${DOMAIN}/oauth2/callback
      - --upstream=http://powerpipe:9033
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --cookie-secure=true
      - --reverse-proxy=true
      - --skip-provider-button=true
      - --oidc-groups-claim=groups
      - --allowed-group=${ENTRA_ALLOWED_GROUP_ID}
    ports:
      - "4180:4180"
    depends_on:
      - powerpipe
    restart: unless-stopped
```

En Coolify: configurar el dominio apuntando al puerto **4180** del servicio.

### Notas Coolify

- Si la EC2 de Coolify ya tiene el Instance Profile `Semaphore_Role`, los contenedores heredan las credenciales automáticamente via IMDS
- Verificar que el Security Group permita tráfico HTTPS (443) desde internet
- En Coolify, configurar los health checks del servicio a `http://localhost:4180/ping`

## Verificación post-despliegue

```bash
# Verificar que Steampipe puede asumir roles
docker compose exec steampipe steampipe query \
  "select account_id, partition from aws_all.aws_account"

# Verificar todas las conexiones
docker compose exec steampipe steampipe query \
  "select name from steampipe_connection where name like 'aws_%'"

# Verificar que oauth2-proxy responde
curl -s http://localhost:4180/ping
# Debería retornar: OK
```

## Estructura de archivos

```
docker/
├── Caddyfile                     # Reverse proxy TLS
├── Dockerfile.powerpipe          # Imagen Powerpipe con mods
├── Dockerfile.steampipe          # Imagen Steampipe con plugin AWS
├── docker-compose.yml            # Despliegue completo (con Caddy)
├── docker-compose.coolify.yml    # Despliegue para Coolify (sin Caddy)
├── .env.example                  # Template variables
├── .gitignore                    # Excluye .env
├── config/
│   ├── aws.spc                   # Conexiones cross-account (AssumeRole)
│   └── mod.pp                    # Mods de compliance/insights
└── README.md                     # Este archivo
```

## Seguridad

- 🔐 **Sin credenciales hardcoded** — usa Instance Profile (IMDS)
- 👥 **Acceso por grupo** — solo miembros del grupo EntraID pueden ver dashboards
- 🔒 **ReadOnly** — el rol `PowerpipeReadOnly` no puede modificar nada
- 🛡️ **Red interna** — solo el proxy expone puertos
- 📋 **TLS automático** — Caddy/Coolify gestiona certificados
- 🔄 **Rotar** `OAUTH2_PROXY_COOKIE_SECRET` periódicamente
