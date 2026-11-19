#!/usr/bin/env bash
# Postavljanje Aetas Huba na cist Ubuntu server (kao root). Ne sadrzi tajne.

REPO="git@github.com:digitalaetas/aetas-hub.git"
DIR=/opt/hub
ADMIN_EMAIL="${ADMIN_EMAIL:-hello@digitalaetas.hr}"
ADMIN_NAME="${ADMIN_NAME:-Digital Aetas}"

echo "== 1/5 Docker i vatrozid"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl ufw openssl >/dev/null
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh
ufw allow 22,80,443/tcp >/dev/null && ufw --force enable >/dev/null

echo "== 2/5 Kljuc za dohvat koda (samo čitanje)"
mkdir -p /root/.ssh && chmod 700 /root/.ssh
[ -f /root/.ssh/hub_deploy ] || ssh-keygen -t ed25519 -N "" -C "hub-server" -f /root/.ssh/hub_deploy >/dev/null
ssh-keyscan -t ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null
grep -q hub_deploy /root/.ssh/config 2>/dev/null || cat >> /root/.ssh/config <<'EOF'
Host github.com
  IdentityFile /root/.ssh/hub_deploy
  IdentitiesOnly yes
EOF
chmod 600 /root/.ssh/config
echo
echo "JAVNI KLJUC (zalijepi ga Claudeu u chat):"
echo "-----"
cat /root/.ssh/hub_deploy.pub
echo "-----"

echo "== 3/5 Cekam da ključ bude dodan na GitHub"
until git ls-remote "$REPO" >/dev/null 2>&1; do sleep 10; done
echo "Pristup radi."

echo "== 4/5 Kod i postavke"
[ -d "$DIR/.git" ] || git clone "$REPO" "$DIR"
cd "$DIR"
if [ ! -f .env ]; then
  cp .env.production.example .env
  sed -i "s|^SESSION_SECRET=.*|SESSION_SECRET=$(openssl rand -hex 32)|" .env
  sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -hex 32)|" .env
  chmod 600 .env
fi

echo "== 5/5 Pokretanje (nekoliko minuta)"
docker compose -f docker-compose.prod.yml up -d --build

echo "Cekam aplikaciju..."
for i in $(seq 1 60); do
  docker compose -f docker-compose.prod.yml exec -T app node -e "fetch('http://localhost:3000').then(()=>process.exit(0)).catch(()=>process.exit(1))" 2>/dev/null && break
  sleep 5
done

if [ ! -f /root/hub-admin-password.txt ]; then
  PASS="$(openssl rand -base64 18 | tr -d '/+=')Aa1"
  docker compose -f docker-compose.prod.yml exec -T -e ADMIN_PASSWORD="$PASS" app \
    node scripts/create-admin.mjs "$ADMIN_EMAIL" "$ADMIN_NAME"
  echo "$ADMIN_EMAIL  $PASS" > /root/hub-admin-password.txt
  chmod 600 /root/hub-admin-password.txt
fi

echo
echo "GOTOVO. Prijava na https://hub.digitalaetas.hr"
echo "E-posta: $ADMIN_EMAIL"
echo "Privremena lozinka: $(awk '{print $2}' /root/hub-admin-password.txt)"
echo "(zapisana i u /root/hub-admin-password.txt; promijeni je nakon prve prijave)"
