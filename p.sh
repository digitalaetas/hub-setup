#!/usr/bin/env bash
# Postavlja novu lozinku korisniku huba. Lozinku upisuješ ti, ne vidi se i ne ostaje u povijesti naredbi.
set -euo pipefail
cd /opt/hub
read -rp "E-posta korisnika [hello@digitalaetas.hr]: " EMAIL
EMAIL="${EMAIL:-hello@digitalaetas.hr}"
read -rsp "Nova lozinka (najmanje 12 znakova): " P1; echo
read -rsp "Ponovi lozinku: " P2; echo
if [ "$P1" != "$P2" ]; then echo "Lozinke se ne podudaraju."; exit 1; fi
if [ "${#P1}" -lt 12 ]; then echo "Lozinka mora imati najmanje 12 znakova."; exit 1; fi
docker compose -f docker-compose.prod.yml exec -T -e NEWPASS="$P1" -e EMAIL="$EMAIL" app node --input-type=module - <<'JS'
import pg from "pg";
import bcrypt from "bcryptjs";
const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();
const hash = await bcrypt.hash(process.env.NEWPASS, 12);
const r = await db.query("update users set password_hash=$2, session_version=session_version+1 where lower(email)=lower($1) returning id", [process.env.EMAIL.trim(), hash]);
console.log(r.rowCount ? "Lozinka promijenjena." : "Korisnik s tom e-postom ne postoji.");
await db.end();
JS
