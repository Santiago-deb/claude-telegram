#!/usr/bin/env bash
# Instala claude-telegram para tu usuario y abre el asistente de configuración.
set -euo pipefail
D="$(dirname "$(readlink -f "$0")")"
command -v claude >/dev/null || { echo "Falta Claude Code (comando claude)."; exit 1; }
python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' || { echo "Hace falta Python 3.11 o más nuevo."; exit 1; }
command -v ffmpeg >/dev/null || echo "Aviso: sin ffmpeg no hay respuestas en audio (/tts)."

chmod +x "$D/claude-telegram" "$D/bin/tg-sudo" "$D/root/tg-root"
mkdir -p ~/.local/bin ~/.config/systemd/user
ln -sf "$D/claude-telegram" ~/.local/bin/claude-telegram
ln -sf "$D/bin/tg-sudo" ~/.local/bin/tg-sudo
sed "s|@DIR@|$D|g" "$D/claude-telegram.service" > ~/.config/systemd/user/claude-telegram.service
systemctl --user daemon-reload
echo "Instalado: claude-telegram y tg-sudo en ~/.local/bin, servicio claude-telegram.service."

[ "${1:-}" = "--sin-configurar" ] || exec "$D/claude-telegram" configurar
