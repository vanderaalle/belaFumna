# Bibliography: Bela-Based Effects Pedals and Related Resources

Compiled for the Bela Fumna project — Andrea Valle, 2025/26.

---

## 1. Bela Platform — Foundational Academic Papers

These are the canonical papers to cite when referencing the Bela platform itself.

**McPherson, Andrew P., and Victor Zappi.**
"An Environment for Submillisecond-Latency Audio and Sensor Processing on BeagleBone Black."
*Audio Engineering Society Convention*, Amsterdam, 2015.
→ https://www.eecs.qmul.ac.uk/~andrewm/mcpherson_aes2015.pdf
*(The original BeagleRT / pre-Bela paper.)*

**McPherson, Andrew P., Robert H. Jack, and Giulio Moro.**
"Action-Sound Latency: Are Our Tools Fast Enough?"
*Proceedings of the International Conference on New Interfaces for Musical Expression (NIME)*, Brisbane, 2016, pp. 20–25.
→ https://www.nime.org/proceedings/2016/nime2016_paper0005.pdf
*(Key latency benchmarking paper; compares Bela against Arduino, Max/MSP, Pd.)*

**Moro, Giulio, Astrid Bin, Robert H. Jack, Christian Heinrichs, and Andrew P. McPherson.**
"Making High-Performance Embedded Instruments with Bela and Pure Data."
*Proceedings of the International Conference on Live Interfaces (ICLI)*, Brighton, 2016.
→ https://www.eecs.qmul.ac.uk/~andrewm/moro_icli2016.pdf
→ Also on ResearchGate: https://www.researchgate.net/publication/319261864
*(Main technical description of Bela hardware/software; Pure Data integration.)*

**Morreale, Fabio, Giulio Moro, Alan Chamberlain, Steve Benford, and Andrew P. McPherson.**
"Building a Maker Community Around an Open Hardware Platform."
*CHI Conference on Human Factors in Computing Systems*, Denver, 2017.
→ https://learn.bela.io/using-bela/about-bela/publications/
*(Study of the Bela user community.)*

**Bela official citations page (includes BibTeX entries for all canonical papers):**
→ https://github.com/BelaPlatform/Bela/wiki/Citing
→ https://learn.bela.io/using-bela/about-bela/publications/

---

## 2. Bela-Based Instruments at NIME (Not Pedals, but Relevant Context)

**Zelechowska, A., Bjerkestrand, K.A.V., Johnson, V., and Jensenius, A.R.**
"Bela-Based Augmented Acoustic Guitars for Sonic Microinteraction."
*Proceedings of NIME*, Blacksburg, Virginia, 2018.
→ https://www.nime.org/proceedings/2018/nime2018_paper0068.pdf

**Pelinski, Teresa, Rodrigo Diaz, Adan L. Benito Temprano, and Andrew McPherson.**
"Pipeline for Recording Datasets and Running Neural Networks on the Bela Embedded Hardware Platform."
*Proceedings of NIME*, 2023.
→ https://nime.org/proceedings/2023/nime2023_22.pdf

**NIME 2018 Workshop: "Making Embedded Instruments with Bela."**
→ https://nime2018.sched.com/event/EiuV/making-embedded-instruments-with-bela
*(Hands-on workshop; useful as evidence of Bela's presence in the NIME community.)*

**Bela at NIME — Blog overview (2020), with links to five Bela instruments presented at NIME:**
→ https://blog.bela.io/nime-2020-bela-sponsorship/

**Bela Gem campaign announcement on NIME Forum (2025) — confirms ongoing platform relevance:**
→ https://forum.nime.org/t/bela-gem-released/993

---

## 3. Programmable Effects Pedals in Academic Literature

The OWL is the only programmable effects pedal with a dedicated NIME paper. It is the closest academic precedent to Bela Fumna.

**Webster, Thomas, Guillaume LeNost, and Martin Klang.**
"The OWL Programmable Stage Effects Pedal: Revising the Concept of the On-Stage Computer for Live Music Performance."
*Proceedings of NIME*, London, 2014, pp. 621–624.
→ https://nime.org/proc/twebster12014/index.html
→ PDF direct: https://www.nime.org/proceedings/2014/nime2014_399.pdf
*(Key reference: only substantial NIME paper specifically on a programmable guitar-format effects pedal.)*

**Rebel Technology — OWL Pedal product page (open-source hardware, C++ programmable):**
→ https://www.rebeltech.org/product/owl-pedal/
→ OWL Pedal mkII: https://www.rebeltech.org/product/owl-pedal-mkii/

---

## 4. Comparison of Embedded Platforms for Audio (Bela, OWL, Raspberry Pi, Daisy)

The Moro (2016) paper already benchmarks Bela vs. OWL, Axoloti, Raspberry Pi. A more recent comparative study:

*(Referenced in Semantic Scholar results)* — A 2023/24 comparative analysis of Bela, Daisy, OWL and Raspberry Pi with Plugdata/Heavy Compiler workflows is cited in several papers but does not appear to have a stable public URL at time of compilation. Search: "Bela Daisy OWL Raspberry Pi Plugdata comparison embedded audio."

---

## 5. DIY Bela Effects Pedal Projects

### 5a. Documented builds

**Parr Burman, Mike.**
"Bela Pedal" — second-generation Bela Mini-based programmable effects pedal; C++; custom PCB design.
→ https://empeeby.com/projects/belapedal/
*(Two-generation project since 2017; the most fully documented DIY Bela pedal.)*

**Török, Lehel.**
"Effect Cape for Bela Mini" — open-source extension cape with rotary encoders, footswitches, OLED, Pure Data framework.
Master's thesis, Institute for Electronic Music and Acoustics (IEM), Graz.
→ Bela Blog: https://blog.bela.io/effects-pedal-lehel-torok/
→ Hackster.io: https://www.hackster.io/leheltorok96/effect-cape-for-bela-mini-7582df
*(Custom PCB designed in KiCad, manufactured by Eurocircuits; GitHub for patches available from the blog page.)*

**Robinson, Martin.**
"Variety Box Effects Pedal" — Bela Mini in a repurposed Corn Flakes box; Pure Data.
→ https://blog.bela.io/variety-box-bela-mini/

**RS DesignSpark / unnamed author.**
"Advanced Audio Effects with a BeagleBone Black and Bela, Part 2: Building a Multi-Effects Module for The Red Tin."
→ https://www.rs-online.com/designspark/advanced-audio-effects-with-a-beaglebone-black-and-bela-part-2-building-a-multi-effects-module-for-the-red-tin
*(Six-pot, three-button enclosure; DJ-oriented; C++; based on the transmogriFX codebase.)*

### 5b. Open-source codebases

**transmogrifox.**
*transmogriFX_bela* — multi-effects C++ processor for Bela; wah, compressor, sustainer, overdrive, EQ, delay.
→ https://github.com/transmogrifox/transmogriFX_bela

### 5c. Forum threads

**Bela Forum — "Embed Bela in a Guitar Pedal?"**
→ https://forum.bela.io/d/111-embed-bela-in-a-guitar-pedal

---

## 6. Bela and SuperCollider

**Bela Blog — "SuperCollider and Bela / Live Coding Sensors with SuperCollider":**
→ https://blog.bela.io/live-coding-sensors-with-supercollider/

**SuperCollider GitHub — README_BELA.md (build and deployment instructions):**
→ https://github.com/supercollider/supercollider/blob/develop/README_BELA.md

**Music Hackspace / Somerset House — Bela+SuperCollider Workshop:**
→ https://www.somersethouse.org.uk/whats-on/music-hackspace-belasupercollider-workshop

---

## 7. Bela Official Resources

**Bela Platform homepage:**
→ https://bela.io

**EU shop:**
→ https://eu.shop.bela.io/products/bela-starter-kit

**Bela Learn / Knowledge Base:**
→ https://learn.bela.io

**Bela Blog (project showcase, tutorials):**
→ https://blog.bela.io

**PEPPER DIY Eurorack module (Bela Mini + PCB):**
→ https://shop.bela.io/products/pepper

**Patchstorage — Bela platform patches:**
→ https://patchstorage.com/platform/bela/

---

## 8. Eurorack-Adjacent: Rebel Technology Salt/Salt+

**Rebel Technology Salt** — Bela-based Eurorack module (open-source hardware and software):
→ Schematics on GitHub (search: *Rebel Technology Salt Bela GitHub*)
→ Discussion: https://modwiggler.com/forum/viewtopic.php?t=226592

---

## Notes on Coverage Gaps

- No NIME paper specifically addresses a **SuperCollider-based** effects pedal on Bela. This remains an undocumented design space.
- No NIME paper specifically addresses a **bass guitar**-oriented Bela instrument (beyond Harrison's one-handed adaptation, 2017).
- Academic treatment of Bela pedals is limited to: one master's thesis (Török), one DIY/maker blog ecosystem, and the OWL paper as the only comparable NIME precedent.
- The NIME proceedings archive is fully searchable at https://www.nime.org/archives/ for any further targeted searches.
