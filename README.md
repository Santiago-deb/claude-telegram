# claude-telegram

Un bot **privado** de Telegram conectado a una sesión de [Claude Code](https://docs.claude.com/en/docs/claude-code) en tu PC. Le escribís desde el celular y es como estar en la terminal: lee y edita archivos, corre comandos, usa skills, te manda archivos de la PC y te puede contestar con audios.

- Solo le contesta a **tu** cuenta (se vincula con un código; los mensajes de cualquier otra cuenta se ignoran).
- Mientras el bot esté prendido y la PC tenga internet, está disponible. Si se corta la conexión, reintenta solo.
- Sin dependencias: Python 3.11+ con la biblioteca estándar.

## Qué podés hacer

| Desde Telegram | Qué pasa |
|---|---|
| Escribir cualquier cosa | Va a Claude Code. Mientras trabaja ves "escribiendo…" y un mensaje que muestra la herramienta que está usando. |
| Mandar una **foto** | Se guarda en la PC y Claude la ve. |
| Mandar un **archivo** | Se guarda en `~/Downloads/telegram` y Claude recibe la ruta. |
| Mandar una **nota de voz** | Se pasa a texto (faster-whisper, si está instalado) y te muestra lo que entendió. |
| "Mandame el pdf de…" | Claude te lo manda con `claude-telegram enviar`. Las carpetas van en zip (hasta 50 MB). |
| `/nombre-de-skill …` | Los skills y comandos de Claude Code andan igual que en la terminal. `/skills` los lista. |
| `/tts on` · `off` · `voces` · `-r` · `-stop` | Respuestas también en nota de voz, elegir voz, repetir el último audio, no mandar el de la respuesta en curso. |
| `/parar` | Corta lo que Claude está haciendo. |
| `/nueva` · `/retomar` · `/terminar` | Conversación nueva, volver a la anterior, cerrarla ya. |
| `/archivo RUTA` | Te manda ese archivo sin pasar por Claude. |
| `/detalle on/off` | Ver cada herramienta que usa Claude como mensaje aparte. |
| `/estado` · `/ayuda` · `/apagar` | Estado, ayuda, apagar el bot (se vuelve a prender desde la PC). |

### Conversaciones que se apagan solas

Si pasan **25 minutos** sin charla (ni mensaje tuyo ni respuesta de Claude), el bot te pregunta si mantiene la conversación, con botones **Seguir / Terminar**. Si no contestás que sí en **3 minutos**, la cierra (se libera la memoria de esa sesión de Claude). El bot sigue escuchando: tu próximo mensaje arranca una conversación nueva, o `/retomar` sigue la que se cerró. Mientras Claude está trabajando no cuenta como inactividad. Los dos tiempos se cambian en la config.

### Permisos de root con un botón

Claude no tiene tu contraseña. Para lo que necesita root usa `tg-sudo 'comando'` y a vos te llega:

> 🔐 **Permiso de root** — Claude quiere correr: `pacman -S htop` — **[✅ Autorizar] [❌ Rechazar]**

Si no contestás en 5 minutos, se rechaza. Cada pedido queda en `/var/log/claude-telegram-root.log`.

Cómo está hecho, para que sea seguro: `tg-root` es un programa de root con su propia copia del token y de tu id en `/etc/claude-telegram/root.json` (solo root la lee). Él mismo manda el botón con un código al azar y él mismo lee la respuesta de Telegram: solo vale si viene de tu cuenta y con ese código. Un proceso de tu usuario no puede falsificar el "sí". La regla de sudo solo deja correr ese programa sin contraseña.

## Instalación paso a paso

**Requisitos:** Linux con systemd, [Claude Code](https://docs.claude.com/en/docs/claude-code) instalado y con sesión iniciada (`claude` anda en la terminal), Python 3.11+. Opcionales: `ffmpeg` (audios), `qrencode` (QR para vincular), faster-whisper (notas de voz).

### 1. Crear el bot en Telegram (2 minutos)

1. En Telegram abrí **[@BotFather](https://t.me/BotFather)** (el oficial, con la tilde azul) y mandale `/newbot`.
2. Te pide un **nombre** (el que se ve, ej. `Mi Claude`) y un **usuario** que termine en `bot` (ej. `mi_claude_pc_bot`). Que no sea obvio: cuanto menos adivinable, mejor.
3. Te contesta con el **token**, algo como `123456789:AAH...`. Es la contraseña del bot: no lo compartas ni lo subas a ningún lado.
4. Recomendado, en el mismo @BotFather:
   - `/setjoingroups` → elegí tu bot → **Disable** (que nadie lo pueda meter en un grupo).
   - `/setprivacy` → tu bot → **Enable**.

### 2. Instalar

```bash
git clone https://github.com/Santiago-deb/claude-telegram.git
cd claude-telegram
./instalar.sh
```

Deja `claude-telegram` y `tg-sudo` en `~/.local/bin`, instala el servicio de usuario `claude-telegram.service` y abre el asistente, que:

1. Te pide el **token** (no se muestra al pegarlo) y verifica que ande.
2. Detecta si tenés voz (`tts-claude`) y transcriptor (faster-whisper) y los configura.
3. **Último paso, la conexión:** te muestra un enlace y un QR. Abrilo con el celular y tocá **Iniciar**. Listo: el bot te saluda y desde ahí **solo te contesta a vos**.
4. Te ofrece prender el bot (y que arranque con cada inicio de sesión).

Si alguna vez querés vincular otra cuenta: `claude-telegram vincular`.

### 3. (Opcional) Permisos de root con botón

```bash
sudo ./instalar-root.sh          # sudo ./instalar-root.sh --quitar para sacarlo
```

Volvé a correrlo si cambiás el token o la cuenta vinculada.

## Prender y apagar

- `claude-telegram on` / `claude-telegram off` (o `systemctl --user enable|disable --now claude-telegram`).
- `claude-telegram estado`.
- Desde Telegram, `/apagar` (para volver a prenderlo hay que hacerlo en la PC).
- Con la barra de iNiR: hay un parche con un botón **Telegram: sí/no** en Acciones rápidas (ver abajo).

Con el bot apagado no queda nada corriendo. Con el bot prendido y sin conversación abierta, solo queda un proceso de Python chico esperando mensajes; Claude Code arranca recién cuando escribís.

## Configuración

`~/.config/claude-telegram/config.json` (permisos 600: tiene el token). Después de cambiarla: `systemctl --user restart claude-telegram`.

| Clave | Por defecto | Qué es |
|---|---|---|
| `token`, `dueno`, `nombre` | — | Los llena el asistente. `dueno` es tu id de Telegram. |
| `carpeta` | `~` | Dónde trabaja Claude. |
| `modelo` | `""` | Modelo de Claude (`""` = el de tu Claude Code). |
| `permisos` | `bypassPermissions` | Acceso completo, sin preguntar (como pide este proyecto). `acceptEdits` o `default` para que Claude no pueda hacer lo que necesitaría permiso. |
| `inactividad_min` / `confirmar_min` | `25` / `3` | Tiempos de la pregunta "¿seguimos?". |
| `recibidos` | `~/Downloads/telegram` | Dónde quedan las fotos y archivos que mandás. |
| `tts_comando` | `[]` | Programa que lee texto por stdin y deja un wav en `{salida}`. |
| `tts_voces`, `tts_elegir` | `[]` | Listar voces (`nombre<TAB>descripción`) y elegir una (`{voz}`). |
| `tts_prender`, `tts_apagar` | `[]` | Se llaman al prender y apagar la voz (para servicios que se cierran solos). |
| `transcribir` | `[]` | Programa que recibe `{entrada}` (audio) e imprime el texto. Viene `transcribir.py` (faster-whisper). |

Ejemplo de voz con [Piper](https://github.com/rhasspy/piper) en vez de Loquendo:

```json
"tts_comando": ["piper", "--model", "/ruta/es_AR-voz.onnx", "--output_file", "{salida}"]
```

## Botón en iNiR

Para la barra de [iNiR](https://github.com/snowarch/iNiR), el botón **Telegram: sí/no** de Acciones rápidas (al lado de los demás) es un `QuickActionButton` que corre `systemctl --user enable|disable --now claude-telegram.service` y cada 2 segundos mira `is-active` para mostrar el estado. Cualquier barra que pueda correr un comando sirve igual: `claude-telegram on|off`.

## Cómo está armado

- `claude-telegram`: el bot y la CLI. Lee Telegram con long polling, y por cada conversación corre `claude -p --input-format stream-json --output-format stream-json` en `carpeta`. Los textos de Claude se pasan de markdown al HTML de Telegram (código, tablas en monoespaciado, links) y se parten en mensajes de hasta 4096 caracteres.
- `bin/tg-sudo` → `sudo -n /usr/local/lib/claude-telegram/tg-root`; `root/tg-root`: el que pide el botón y corre el comando como root.
- `transcribir.py`: notas de voz con faster-whisper (`CLAUDE_TELEGRAM_WHISPER=small` entiende mejor y tarda más).
- Estado (voz prendida, última conversación) en `~/.local/state/claude-telegram/estado.json`.
- Log: `journalctl --user -u claude-telegram` (no guarda lo que hablás).

## Seguridad: leé esto

- Quien tenga tu Telegram abierto tiene tu PC. Poné contraseña/código de bloqueo a Telegram y al celular.
- El token del bot da control del bot: si se filtra, en @BotFather `/revoke` y volvé a correr `claude-telegram configurar` (y `sudo ./instalar-root.sh`).
- Con `permisos: bypassPermissions` Claude no pide confirmación para nada de tu usuario (solo para root). Si no querés eso, cambialo.
- Las conversaciones quedan en el historial de Claude Code (`~/.claude/projects`), igual que en la terminal; `/retomar` las usa.

## Licencia

MIT
