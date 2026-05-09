#!/bin/bash
set -euo pipefail

echo "==> Starting Urlaubsverwaltung on Cloudron"

# ---------------------------------------------------------------------------
# Persistent data directories (survive app restarts via /app/data volume).
# ---------------------------------------------------------------------------
mkdir -p /app/data/backups /app/data/logs
chown -R cloudron:cloudron /app/data

# ---------------------------------------------------------------------------
# Database (Cloudron postgresql addon)
# ---------------------------------------------------------------------------
export SPRING_DATASOURCE_URL="jdbc:postgresql://${CLOUDRON_POSTGRESQL_HOST}:${CLOUDRON_POSTGRESQL_PORT}/${CLOUDRON_POSTGRESQL_DATABASE}"
export SPRING_DATASOURCE_USERNAME="${CLOUDRON_POSTGRESQL_USERNAME}"
export SPRING_DATASOURCE_PASSWORD="${CLOUDRON_POSTGRESQL_PASSWORD}"

# ---------------------------------------------------------------------------
# SMTP (Cloudron sendmail addon)
# ---------------------------------------------------------------------------
export SPRING_MAIL_HOST="${CLOUDRON_MAIL_SMTP_SERVER}"
export SPRING_MAIL_PORT="${CLOUDRON_MAIL_SMTP_PORT}"
export SPRING_MAIL_USERNAME="${CLOUDRON_MAIL_SMTP_USERNAME}"
export SPRING_MAIL_PASSWORD="${CLOUDRON_MAIL_SMTP_PASSWORD}"
export SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH=true
export SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE=true

export UV_MAIL_FROM="${CLOUDRON_MAIL_FROM}"
export UV_MAIL_FROMDISPLAYNAME="${CLOUDRON_MAIL_FROM_DISPLAY_NAME:-Urlaubsverwaltung}"
export UV_MAIL_REPLYTO="${CLOUDRON_MAIL_FROM}"
export UV_MAIL_REPLYTODISPLAYNAME="${CLOUDRON_MAIL_FROM_DISPLAY_NAME:-Urlaubsverwaltung}"
export UV_MAIL_APPLICATIONURL="${CLOUDRON_APP_ORIGIN}"

# iCal calendar organizer (required, must be a valid email).
export UV_CALENDAR_ORGANIZER="${CLOUDRON_MAIL_FROM}"

# ---------------------------------------------------------------------------
# OIDC (Cloudron oidc addon)
# Cloudron exposes CLOUDRON_OIDC_ISSUER as the issuer URI; Spring Boot will
# auto-discover endpoints from {issuer}/.well-known/openid-configuration.
# The redirect URI registered in CloudronManifest.json must match Spring's
# default of /login/oauth2/code/{registrationId}, here "default".
# ---------------------------------------------------------------------------
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_DEFAULT_CLIENT_ID="${CLOUDRON_OIDC_CLIENT_ID}"
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_DEFAULT_CLIENT_SECRET="${CLOUDRON_OIDC_CLIENT_SECRET}"
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_DEFAULT_SCOPE="openid,profile,email"
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_DEFAULT_PROVIDER="default"
export SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_DEFAULT_ISSUER_URI="${CLOUDRON_OIDC_ISSUER}"
export SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI="${CLOUDRON_OIDC_ISSUER}"

# ---------------------------------------------------------------------------
# Persistent paths and server config
# ---------------------------------------------------------------------------
export UV_BACKUP_BACKUP_CONFIGURATION_FILESYSTEM_BACKUPPATH="/app/data/backups/"
export LOGGING_FILE_NAME="/app/data/logs/urlaubsverwaltung.log"
export SERVER_PORT=8080

# Honor X-Forwarded-* headers from Cloudron's reverse proxy so that Spring
# constructs absolute URLs (incl. the OAuth2 redirect URI) using the public
# https://<location> origin instead of the internal container address.
export SERVER_FORWARD_HEADERS_STRATEGY=framework

# Tune JVM for Cloudron's container memory limit (declared in manifest).
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -XX:MaxRAMPercentage=70 -XX:+ExitOnOutOfMemoryError"

echo "==> Launching JVM"
exec /usr/local/bin/gosu cloudron:cloudron java -jar /app/code/urlaubsverwaltung.jar
