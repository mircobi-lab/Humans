#!/bin/bash
# Avvia ace-server con l'interfaccia web: apri http://localhost:8085 nel browser.
# Per chiudere: Ctrl+C in questa finestra.
cd "$(dirname "$0")"
( sleep 3; open http://localhost:8085 ) &
./bin/ace-server --host 127.0.0.1 --port 8085 --models ./models
