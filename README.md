# Bela Fumna

**Bela Fumna** is a custom multi-effects stompbox for electric bass, built on the [Bela](https://bela.io) embedded audio platform and programmed in [SuperCollider](https://supercollider.github.io). It is designed as a replacement for a commercial multi-effects unit (Zoom B6), optimised for live performance accompanying silent films with the ensemble [Arto Fantasma](https://artofantasma.it).

The name is a Piedmontese pun: *Bela* (the platform) + *fumna* (Piedmontese dialect for *donna*/woman, but also evoking *fumo*/smoke).

---

## Instrument context

The pedal is played by a bassist performing live accompaniment to silent films. The signal chain is:

```
6-string bass → Bela Fumna → Darkglass / SansAmp Programmable Bass Driver DI → PA
```

Design priorities are stability, instant recall, and a small number of well-chosen effects that work well for bass in an acoustic/cinematic context.

---

## Hardware

### Platform
- **Bela Starter Kit** (BeagleBone Black + Bela cape), powered via USB 5V

### Enclosure
- Diecast aluminium enclosure, 187 × 118 × 38 mm

### Controls
- **SW1–SW5** — 6 illuminated latching 3PDT footswitches (SW6 spare)
- **K1** — Input gain (Alpha 16mm 10kΩ linear pot)
- **K2** — Spare
- **K3** — Output volume (Alpha 16mm 10kΩ linear pot)
- LED current limiting: 100Ω resistors

### Audio I/O
- Input: Lumberg KLB3 6.35mm mono jack
- Output: Lumberg KLB3 6.35mm mono jack
- Audio connectors wired directly to Bela cape (3.5mm adapters removed)

### Power
- USB 5V, 1A minimum (standard micro-USB)
- Panel-mount USB socket on enclosure

### Suppliers
- Bela board: [eu.shop.bela.io](https://eu.shop.bela.io)
- Enclosure, footswitches, knobs, pots: [Musikding.de](https://www.musikding.de)
- Jacks, resistors: [RS Components Italy](https://it.rs-online.com)

---

## Signal architecture

All processing runs in SuperCollider on Bela. There is no hardware true bypass — dry/wet and bypass are handled in software via `XFade2`.

```
                        ┌─────────────────────────────────────┐
                        │            dry input bus             │
                        └──┬──────────┬──────────┬────────────┘
                           │          │          │
                     serial chain   freeze    sampler
                           │          │          │
                    ┌──────┴──────┐   │          │
                    │  oct down   │   │          │
                    │  oct up     │   │          │
                    │  autowah    │   │          │
                    └──────┬──────┘   │          │
                           │          │          │
                        ┌──┴──────────┴──────────┴──┐
                        │           mixer            │
                        └──────────────┬─────────────┘
                                       │
                                   output
```

### Effects

| Effect | SW | Implementation |
|---|---|---|
| Octave down | SW1 | Ring modulation (SinOsc × input at freq×0.5), MoogFF 400Hz, gated by `hasFreq` |
| Octave up | SW2 | `PitchShift.ar` (windowSize 0.2, pitchRatio 2.0) |
| Autowah | SW3 | `Amplitude.ar` → dB → `linexp` → MoogFF (gain 3.0), 200Hz low/high split, 6dB makeup gain |
| Spectral freeze | SW4 | `PV_MagFreeze` + `BufRd` navigated by pitch via `K2A.ar` |
| Sampler | SW5 | `PlayBuf` triggered by `Onsets.kr`, rate controlled by pitch/rootFreq ratio, amplitude-gated |

Pitch tracking throughout uses `Pitch.kr` with `hasFreq` gating, tuned for 6-string bass (low B ≈ 30.9 Hz).

### Bus routing

| Bus | Content |
|---|---|
| `dryBus` | Dry input signal, feeds all parallel paths |
| `chainBus` | Serial chain output (oct down → oct up → autowah) |
| `freezeBus` | Spectral freeze output |
| `samplerBus` | Sampler output |
| `outBus` | Final mix to hardware output |

### Node ordering

All SynthDefs are instantiated with explicit `Synth.head` / `Synth.tail` ordering to ensure correct signal flow. Default `Synth()` (addToHead) is not used.

---

## Software

### Requirements
- [Bela](https://bela.io) with SuperCollider support
- SuperCollider ≥ 3.12 (as shipped with Bela image)

### File structure

```
BelajFumna/
├── _main.scd          # Entry point — runs automatically on Bela
├── synthdefs/
│   ├── input.scd      # Input gain stage
│   ├── octdown.scd    # Oct down SynthDef
│   ├── octup.scd      # Oct up SynthDef
│   ├── autowah.scd    # Autowah SynthDef
│   ├── freeze.scd     # Spectral freeze SynthDef
│   ├── sampler.scd    # Sampler SynthDef
│   └── mixer.scd      # Final mixer SynthDef
└── README.md
```

### Running on Bela

1. Connect Bela to your computer via USB.
2. Open `http://bela.local` in a browser.
3. Create a new SuperCollider project in the IDE.
4. Upload `_main.scd` (and any supporting files).
5. Click **Run**.

To set the project to run automatically on boot (standalone pedal mode):

```
IDE → Settings → Run project on boot → select BelajFumna
```

Or via SSH:
```bash
ssh root@bela.local
make -C /root/Bela PROJECT=BelajFumna startup
```

### Development / laptop testing

The codebase includes a GUI fallback for laptop development (without Bela hardware). GUI controls replace `AnalogIn.ar` / `DigitalIn.ar` calls and are deferred via `.defer`. To run in laptop mode, use the standard SC IDE on any desktop system — the GUI will launch automatically when Bela hardware is not detected.

---

## Design notes

- **Amplitude scaling** is done in dB space throughout, not linear — this gives more musical response for envelope-controlled effects.
- **`Normalizer.ar`** was tested and rejected for the autowah makeup gain — it acts as a sustainer rather than a level corrector.
- **`s.sync`** requires a `Routine` context; all server-synchronous code is wrapped accordingly.
- **GUI calls** from non-AppClock threads use `.defer`.
- **Octave down** uses a ring modulation approach (SinOsc at freq×0.5 × input signal) rather than a zero-crossing divider, which produced distortion artefacts on complex bass signals.
- **Octave up** uses `PitchShift.ar` rather than `sig*sig` (frequency doubling via squaring has no audible effect on complex signals).
- **Output LPF** (390Ω + 22nF) is fitted on the headphone output to prevent sigma-delta converter out-of-band noise from aliasing through the nonlinear downstream stages (Darkglass / SansAmp).

---

## Related resources

- Bela platform: https://bela.io
- SuperCollider on Bela: https://github.com/supercollider/supercollider/blob/develop/README_BELA.md
- Bela forum — embedding Bela in a guitar pedal: https://forum.bela.io/d/111-embed-bela-in-a-guitar-pedal
- Bela hardware reference: https://learn.bela.io/using-bela/about-bela/bela-hardware/

---

## Author

Andrea Valle  
Composer, bassist, researcher — Turin, Italy  
Ensemble Arto Fantasma

---

## Licence

MIT
