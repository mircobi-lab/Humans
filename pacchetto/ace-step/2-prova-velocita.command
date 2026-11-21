#!/bin/bash
# Genera lo stesso brano di 60 secondi due volte: con la GPU (Metal) e con la sola CPU.
# Scrive tempi e file audio in risultati/. Mandami il file risultati/riepilogo.txt.
set -u
cd "$(dirname "$0")"
mkdir -p risultati
R=risultati/riepilogo.txt
{
  echo "Humans - prova ACE-Step su questo Mac - $(date)"
  sysctl -n machdep.cpu.brand_string
  echo "RAM: $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
  sw_vers | tr '\n' ' '; echo
  system_profiler SPDisplaysDataType | grep -E 'Chipset|VRAM|Metal' || true
  echo
} > "$R"

cp canzone-prova.json risultati/canzone.json
cd risultati

echo ">>> 1/3 LM: struttura e codici audio (CPU)"
s=$(date +%s)
../bin/ace-lm --models ../models --request canzone.json --device CPU 2>&1 | tee lm.log
e=$(date +%s); echo "LM (CPU): $((e-s)) s" >> riepilogo.txt

for dev in MTL0 CPU; do
  echo ">>> Sintesi audio con $dev"
  cp canzone0.json "canzone-$dev.json"
  s=$(date +%s)
  if ../bin/ace-synth --models ../models --request "canzone-$dev.json" --device "$dev" 2>&1 | tee "synth-$dev.log"; then
    e=$(date +%s); echo "Sintesi $dev: $((e-s)) s" >> riepilogo.txt
  else
    echo "Sintesi $dev: ERRORE (vedi synth-$dev.log)" >> riepilogo.txt
  fi
  grep -E 'backend:|DiT-Generate\] Total|VAE-Decode' "synth-$dev.log" | sed "s/^/  [$dev] /" >> riepilogo.txt
done

echo
echo "================ RIEPILOGO ================"
cat riepilogo.txt
echo "Ascolta: risultati/canzone-MTL00.mp3 e risultati/canzone-CPU0.mp3"
