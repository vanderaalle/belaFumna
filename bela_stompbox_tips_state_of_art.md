# Building a Bela Stompbox: State of the Art — Tips, Tricks, and Resources

Compiled for the Bela Fumna project — Andrea Valle, 2025/26.  
Sources: Bela official documentation, Bela forum, community builds, DIY pedal community.

---

## 0. Framing: What Makes a Bela Stompbox Different

A Bela-based stompbox is architecturally unlike a conventional DSP pedal. The Bela board (BeagleBone Black + cape) is a Linux SBC running Xenomai real-time kernel extensions, not a microcontroller. This has consequences throughout the build:

- **No true bypass hardware switch** is typically used. Signal routing is done in software (e.g. `XFade2` in SuperCollider), so the DSP always runs. Audio I/O is mediated by the on-board TLV320AIC3104 codec (Bela) or equivalent.
- **Boot time** is 20–30 seconds; not instant like analog pedals or microcontroller-based builds.
- **Control I/O** is on 3.3V GPIO (digital) and 0–4.096V ADC (analog), not 5V or 9V — critical for wiring choices.
- **USB 5V power** is sufficient for the board, but noise isolation from the USB supply requires attention.

Foundational hardware reference: Bela hardware page — https://learn.bela.io/using-bela/about-bela/bela-hardware/

---

## 1. Enclosure

### 1.1 Board dimensions and minimum enclosure

The Bela (BeagleBone Black + cape) is approximately **90mm × 55mm × 30mm** (height varies with connectors; the mini-USB port protrudes). The Bela Mini (PocketBeagle + cape) is smaller: approx. 56mm × 35mm.

Key constraint from Dan Stowell (Bela Forum thread #111): the 3.5mm audio connectors on the cape stand too tall inside a typical "1590B"-size enclosure once cables are attached. He discovered his chosen Hammond octagonal box was not quite large enough once the audio I/O cables were plugged in.

→ Forum thread: https://forum.bela.io/d/111-embed-bela-in-a-guitar-pedal

**Minimum recommended enclosure depths:**
- Bela (full): at least **40mm internal depth** to clear the USB connector and cape stack with cables.
- Bela Mini: more compact; **35mm** may suffice with careful cable routing.
- A "pi-Stomp" SBC-in-a-pedal builder confirmed that 1.66" (42mm) is the minimum height for a diecast enclosure with a Raspberry Pi; same principle applies to Bela.

→ Enclosure considerations: https://www.treefallsound.com/wiki/doku.php?id=enclosure_considerations

### 1.2 Hammond 1590-series reference sizes (standard pedal community)

The Hammond 1590 diecast aluminium series is the universal stompbox enclosure standard. Interior dimensions (approximate, excluding lid):

| Model       | L × W × H (mm)         | Notes                                        |
|-------------|------------------------|----------------------------------------------|
| 1590A       | 93 × 38 × 31          | Too small for Bela                           |
| 1590B       | 111 × 59 × 31         | Too small for Bela                           |
| 1590BB      | 119 × 94 × 34         | Borderline; Bela Mini may fit                |
| 1590BB2     | 119 × 94 × 42         | Taller version; workable for Bela Mini       |
| 1590N1/125B | 120 × 65 × 39         | Narrow; unlikely to fit Bela sideways        |
| 1590C       | 119 × 94 × 57         | Good depth for full Bela                     |
| 1590DD      | 188 × 120 × 37        | Multi-effect; used for Bela Fumna-type builds|
| 1590XX      | 145 × 121 × 39        | Large; generous room                         |

For the Bela Fumna project (187×118×38mm enclosure, 6 footswitches), the approximate equivalent is the 1590DD.

→ Hammond official dimension table: https://www.hammfg.com/electronics/small-case/diecast/1590  
→ Hammond enclosure finder tool: https://stompboxelectronics.com/resources/hammond-enclosure-finder-for-diy-guitar-pedals/

### 1.3 Audio connector strategy

The official Bela recommendation for mounting in a guitar pedal (Hammond-style case) is to **remove the existing 3.5mm connector from the cape and solder wires directly to the panel-mount 1/4" (6.35mm) jacks.** This eliminates the cable-height problem and is the cleanest wiring approach.

→ Source: https://learn.bela.io/using-bela/about-bela/bela-hardware/

### 1.4 Drilling and mechanical

Standard DIY pedal community practice:
- Use a **step drill bit** for larger holes (jacks, pots, footswitches).
- Use a **centre punch** before drilling to prevent bit wander.
- For LED holes: typically 5mm.
- For 3PDT footswitches: typically 11–12mm.
- For Alpha 16mm pots: 7mm shaft hole.
- For 6.35mm jack sockets (Lumberg KLB3 style): 11–12mm.
- For DC barrel jack (5.5mm × 2.1mm): 12mm.
- Use a **hand file** to deburr after drilling.

→ Detailed drilling guidance: https://www.premierguitar.com/diy/pedal-projects/diy-guitar-pedals

---

## 2. Power

### 2.1 Voltage and connector spec

Bela requires **5V DC, centre-positive**, via:
- Mini/Micro USB B port (standard phone charger spec).
- Barrel jack: **5.5mm OD × 2.1mm ID, centre positive**.

**NEVER exceed 5V.** Connecting the wrong polarity or voltage to the barrel connector may destroy the BeagleBone Black and Bela cape.

→ Source: https://learn.bela.io/using-bela/bela-techniques/powering-bela/

### 2.2 DC barrel jack isolation

The DC barrel jack in a metal enclosure must have a **plastic surround** (insulated from the enclosure) if the outer barrel is connected to the circuit positive — or alternatively, use a fully plastic-bodied jack. A metal-surrounded jack will short the outer barrel to enclosure ground.

→ Standard DIY pedal wiring principle: https://diystrat.blogspot.com/2009/06/how-to-wire-up-stomp-box-effects-pedal.html

### 2.3 Current budget

The Bela cape itself (audio codec, speaker amp) draws additional current beyond the BeagleBone base draw (~500mA). A **1A minimum** USB supply is recommended for stable standalone operation. For LiPo battery builds, use a **5V boost converter** (e.g., SparkFun 5V/1A LiPo charger/booster); powering Bela from less than 5V will cause analog I/O to misbehave.

### 2.4 Power supply noise

The **3.3V rail has significantly better noise performance than the 5V rail.** If using any on-board supply as a reference in analog circuits (e.g., as reference for pots), use 3.3V (P9.03/04 on Bela), not 5V.

→ Source: https://learn.bela.io/using-bela/about-bela/bela-hardware/

---

## 3. Audio Signal Path

### 3.1 Input impedance

The TLV320AIC3104 codec input impedance is approximately **80kΩ**. For direct guitar/bass connection, this is marginally low — guitar pickups ideally see >500kΩ, preferably 1MΩ.

**Practical consequence:** the resonant peak of the pickup (typically 2–5kHz) will flatten and the guitar will sound duller than through a proper hi-Z input. String sustain may also be reduced due to mechanical loading.

**Solutions:**
1. Place a non-true-bypass pedal (with its own buffer) before the Bela — the buffer provides the required hi-Z to the pickup.
2. Build a **simple JFET input buffer** (search "simple JFET guitar buffer").

Note: the Bela team acknowledge this works "alright" for most practical purposes, especially if any buffered pedal precedes it.

→ Detailed discussion (ryjobil): Bela Forum thread #111, page 2  
→ Pickup loading technical deep-dive: http://buildyourguitar.com/resources/lemme/

### 3.2 Input gain

The TLV320AIC3104 codec provides up to **59.5dB of gain** at the audio input, configurable via the IDE Settings tab. This means you can comfortably connect guitar, dynamic microphone, piezo pickup, etc. directly.

Analog input range: **0 to 4.096V** (5V tolerant). Audio maps to **−1 to 1** in software.

### 3.3 Output low-pass filter (important for guitar applications)

When Bela is used as a guitar/bass effect going into a **non-linear next stage** (distortion, DI, amp), the sigma-delta converter's out-of-band noise can be aliased back into the audio range by the nonlinearity of the following stage. Bela recommends adding an **RC low-pass filter** on the audio output:

- **Headphone output:** R = 390Ω, C = 22nF
- **Line out (J9):** R = 4.7kΩ, C = 2.2nF

Place R in series, C to ground on each channel.

→ Source: https://learn.bela.io/using-bela/about-bela/bela-hardware/

### 3.4 Audio connector pinout

The Bela audio connectors are **3-way Molex-style crimp housings, 2.54mm pitch**. Speaker outputs use **2-way Molex** crimp housings. Compatible with female dupont/jumper cables for prototyping.

For panel-mount audio: solder wires directly from the cape pins to 6.35mm jack sockets mounted in the enclosure. The left channel pin is the central pin of the IN connector; the right channel is the pin closest to the OUT connector.

---

## 4. Controls: Potentiometers

### 4.1 Wiring

Bela analog inputs range **0 to 4.096V**. Connect pots as a voltage divider:

- Pin 1 (CCW lug) → **GND**
- Pin 2 (wiper) → **Analog Input 0–7**
- Pin 3 (CW lug) → **3.3V** (recommended) or ADC_REF

Pot value: **10kΩ linear** is standard.

The Bela IDE ADC reference is nominally **4.096V**, but pot output tops at 3.3V if 3.3V is used as the supply rail — so the wiper will read in range **0.0 to ~0.805** (not 0.0 to 1.0). Compensate in software.

### 4.2 ADC reference pin

Bela exposes an **AREF/Vref** pin — this is a high-impedance, low-noise internal reference used by the ADC. If using it as a voltage reference in the circuit, a **high-impedance buffer** must be used; do not draw current from it directly.

From the Red Tin build: "I wired a 470Ω resistor between 5V and the analogue ref pin to make up the extra current drawn by the 10k pots."

→ Source: Red Tin build — https://www.rs-online.com/designspark/advanced-audio-effects-with-a-beaglebone-black-and-bela-part-2-building-a-multi-effects-module-for-the-red-tin  
→ Bela learn: https://learn.bela.io/tutorials/pure-data/connecting/analog-input/

### 4.3 Multiplexer capelet for >8 pots

Bela has 8 analog inputs. If more than 8 controls are needed, the **Bela Multiplexer Capelet** extends to up to 64 analog inputs, at a reduced sampling rate.

→ Giulio Moro (Bela forum #111): "the multiplexer capelet will handle up to 64 analog inputs at a lower sampling rate"

---

## 5. Controls: Footswitches and Digital Inputs

### 5.1 Voltage levels — critical

Bela digital GPIO pins are **BeagleBone Black AM3358 pins directly exposed**:

- Input/output level: **0 / 3.3V**
- **NEVER exceed 3.3V** on these pins — exceeding this voltage will destroy the CPU.

→ Source: https://code.soundsoftware.ac.uk/projects/beaglert/wiki/_Wiring_instructions

### 5.2 Wiring a footswitch (momentary push-to-make)

For a **momentary** footswitch (push-to-make, normally open) connected to a digital input:

```
Digital Input pin ──┬── Switch ── 3.3V
                    │
                   10kΩ (pull-down)
                    │
                   GND
```

When the switch is open: pin reads LOW (0).  
When the switch is pressed: pin reads HIGH (3.3V).

**Use a 3.3kΩ or 10kΩ pull-down resistor** (not 5V pull-up). The Red Tin build used 3.3kΩ pull-down with 3.3V switching.

Alternatively, use the internal pull-up (3.3V) and wire the switch to GND — invert logic in software.

### 5.3 Latching vs. momentary footswitches

For a Bela pedal, **momentary switches are preferred** for the footswitch inputs, with latching behaviour implemented in software (toggle a boolean in the DSP code). This is cleaner, more flexible, and allows the software to define what "latch" means (e.g., hold for momentary, tap for toggle).

Latching 3PDT hardware switches are still perfectly usable — the physical state change on press is still readable as a toggle edge — but they limit flexibility and some latch-spring mechanisms fail over time.

**Debouncing:** hardware switch bounce (rapid oscillation on make/break) should be handled in software. In SuperCollider on Bela, `DigitalIn.ar` can be followed by a short `LagUD` or threshold comparison. In C++, a typical approach is to require a stable reading for ~5ms before accepting a state change.

### 5.4 Latching 3PDT in software-bypass configuration

In the Bela Fumna design (and all software-bypass configurations), the 3PDT switch's **third pole** (normally used for LED and signal bypass in hardware true-bypass) is freed up and only one pole is connected to a Bela digital input. The LED is driven from a Bela digital output or, if passive, through a GPIO pin via a current-limiting resistor.

**LED current limiting:** 100Ω series resistor for standard 3mm/5mm LED driven from 3.3V GPIO.

→ Standard 3PDT true-bypass wiring reference: https://diystrat.blogspot.com/2009/06/how-to-wire-up-stomp-box-effects-pedal.html

---

## 6. LEDs

### 6.1 From GPIO

Bela digital outputs are **3.3V**, able to source a small amount of current. For a standard LED:
- Series resistor: **100Ω** gives adequate brightness from 3.3V (~15–20mA depending on forward voltage).
- Use **3mm or 5mm LEDs** — illuminated latching switches often include their own LED with integrated resistor; check the LED spec.

### 6.2 Illuminated footswitches

Illuminated 3PDT latching switches (as used in Bela Fumna) typically contain an LED and resistor internally. Check whether the built-in resistor is calibrated for 9V (common) or 5V; if for 9V, add an external resistor in series when driving from 3.3V GPIO.

---

## 7. Grounding

### 7.1 Star ground principle

In a metal enclosure, all grounds should connect to a **single star point** — not daisy-chained in a loop (which would create a ground loop, acting as an antenna). The back of a pot bolted to a metal enclosure is a common star point, as it automatically grounds the enclosure via the pot body.

### 7.2 Ground the enclosure

The metal enclosure should be connected to signal ground. This provides EMI/RFI shielding. If using plastic jacks or insulated pot bushings, add a dedicated ground wire to the enclosure.

### 7.3 Signal ground vs. chassis ground

In a signal chain context: the signal ground (sleeve of the 6.35mm jack) is typically connected to chassis ground. Keeping these unified avoids hum from floating chassis.

→ Standard practice: https://markweinguitarlessons.com/forums/threads/guitar-pedal-stomp-box-wiring-explained.15286/

---

## 8. Software/Firmware

### 8.1 Auto-run on boot

To make the pedal work standalone (without laptop), set the project to auto-run on boot in the Bela IDE:

**IDE method:** Settings tab → "Run project on boot" → select your project name (must be saved first).

**Terminal method:**
```bash
make -C Bela PROJECT=myproject run
```
Enable startup:
```bash
make -C Bela PROJECT=myproject nostartup  # disable
make -C Bela PROJECT=myproject startup    # enable
```

→ Source: https://github.com/BelaPlatform/Bela/wiki/Running-Bela-projects-automatically-on-boot

### 8.2 Boot time

Bela takes approximately **20–30 seconds** to boot to a running project. Plan for this in the performance context — power the pedal well before needing it.

### 8.3 Graceful shutdown — external power button

The Bela cape button is tied to **P9 pin 27**. An external power-off button can be added to the enclosure by wiring a momentary push-button between P9.27 and GND:
- **Short press (~1s):** stops the currently running program.
- **Hold press (~2s):** initiates graceful shutdown.

⚠️ The neighbouring pins are sensitive codec signals — be careful not to short adjacent pins.

→ Source: https://learn.bela.io/using-bela/bela-techniques/shutting-down-bela/  
→ GitHub wiki: https://github.com/BelaPlatform/Bela/wiki/Powering-off-the-board

### 8.4 Recovering from boot loop

If a CPU-intensive project is set to run on boot and the board becomes unresponsive:
- **SSH in:** `ssh root@192.168.7.2` then `make -C Bela stop nostartup`
- **Cape button:** press rapidly and repeatedly — if fast enough, systemd detects the service crashing too quickly and temporarily disables it (only works on Bela images ≥ v0.3).

→ Source: https://github.com/BelaPlatform/Bela/wiki/Recover-from-stuck-in-reboot-loop

### 8.5 SuperCollider on Bela

SuperCollider support is maintained in the SC source repository. Key reference:
- SC build instructions for Bela: https://github.com/supercollider/supercollider/blob/develop/README_BELA.md
- Bela blog tutorial (SuperCollider + live coding with sensors): https://blog.bela.io/live-coding-sensors-with-supercollider/
- Original Bela+SC thread (Dan Stowell): https://forum.bela.io/d/53-supercollider-on-bela

In SuperCollider on Bela, `AnalogIn.ar(channel)` and `DigitalIn.ar(pin)` replace GUI sliders. Analog values arrive as audio-rate signals (0.0–1.0 range, mapped from 0–3.3V if pots are wired to 3.3V).

---

## 9. Known Issues and Gotchas (Community-Sourced)

| Issue | Description | Source |
|---|---|---|
| **Audio connector height** | The 3.5mm connectors on the cape stand too tall inside typical enclosures; cables may not fit. Remove 3.5mm connectors and wire directly to panel-mount 1/4" jacks. | Dan Stowell, forum #111; official Bela hardware page |
| **Input impedance** | ~80kΩ input Z is too low for direct guitar pickup connection without a buffer stage | ryjobil, forum #111 |
| **Output aliasing noise** | Sigma-delta converter out-of-band noise aliases via nonlinear stages downstream; use RC output LPF | Official Bela hardware page |
| **Digital pin voltage** | NEVER exceed 3.3V on GPIO digital pins — destroys the AM3358 CPU | BeagleRT wiring instructions; forum |
| **USB boot time** | 20–30s boot time; plan performance workflow accordingly | Community knowledge |
| **Boot loop** | A crashing auto-run project can lock the board; SSH or rapid button press to recover | Bela troubleshooting guide |
| **Pot ADC range** | Pots wired to 3.3V will only span 0.0–0.805 of the 4.096V ADC range; compensate in software | Bela learn docs |
| **Ground loop** | Daisy-chaining all grounds creates an antenna loop; use star ground | Standard DIY pedal practice |
| **3.3V supply noise** | 3.3V rail is cleaner than 5V for analog reference circuits | Official Bela hardware page |
| **P9.27 neighbours** | The shutdown pin neighbours are codec signals; careful not to short adjacent pins | Bela shutdown docs |

---

## 10. Reference Builds (with Wiring Notes)

### 10.1 Dan Stowell's pedal (2016)
- Board: Bela (full), Hammond diecast enclosure (octagonal).
- Software: SuperCollider. No DSP code released publicly; driver is the standard Bela SC driver.
- Key finding: enclosure was too small once audio I/O cables attached.
- → https://forum.bela.io/d/111-embed-bela-in-a-guitar-pedal

### 10.2 transmogrifox / transmogriFX_bela (2017–)
- Board: Bela (full), BeagleBone Black.
- Software: C++.
- Controls: 6 × 10kΩ analog pots on ADC 0–5, 3 × momentary push-buttons on digital inputs.
- Wiring: pots between ADC_REF and GND, wipers to analog in. 470Ω between 5V and ADC_REF to supply extra current for 6 pots. Buttons to 3.3V with 3.3kΩ pull-down.
- → https://github.com/transmogrifox/transmogriFX_bela

### 10.3 Red Tin multi-effects (RS DesignSpark, ~2019)
- Board: BeagleBone Black + Bela cape.
- Software: C++ (transmogriFX codebase, adapted).
- Controls: 6 × 10kΩ pots, 3 × momentary buttons.
- Wiring: pots between ADC_REF and GND. 470Ω between 5V and ADC_REF. Right-angle pin headers to save space.
- Enclosure: custom MDF/acrylic prototype; diecast final.
- → https://www.rs-online.com/designspark/advanced-audio-effects-with-a-beaglebone-black-and-bela-part-2-building-a-multi-effects-module-for-the-red-tin

### 10.4 Lehel Török effect cape (2023)
- Board: Bela Mini + custom KiCad PCB cape (manufactured by Eurocircuits).
- Software: Pure Data.
- Controls: 4 × rotary encoders with push switches, 2 × footswitches, OLED screen, bicolor LED.
- Audio: 6.35mm jack in, dual 6.35mm out, 3.5mm headphone, expression pedal in, DC barrel jack (5V, 2.1mm).
- → https://blog.bela.io/effects-pedal-lehel-torok/ / https://www.hackster.io/leheltorok96/effect-cape-for-bela-mini-7582df

### 10.5 Mike Parr Burman pedal (2017, v2 ~2021)
- Board: Bela Mini (v2); full Bela (v1).
- Software: C++.
- Custom PCB for control I/O.
- Key change v1→v2: replaced hand-wiring with PCB, switched from full Bela to Bela Mini for space.
- → https://empeeby.com/projects/belapedal/

---

## 11. Sources Index

| Source | URL |
|---|---|
| Bela hardware page (official) | https://learn.bela.io/using-bela/about-bela/bela-hardware/ |
| Bela GitHub hardware wiki | https://github.com/BelaPlatform/Bela/wiki/Hardware-explained |
| Bela wiring instructions (BeagleRT) | https://code.soundsoftware.ac.uk/projects/beaglert/wiki/_Wiring_instructions |
| Bela analog input tutorial | https://learn.bela.io/tutorials/pure-data/connecting/analog-input/ |
| Bela powering guide | https://learn.bela.io/using-bela/bela-techniques/powering-bela/ |
| Bela shutdown guide | https://learn.bela.io/using-bela/bela-techniques/shutting-down-bela/ |
| Bela button wiki | https://github.com/BelaPlatform/Bela/wiki/The-Bela-Button |
| Bela autorun wiki | https://github.com/BelaPlatform/Bela/wiki/Running-Bela-projects-automatically-on-boot |
| Bela boot loop recovery | https://github.com/BelaPlatform/Bela/wiki/Recover-from-stuck-in-reboot-loop |
| Bela troubleshooting guide | https://learn.bela.io/using-bela/about-bela/troubleshooting-guide/ |
| Bela forum — embed in guitar pedal | https://forum.bela.io/d/111-embed-bela-in-a-guitar-pedal |
| Bela SuperCollider forum thread | https://forum.bela.io/d/53-supercollider-on-bela |
| SC README_BELA | https://github.com/supercollider/supercollider/blob/develop/README_BELA.md |
| Bela+SC blog tutorial | https://blog.bela.io/live-coding-sensors-with-supercollider/ |
| transmogrifox codebase | https://github.com/transmogrifox/transmogriFX_bela |
| Red Tin build (RS DesignSpark) | https://www.rs-online.com/designspark/advanced-audio-effects-with-a-beaglebone-black-and-bela-part-2-building-a-multi-effects-module-for-the-red-tin |
| Lehel Török effect cape (Bela Blog) | https://blog.bela.io/effects-pedal-lehel-torok/ |
| Lehel Török (Hackster) | https://www.hackster.io/leheltorok96/effect-cape-for-bela-mini-7582df |
| Mike Parr Burman pedal | https://empeeby.com/projects/belapedal/ |
| Guitar pickup impedance / loading | http://buildyourguitar.com/resources/lemme/ |
| Hammond 1590 diecast series | https://www.hammfg.com/electronics/small-case/diecast/1590 |
| Hammond enclosure finder | https://stompboxelectronics.com/resources/hammond-enclosure-finder-for-diy-guitar-pedals/ |
| Standard stompbox wiring (DIYStrat) | https://diystrat.blogspot.com/2009/06/how-to-wire-up-stomp-box-effects-pedal.html |
| Stompbox wiring (Premier Guitar) | https://www.premierguitar.com/diy/pedal-projects/diy-guitar-pedals |
| Star ground / grounding explained | https://markweinguitarlessons.com/forums/threads/guitar-pedal-stomp-box-wiring-explained.15286/ |
| Enclosure size considerations (pi-Stomp) | https://www.treefallsound.com/wiki/doku.php?id=enclosure_considerations |
