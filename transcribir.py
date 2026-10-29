"""Nota de voz -> texto con faster-whisper (CPU, int8). Uso: python transcribir.py AUDIO
Modelo con CLAUDE_TELEGRAM_WHISPER (por defecto "base"; "small" entiende mejor pero tarda ~4 veces más)."""
import os
import subprocess
import sys

import numpy as np
from faster_whisper import WhisperModel

# ffmpeg decodifica (el .oga de Telegram es opus): 16 kHz mono, como lo quiere whisper
crudo = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", sys.argv[1], "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                       capture_output=True, check=True).stdout
audio = np.frombuffer(crudo, np.int16).astype(np.float32) / 32768
modelo = WhisperModel(os.environ.get("CLAUDE_TELEGRAM_WHISPER", "base"), device="cpu", compute_type="int8",
                      cpu_threads=2)
partes, _ = modelo.transcribe(audio, language=os.environ.get("CLAUDE_TELEGRAM_IDIOMA", "es"), vad_filter=True)
print(" ".join(p.text.strip() for p in partes))
