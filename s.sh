#!/usr/bin/env bash
# Postavlja slanje e-pošte (Zoho) za Aetas HUB. Lozinku za aplikaciju upisuješ ti; ne vidi se i ne ostaje u povijesti naredbi.
set -euo pipefail
cd /opt/hub
read -rp "Zoho korisnik [hub@digitalaetas.hr]: " U
U="${U:-hub@digitalaetas.hr}"
read -rsp "Lozinka za aplikaciju iz Zoha: " P; echo
[ -n "$P" ] || { echo "Lozinka je prazna."; exit 1; }
set_env() { grep -v "^$1=" .env > .env.tmp || true; echo "$1=$2" >> .env.tmp; mv .env.tmp .env; }
set_env SMTP_HOST smtppro.zoho.eu
set_env SMTP_PORT 465
set_env SMTP_USER "$U"
set_env SMTP_PASS "$P"
set_env MAIL_FROM "Aetas HUB <$U>"
chmod 600 .env
docker compose -f docker-compose.prod.yml up -d app worker
echo GOTOVO
