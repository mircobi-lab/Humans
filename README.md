# Humans

Prova di fattibilità di MBStudio91 per voci e cori generati in locale, senza cloud, su un MacBook Pro 15" 2019 (Intel i9, 32 GB, GPU AMD).

L'obiettivo finale è un plugin VST3/AU che faccia in piccolo quello che fanno ACE Studio (voce cantata da MIDI e testo, modalità coro) e Suno (brano intero da descrizione). Prima di scrivere il plugin misuriamo i due motori open source candidati sulla macchina vera.

| Motore | Cosa fa | Licenza |
|---|---|---|
| [acestep.cpp](https://github.com/ServeurpersoCom/acestep.cpp) (ACE-Step 1.5) | brano completo da testo e liriche | MIT |
| [OpenUtau](https://github.com/stakira/OpenUtau) + DiffSinger | voce cantata da note MIDI e sillabe | MIT |

## Come si usa

Ogni push su `main` lancia `.github/workflows/mac-intel.yml`, che compila tutto sul runner Intel di GitHub, fa una prova di generazione sul runner e pubblica i pacchetti nella release **prova-mac-intel**.

Il riepilogo dei tempi misurati sul runner compare nella pagina del run, sezione Summary.

## Note tecniche

- OpenUtau ha tolto il supporto ai Mac Intel il 2 settembre 2026 (commit `e1200ffd`), e ONNX Runtime dalla 1.24 non pubblica più librerie x86_64 per macOS. Qui si compila il commit precedente, `d8ffda8`, con ONNX Runtime 1.23.2.
- acestep.cpp è compilato con `GGML_NATIVE=OFF` e AVX2, così gira anche sul processore del 2019, che non ha AVX-512.
- I runner `macos-15-intel` sono gli ultimi Intel offerti da GitHub, supportati fino ad agosto 2027.
