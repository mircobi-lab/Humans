#!/bin/bash
# Humans - prova ACE-Step su Mac Intel.
# Aprilo con clic destro > Apri (la prima volta macOS chiede conferma).
# Fa tutto da solo: sblocca i programmi, controlla il Mac, scarica i modelli,
# genera un brano di prova e scrive risultati/rapporto.txt da mandare a Claude.
cd "$(dirname "$0")" || exit 1
DIR="$PWD"
mkdir -p risultati models
R="$DIR/risultati/rapporto.txt"
: > "$R"
log() { echo "$*" | tee -a "$R"; }
fine() {
  log ""; log "Rapporto salvato in: $R"
  open "$DIR/risultati" 2>/dev/null
  echo; read -r -p "Premi Invio per chiudere questa finestra..." _
  exit "${1:-0}"
}

log "=== Humans - prova ACE-Step - $(date '+%d/%m/%Y %H:%M') ==="

# 1. Sblocco: toglie la "quarantena" che macOS mette sui file scaricati
xattr -dr com.apple.quarantine "$DIR" 2>/dev/null
chmod +x "$DIR"/bin/* "$DIR"/*.command 2>/dev/null

# 2. Controllo del Mac
OSV=$(sw_vers -productVersion)
CPU=$(sysctl -n machdep.cpu.brand_string)
CORES=$(sysctl -n hw.physicalcpu)
RAM=$(( $(sysctl -n hw.memsize) / 1073741824 ))
AVX2=no; sysctl -n machdep.cpu.leaf7_features 2>/dev/null | grep -qw AVX2 && AVX2=si
DISK=$(df -g "$DIR" | awk 'NR==2{print $4}')
ARCH=$(uname -m)
log "macOS $OSV | $CPU | $CORES core | RAM $RAM GB | AVX2: $AVX2 | disco libero: $DISK GB | $ARCH"
system_profiler SPDisplaysDataType 2>/dev/null | grep -E 'Chipset Model|Metal' | sed 's/^ */GPU: /' | tee -a "$R"

problema=0
case "$OSV" in 10.*|11.*) log "PROBLEMA: serve macOS 12 Monterey o successivo."; problema=1;; esac
[ "$ARCH" != x86_64 ] && log "NOTA: questo pacchetto e' per Mac Intel, qui gira tramite Rosetta."
[ "$AVX2" = no ] && { log "PROBLEMA: il processore non ha AVX2, i programmi non possono girare."; problema=1; }
[ "${DISK:-0}" -lt 6 ] && { log "PROBLEMA: servono almeno 6 GB liberi sul disco."; problema=1; }
[ $problema = 1 ] && fine 1

# Prova di avvio dei programmi (cattura errori di sistema come librerie o versione macOS)
for b in ace-lm ace-synth; do
  out=$("$DIR/bin/$b" </dev/null 2>&1 | head -3)
  if echo "$out" | grep -qiE 'dyld|killed|illegal|bad CPU|cannot execute|not permitted'; then
    log "PROBLEMA avviando $b:"; log "$out"; fine 1
  fi
done
log "Programmi: si avviano correttamente."

# 3. Profilo: leggero sui Mac con pochi core o poca RAM
if [ "$CORES" -le 4 ] || [ "$RAM" -lt 24 ]; then
  PROFILO=leggero; LM=acestep-5Hz-lm-0.6B-Q8_0.gguf; DIT=acestep-v15-turbo-Q4_K_M.gguf; DUR=30
else
  PROFILO=completo; LM=acestep-5Hz-lm-1.7B-Q8_0.gguf; DIT=acestep-v15-turbo-Q8_0.gguf; DUR=60
fi
log "Profilo: $PROFILO (modelli $LM + $DIT, brano di $DUR secondi)"

# 4. Modelli
BASE="https://huggingface.co/Serveurperso/ACE-Step-1.5-GGUF/resolve/main"
for f in vae-BF16.gguf Qwen3-Embedding-0.6B-Q8_0.gguf "$LM" "$DIT"; do
  if [ -s "models/$f" ]; then log "[ok] $f"; continue; fi
  echo "[scarico] $f"
  ok=0; rc=0
  for tentativo in 1 2 3 4 5; do
    curl -fL --retry 3 --retry-all-errors --retry-delay 5 -C - -o "models/$f.part" "$BASE/$f"; rc=$?
    [ $rc = 0 ] && { ok=1; break; }
    echo "tentativo $tentativo non riuscito (codice $rc), riprovo tra 10 secondi..."; sleep 10
  done
  if [ $ok = 1 ]; then
    mv "models/$f.part" "models/$f"; log "[scaricato] $f"
  else
    log "PROBLEMA: download di $f non riuscito dopo 5 tentativi. Rilancia lo script: riprende da dove si era fermato."
    log "Codice curl: $rc (6 = nome sito non trovato, 7 = connessione rifiutata, 22 = errore del sito, 28 = tempo scaduto, 56 = connessione interrotta)"; fine 1
  fi
done

# 5. Brano di prova
cd "$DIR/risultati"
sed -e "s/__LM__/$LM/" -e "s/__DIT__/$DIT/" -e "s/__DUR__/$DUR/" "$DIR/canzone-prova.json" > canzone.json
log ""; log ">>> Creo struttura e melodia (LM, CPU)..."
s=$(date +%s)
if ! "$DIR/bin/ace-lm" --models "$DIR/models" --request canzone.json --device CPU > lm.log 2>&1; then
  log "PROBLEMA nella fase LM. Ultime righe:"; tail -n 15 lm.log | tee -a "$R"; fine 1
fi
log "LM: $(( $(date +%s)-s )) secondi"

DEVS="CPU"; [ "$PROFILO" = completo ] && DEVS="MTL0 CPU"
fatto=0
for dev in $DEVS; do
  log ">>> Genero l'audio con $dev..."
  cp canzone0.json "canzone-$dev.json"
  s=$(date +%s)
  if "$DIR/bin/ace-synth" --models "$DIR/models" --request "canzone-$dev.json" --device "$dev" > "synth-$dev.log" 2>&1; then
    log "Audio $dev: $(( $(date +%s)-s )) secondi -> risultati/canzone-${dev}0.mp3"
    grep -E 'DiT-Generate\] Total|VAE-Decode' "synth-$dev.log" | sed 's/^/   /' | tee -a "$R"
    fatto=1
  else
    log "Audio con $dev non riuscito. Ultime righe:"; tail -n 6 "synth-$dev.log" | tee -a "$R"
  fi
done
[ $fatto = 1 ] && log "" && log "FATTO. Ascolta il brano nella cartella risultati."
fine 0
