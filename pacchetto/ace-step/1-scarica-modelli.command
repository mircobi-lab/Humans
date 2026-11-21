#!/bin/bash
# Scarica i modelli ACE-Step 1.5 (GGUF) nella cartella models/ (circa 5 GB).
# I file gia' presenti non vengono riscaricati.
set -eu
cd "$(dirname "$0")"
BASE="https://huggingface.co/Serveurperso/ACE-Step-1.5-GGUF/resolve/main"
mkdir -p models
for f in vae-BF16.gguf \
         Qwen3-Embedding-0.6B-Q8_0.gguf \
         acestep-5Hz-lm-1.7B-Q8_0.gguf \
         acestep-v15-turbo-Q8_0.gguf; do
  if [ -s "models/$f" ]; then
    echo "[ok] $f"
  else
    echo "[scarico] $f"
    curl -fL --retry 3 -C - -o "models/$f.part" "$BASE/$f" && mv "models/$f.part" "models/$f"
  fi
done
echo
echo "Modelli pronti. Ora lancia 2-prova-velocita.command"
