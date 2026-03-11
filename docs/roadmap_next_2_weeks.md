# Xeno Breach — Nästa 2 veckor (prioriterad roadmap)

Detta dokument bryter ner nästa steg efter nuvarande spelbara prototyp (v0.1.0)
för att snabbt höja spelkänsla, balans och leveransbarhet.

## Framsteg — snabbstatus

| # | Uppgift | Status |
|---|---------|--------|
| 1 | Combat-feel och readability | ✅ Klar |
| 2 | HUD + run-resultat | ✅ Klar |
| 3 | Balanspass med telemetry | 🔲 Återstår |
| 4 | Våginnehåll och variantmix | 🔲 Återstår |
| 5 | Meny/pause/game state polish | 🔲 Återstår |
| 6 | Test- och leveranshygien | 🔲 Återstår |

---

## Målbild för perioden

- M1: Stabil och läsbar core-loop (start → 5 vågor → resultat → retry/menu)
- M2: Tydlig combat feedback (träff, skada, död, vågtempo)
- M3: Balanserad svårighetskurva med mätbar telemetry
- M4: Bas för release-ready iteration (test/checklist/build-rutin)

---

## Prioriteringsprincip

1. Spelbarhet före polish
2. Tydlig feedback före nytt innehåll
3. Datadriven tuning före hårdkodade specialfall
4. Små, verifierbara leveranser varje dag

---

## Vecka 1 — "Core feel + clarity"

### 1) Combat-feel och readability ✅ Klar

**Leverabler**
- [x] Hit flash på fiender när de tar skada (#19)
- [x] Kort skärmeffekt/indikator vid spelarskada (#24)
- [x] Enkel muzzle/tracer-effekt på projektiler (#27)
- [x] Tydligare death feedback (sprite blink/fade) (#28)

**Varför**
- Nuvarande loop fungerar, men feedback-lagret avgör om combat känns "rätt".

**Klart när**
- En testspelare kan direkt uppfatta: "jag träffade", "jag tog skada", "fienden dog" utan att läsa siffror.

---

### 2) HUD + run-resultat ✅ Klar

**Leverabler**
- [x] Förtydliga HUD-texter (wave progress, score feedback) (#29)
- [x] Visa mellanresultat efter varje våg (kort banner) (#29)
- [x] Förbättra slutskärm med tydlig CTA (Retry/Menu) (#29)

**Varför**
- HUD finns redan men kan bära progression bättre och minska kognitiv friktion.

**Klart när**
- Spelare förstår alltid vilken våg de är på och vad nästa knapptryck gör.

---

### 3) Balanspass med telemetry 🔲 Återstår (Hög prioritet)

**Leverabler**
- [ ] Behåll och använd telemetry-fälten aktivt per våg
- [ ] Kör 10–15 interna runs och logga: clear-time, damage taken, kills/min
- [ ] Justera wave_data i små steg (enemy_count, spawn_delay, enemy mix)

**Varför**
- Data finns redan; snabbaste vägen till bättre pacing är systematisk tuning.

**Klart när**
- Minst 70% av runs landar inom målintervall för clear-time och damage taken.

---

## Vecka 2 — "Content pass + robustness"

### 4) Våginnehåll och variantmix 🔲 Återstår (Medium-Hög prioritet)

**Leverabler**
- [ ] Introducera `enemy_scene_pool` på fler vågor för mixade spawns
- [ ] Definiera 2–3 tydliga våg-identiteter (rush, attrition, burst)
- [ ] Finjustera spawn safety-radie mot spelarpuls

**Varför**
- Variationen finns på plats i systemet; nu behövs mer kuraterade encounter-profiler.

**Klart när**
- Vågor känns olika i beteende, inte bara i antal HP/enemies.

---

### 5) Meny/pause/game state polish 🔲 Återstår (Medium prioritet)

**Leverabler**
- [ ] Konsistent state-övergång för pause/retry/menu
- [ ] Säkerställ att input inte dubbeltriggar vid scenbyte
- [ ] Lägg till enkel run-seed/run-id i logg för reproducerbarhet

**Varför**
- Ökar stabiliteten och förenklar felsökning av edge-cases.

**Klart när**
- Inga kända state-glitchar i 20 raka runs.

---

### 6) Test- och leveranshygien 🔲 Återstår (Medium prioritet)

**Leverabler**
- [ ] Utöka testfall för wave progression edge-cases
- [ ] Lägg till snabb "pre-merge checklist" i repo
- [ ] Definiera enkel build/rök-test-rutin inför varje merge

**Varför**
- Skyddar tempot när fler features adderas.

**Klart när**
- Teamet kan köra en standardiserad check före merge utan ad hoc-steg.

---

## Backlog efter 2 veckor (ej blockerande nu)

- Vapenvariation (burst/spread/charge)
- Djupare fiende-AI (sidestepping, kiting, telegraph attacks)
- Progression/meta-system
- Co-op foundations
- Ljudbild och VFX-pass i större skala

---

## Arbetsupplägg (rekommenderat)

- Daglig rytm: 1 gameplay-task + 1 quality-task
- Max 1 större systemändring per dag
- Avsluta varje dag med kort "before/after" notering:
  - vad ändrades
  - vilken metric förbättrades/försämrades
  - nästa hypotes

---

## KPI:er för perioden

- Median clear-time per våg
- Damage taken per våg
- Kills per minute
- Death-rate på wave 3–5
- Retry-rate efter game over

Om dessa rör sig åt rätt håll har perioden levererat effekt, inte bara kodmängd.
