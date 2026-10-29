#!/usr/bin/env bash
# Parte opcional: deja que Claude pida root con un botón en Telegram (tg-sudo).
#   sudo ./instalar-root.sh             instala
#   sudo ./instalar-root.sh --quitar    lo saca
# Instala tg-root (de root) y una regla de sudo que solo permite correr ESE programa sin contraseña.
# tg-root no hace nada sin tu "Autorizar" en Telegram. Volvé a correrlo si cambiás el token o la cuenta.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Correlo con sudo: sudo $0"; exit 1; }
USUARIO="${SUDO_USER:?correlo con sudo desde tu usuario, no como root directo}"
D="$(dirname "$(readlink -f "$0")")"
LIB=/usr/local/lib/claude-telegram
REGLA=/etc/sudoers.d/claude-telegram

if [ "${1:-}" = "--quitar" ]; then
  rm -rf "$LIB" "$REGLA" /etc/claude-telegram
  echo "Listo: tg-sudo ya no puede pedir root."
  exit 0
fi

CASA="$(getent passwd "$USUARIO" | cut -d: -f6)"
CONFIG="$CASA/.config/claude-telegram/config.json"
[ -f "$CONFIG" ] || { echo "No encuentro $CONFIG: primero corré claude-telegram configurar"; exit 1; }

install -d -m 755 -o root -g root "$LIB"
install -m 755 -o root -g root "$D/root/tg-root" "$LIB/tg-root"
install -d -m 700 -o root -g root /etc/claude-telegram
python3 -I - "$CONFIG" <<'EOF'
import json, os, sys
c = json.load(open(sys.argv[1]))
if not c.get("token") or not c.get("dueno"):
    sys.exit("La config no tiene token o cuenta vinculada: corré claude-telegram configurar")
fd = os.open("/etc/claude-telegram/root.json", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
os.write(fd, json.dumps({"token": c["token"], "dueno": c["dueno"]}).encode())
os.close(fd)
EOF

TMP="$(mktemp)"
echo "$USUARIO ALL=(root) NOPASSWD: $LIB/tg-root" > "$TMP"
visudo -cf "$TMP" >/dev/null
install -m 440 -o root -g root "$TMP" "$REGLA"
rm -f "$TMP"
echo "Listo: Claude puede usar tg-sudo y te va a llegar un botón para autorizar cada comando."
