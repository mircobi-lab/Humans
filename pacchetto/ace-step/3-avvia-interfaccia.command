#!/bin/bash
# Interfaccia web di ACE-Step: si apre nel browser su http://localhost:8085
# Prima lancia AVVIA-QUI.command (scarica i modelli). Per chiudere: Ctrl+C.
cd "$(dirname "$0")" || exit 1
xattr -dr com.apple.quarantine "$PWD" 2>/dev/null
chmod +x bin/* 2>/dev/null
( sleep 3; open http://localhost:8085 ) &
./bin/ace-server --host 127.0.0.1 --port 8085 --models ./models
