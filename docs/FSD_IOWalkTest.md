# IO Test Rack Functional Specification

**Document:** ORC-TST-FSD-001 Rev 2.0
**Date:** 2026-04-08
**System:** 3 MW ORC Turbine — WAGO PFC200 Hardware IO Verification

**Related Documents:**
- `IO_List.md` — Complete IO point list and module configuration
- `commission.md` — Commissioning plan (Phase 3: Static Testing)
- `GVL_HardwareIO.st` — Hardware IO variable declarations

---

## 1. Purpose

Before connecting the PLC to field devices, every IO point must be verified to confirm correct wiring, module configuration, signal scaling, and fail-safe behavior. This document specifies a dedicated test program (`PRG_IOWalkTest`) that allows rapid, automated verification of all DI, DO, AI, and AO channels using a QH-VISG3-ED handheld signal generator and a multimeter.

The test is designed for **minimal operator interaction** — the PLC automates the sequencing and the operator follows along with their test equipment. No per-channel button presses required. The PLC detects pass/fail automatically where possible and flags anything that needs attention.

**Estimated total test time: ~30 minutes for 172 channels.**

---

## 2. Test Equipment

### 2.1 QH-VISG3-ED Multi-Function Signal Generator

| Parameter | Value |
|-----------|-------|
| Manufacturer | QH / Shenzhen Qihe |
| Model | QH-VISG3-ED |
| Current output | 0–24mA adjustable (default 4-20mA) |
| Current accuracy | 0.05mA (after calibration) |
| Voltage output | ±12V adjustable (default 0–10V) |
| Power | Battery (3.7V 1500mAh Li-ion), USB-C, or 24VDC |

### 2.2 Additional Equipment

| Item | Purpose |
|------|---------|
| Digital multimeter (DMM) | Measure DO voltage and AO current |
| Jumper wire with banana clips | Single wire to touch each DI terminal in sequence |
| 250Ω precision resistor (±0.1%) | AO test load resistor |

---

## 3. IO Module Configuration Under Test

Per `IO_List.md` Rev 3.2:

| Type | Modules | Channels | Address Range |
|------|---------|----------|---------------|
| DI | 9 (8 active + 1 spare) | 72 | %IX0.0–%IX8.7 |
| DO | 7 (6 active + 1 spare) | 56 | %QX0.0–%QX6.7 |
| AI | 8 (7 active + 1 spare) | 32 | %IW0–%IW62 |
| AO | 3 (2 active + 1 spare) | 12 | %QW0–%QW22 |

**Total: 172 channels**

---

## 4. Test Philosophy — Minimal Interaction

Each IO type uses a different automated approach:

| IO Type | Approach | Operator Action | PLC Action |
|---------|----------|-----------------|------------|
| **DI** | Touch each terminal with 24V jumper wire in order; PLC watches for rising+falling edge on each channel sequentially | Move jumper wire to next terminal, touch and release | Detects edge, auto-advances, flags missed channels |
| **AI** | Connect QH-VISG3-ED to each terminal in order at a fixed mA; repeat for 3 test points | Move signal generator lead to next terminal; change mA setting between passes | Reads value, auto-compares to expected, auto-advances on valid signal |
| **DO** | PLC sequences through all outputs, 3 seconds each | Follow along with DMM, reading each terminal in order | Energizes one output at a time, 3s dwell, auto-advances |
| **AO** | PLC ramps each output up then down (3s up, 3s down) | Follow along with DMM, verify needle sweeps | Ramps 4→20→4 mA on each channel sequentially |

---

## 5. Digital Input Test

### 5.1 Concept

The PLC watches all DI channels and expects them to be toggled **in order**. The operator touches a 24VDC jumper wire to each DI terminal sequentially — touch and release. The PLC detects the rising edge (touch) and falling edge (release) and automatically marks that channel as passed, then advances to the next expected channel.

If the operator touches a channel out of order, or a channel fails to respond within a timeout, the PLC flags it.

### 5.2 Procedure

1. Press **START DI TEST** on HMI
2. HMI displays: `"Touch DI channel %IX0.0 (hwDI_PumpRunFeedback)"`
3. Touch the jumper wire from the 24VDC bus to the %IX0.0 terminal, then release
4. PLC detects rising edge → falling edge → marks PASS → advances
5. HMI displays: `"Touch DI channel %IX0.1 (hwDI_PumpFault)"`
6. Continue through all 72 channels
7. When complete, HMI shows results summary

### 5.3 Logic

```
PROGRAM PRG_DI_Test
VAR
    ExpectedChannel  : INT := 0;        // Which channel we're waiting for
    WaitingForRise   : BOOL := TRUE;    // Waiting for touch (rising edge)
    WaitingForFall   : BOOL := FALSE;   // Waiting for release (falling edge)
    ChannelTimeout   : TON;             // 30s timeout per channel
    DI_Results       : ARRAY[0..71] OF INT;  // 0=untested, 1=passed, 2=failed, 3=skipped
    DI_Prev          : ARRAY[0..71] OF BOOL; // Previous scan state for edge detection
    TestActive       : BOOL;
END_VAR

IF TestActive THEN
    ChannelTimeout(IN := TRUE, PT := T#30s);

    // Read current expected channel
    CurrentState := ReadDI(ExpectedChannel);

    // Detect rising edge (operator touched the terminal)
    IF WaitingForRise AND CurrentState AND NOT DI_Prev[ExpectedChannel] THEN
        WaitingForRise := FALSE;
        WaitingForFall := TRUE;
        ChannelTimeout(IN := FALSE);  // Reset timeout
        ChannelTimeout(IN := TRUE);
    END_IF

    // Detect falling edge (operator released)
    IF WaitingForFall AND NOT CurrentState AND DI_Prev[ExpectedChannel] THEN
        // PASS — both edges detected
        DI_Results[ExpectedChannel] := 1;
        WaitingForRise := TRUE;
        WaitingForFall := FALSE;
        ExpectedChannel := ExpectedChannel + 1;
        ChannelTimeout(IN := FALSE);
        ChannelTimeout(IN := TRUE);

        IF ExpectedChannel >= TotalDIChannels THEN
            TestActive := FALSE;
            DI_TestComplete := TRUE;
        END_IF
    END_IF

    // Check for out-of-order activation (wrong channel toggled)
    FOR i := 0 TO TotalDIChannels - 1 DO
        IF i <> ExpectedChannel THEN
            IF ReadDI(i) AND NOT DI_Prev[i] THEN
                // Unexpected channel activated
                ALM_DI_WRONG_CHANNEL := TRUE;
                WrongChannelIndex := i;
            END_IF
        END_IF
    END_FOR

    // Timeout — operator missed this channel
    IF ChannelTimeout.Q THEN
        DI_Results[ExpectedChannel] := 2;  // FAILED — no response
        ALM_DI_TIMEOUT := TRUE;
        // Auto-advance to next channel (don't block the whole test)
        ExpectedChannel := ExpectedChannel + 1;
        WaitingForRise := TRUE;
        WaitingForFall := FALSE;
        ChannelTimeout(IN := FALSE);
        ChannelTimeout(IN := TRUE);
    END_IF

    // Store previous states for edge detection
    FOR i := 0 TO TotalDIChannels - 1 DO
        DI_Prev[i] := ReadDI(i);
    END_FOR
END_IF
```

### 5.4 NC Contact Handling

For normally-closed contacts (E-stop, level switches, temp switches), the channel reads TRUE at rest. The test logic is inverted: the PLC waits for a **falling** edge (operator opens the NC path), then a **rising** edge (operator reconnects). The channel lookup table includes a `ContactType` field ("NO" or "NC") that the logic uses to determine which edge sequence to expect.

```
IF DI_Channels[ExpectedChannel].ContactType = 'NC' THEN
    // NC: expect fall-then-rise (operator disconnects then reconnects)
    // Invert the edge detection
END_IF
```

### 5.5 HMI Display

```
+-- DI TEST (AUTO-ADVANCING) ---------------------------------------------------+
|                                                                               |
|  WAITING FOR: %IX0.4  hwDI_LubeOilTempOk  [NC contact]                       |
|  ACTION: Disconnect jumper from terminal, then reconnect                      |
|                                                                               |
|  Channel 5 of 72          Elapsed: 1:42                                       |
|                                                                               |
|  ┌─ PROGRESS ───────────────────────────────────────────┐                     |
|  │ %IX0.0 [PASS]  %IX0.1 [PASS]  %IX0.2 [PASS]        │                     |
|  │ %IX0.3 [PASS]  %IX0.4 [>>>>]  %IX0.5 [    ]        │                     |
|  │ %IX0.6 [    ]  %IX0.7 [    ]  %IX1.0 [    ]  ...   │                     |
|  └──────────────────────────────────────────────────────┘                     |
|                                                                               |
|  PASSED: 4    FAILED: 0    TIMEOUT: 0                                         |
|                                                                               |
|  [ SKIP CHANNEL ]    [ STOP TEST ]                                            |
+-------------------------------------------------------------------------------+
```

### 5.6 Estimated Time

At ~3 seconds per channel (touch, release, advance): **72 channels × 3s = ~3.5 minutes**

---

## 6. Digital Output Test

### 6.1 Concept

The PLC sequences through all DO channels automatically, energizing one at a time for 3 seconds, then de-energizing and advancing to the next. The operator follows along with a DMM, reading 24VDC at each terminal.

The HMI shows which channel is currently active, a countdown timer, and which channel is next — so the operator can position their DMM probe on the next terminal during the current dwell.

### 6.2 Procedure

1. Press **START DO TEST** on HMI
2. PLC de-energizes all outputs
3. PLC energizes %QX0.0, HMI shows: `"ACTIVE: %QX0.0 hwDO_PumpStart — 3s"` with countdown
4. Operator reads 24VDC at terminal with DMM
5. After 3 seconds, PLC de-energizes %QX0.0, energizes %QX0.1
6. HMI shows next channel with countdown
7. Operator moves probe to next terminal
8. Continues through all 56 channels
9. At end, PLC de-energizes all outputs

### 6.3 Logic

```
PROGRAM PRG_DO_Test
VAR
    CurrentChannel   : INT := 0;
    DwellTimer       : TON;
    DwellTime        : TIME := T#3s;
    TestActive       : BOOL;
END_VAR

IF TestActive THEN
    // De-energize all
    ClearAllDO();

    // Energize current channel
    WriteDO(CurrentChannel, TRUE);

    // Display info
    ActiveAddress := DO_Channels[CurrentChannel].Address;
    ActiveTag := DO_Channels[CurrentChannel].Tag;
    ActiveDescription := DO_Channels[CurrentChannel].Description;
    SecondsRemaining := TIME_TO_INT(DwellTime - DwellTimer.ET) / 1000;
    NextChannel := CurrentChannel + 1;

    // Dwell timer
    DwellTimer(IN := TRUE, PT := DwellTime);
    IF DwellTimer.Q THEN
        WriteDO(CurrentChannel, FALSE);
        DwellTimer(IN := FALSE);
        CurrentChannel := CurrentChannel + 1;

        IF CurrentChannel >= TotalDOChannels THEN
            ClearAllDO();
            TestActive := FALSE;
            DO_TestComplete := TRUE;
        END_IF
    END_IF
END_IF
```

### 6.4 Special Channel Handling

| Channel | Tag | Handling |
|---------|-----|---------|
| %QX0.6 | hwDO_TripSolenoid | De-energize-to-trip. The test **energizes** it (normal running state), then de-energizes (trip state). HMI note: "Listen for solenoid click ON, then OFF." |
| %QX1.3 | hwDO_WatchdogHeartbeat | Held steady (not toggling). Safety relay will trip from missing heartbeat — this is expected. HMI note: "Safety relay will trip — reset after this channel." |

### 6.5 HMI Display

```
+-- DO TEST (AUTO-SEQUENCING, 3s per channel) ----------------------------------+
|                                                                               |
|  ACTIVE:  %QX0.3  hwDO_CondenserFan  "Condenser fan contactor"               |
|  TIME:    [██████░░░░]  1.8s remaining                                        |
|                                                                               |
|  NEXT:    %QX0.4  hwDO_WoodwardEnable  "Woodward 505 enable"                 |
|           (move DMM probe to %QX0.4 terminal now)                             |
|                                                                               |
|  Channel 4 of 56          Elapsed: 0:12                                       |
|                                                                               |
|  ┌─ PROGRESS ───────────────────────────────────────────┐                     |
|  │ %QX0.0 [DONE]  %QX0.1 [DONE]  %QX0.2 [DONE]        │                     |
|  │ %QX0.3 [>>>>]  %QX0.4 [NEXT]  %QX0.5 [    ]  ...   │                     |
|  └──────────────────────────────────────────────────────┘                     |
|                                                                               |
|  [ PAUSE ]    [ MARK FAIL ]    [ SKIP ]    [ STOP / ALL OFF ]                |
+-------------------------------------------------------------------------------+
```

The operator can press **MARK FAIL** at any time during the 3-second dwell if the DMM reading is wrong. This tags the current channel as failed without stopping the sequence.

### 6.6 Estimated Time

56 channels × 3 seconds = **~3 minutes**

---

## 7. Analog Input Test

### 7.1 Concept

Instead of testing each channel at all three mA levels before moving on, the test runs **three passes across all channels** — one pass per test point. The operator connects the QH-VISG3-ED to each terminal in order while the PLC auto-detects when a valid signal appears and records the reading.

| Pass | QH-VISG3-ED Setting | Expected Raw | Expected Meaning |
|------|---------------------|-------------|------------------|
| Pass 1 | 4.00 mA | ~3277 | 0% of range |
| Pass 2 | 12.00 mA | ~16384 | 50% of range |
| Pass 3 | 20.00 mA | ~32767 | 100% of range |

Between passes, the operator changes the QH-VISG3-ED output — one dial adjustment, not per-channel.

### 7.2 Procedure

**Pass 1 (4mA):**
1. Set QH-VISG3-ED to **4.00 mA**
2. Press **START AI TEST** on HMI
3. HMI shows: `"Connect QH-VISG3-ED (4mA) to %IW0 (hwAI_LubeOilPressure)"`
4. Connect the signal generator leads to the %IW0 input terminals
5. PLC detects a valid 4mA signal (raw value enters the 3277 ± 500 window) → records reading → auto-advances
6. HMI shows: `"Connect to %IW2 (hwAI_LubeOilTemperature)"`
7. Move leads to next AI terminal
8. Continue through all 32 channels
9. HMI shows: `"Pass 1 complete. Set QH-VISG3-ED to 12.00 mA and press CONTINUE"`

**Pass 2 (12mA):**
10. Change QH-VISG3-ED to **12.00 mA**
11. Press **CONTINUE**
12. Repeat step 3–8 for all 32 channels at 12mA

**Pass 3 (20mA):**
13. Change QH-VISG3-ED to **20.00 mA**
14. Press **CONTINUE**
15. Repeat for all 32 channels at 20mA
16. Test complete — HMI shows results

### 7.3 Logic

```
PROGRAM PRG_AI_Test
VAR
    CurrentChannel  : INT := 0;
    CurrentPass     : INT := 1;          // 1=4mA, 2=12mA, 3=20mA
    ExpectedRaw     : ARRAY[1..3] OF INT := [3277, 16384, 32767];
    Tolerance       : INT := 500;        // ± raw counts (~1.5% of span)
    SettleTimer     : TON;               // Debounce: signal must be stable for 500ms
    ChannelTimeout  : TON;               // 30s timeout
    WaitingForSignal: BOOL := TRUE;
    WaitingForContinue : BOOL := FALSE;  // Waiting for operator between passes

    AI_Readings     : ARRAY[0..31, 1..3] OF INT;   // Recorded raw values [channel, pass]
    AI_Results      : ARRAY[0..31, 1..3] OF INT;    // 0=untested, 1=pass, 2=fail
    TestActive      : BOOL;
END_VAR

IF TestActive AND NOT WaitingForContinue THEN
    CurrentRaw := ReadAI(CurrentChannel);
    ChannelTimeout(IN := TRUE, PT := T#30s);

    // Check if signal is within expected window
    SignalInWindow := ABS(CurrentRaw - ExpectedRaw[CurrentPass]) < Tolerance;

    IF SignalInWindow THEN
        // Debounce: must be stable for 500ms
        SettleTimer(IN := TRUE, PT := T#500ms);
        IF SettleTimer.Q THEN
            // Record reading
            AI_Readings[CurrentChannel, CurrentPass] := CurrentRaw;

            // Evaluate pass/fail
            ScaledActual := ScaleAI(CurrentRaw, AI_Channels[CurrentChannel].RangeLow,
                                                AI_Channels[CurrentChannel].RangeHigh);
            ScaledExpected := ScaleAI(ExpectedRaw[CurrentPass], AI_Channels[CurrentChannel].RangeLow,
                                                                AI_Channels[CurrentChannel].RangeHigh);
            Error_Pct := ABS(ScaledActual - ScaledExpected) / (AI_Channels[CurrentChannel].RangeHigh
                          - AI_Channels[CurrentChannel].RangeLow) * 100.0;

            IF Error_Pct < 1.0 THEN
                AI_Results[CurrentChannel, CurrentPass] := 1;  // PASS
            ELSE
                AI_Results[CurrentChannel, CurrentPass] := 2;  // FAIL (in range but inaccurate)
            END_IF

            // Advance to next channel
            SettleTimer(IN := FALSE);
            ChannelTimeout(IN := FALSE);
            CurrentChannel := CurrentChannel + 1;

            IF CurrentChannel >= TotalAIChannels THEN
                IF CurrentPass < 3 THEN
                    // End of pass — wait for operator to change mA and press CONTINUE
                    WaitingForContinue := TRUE;
                    CurrentChannel := 0;
                    CurrentPass := CurrentPass + 1;
                ELSE
                    // All 3 passes complete
                    TestActive := FALSE;
                    AI_TestComplete := TRUE;
                END_IF
            END_IF
        END_IF
    ELSE
        SettleTimer(IN := FALSE);  // Reset settle if signal drifts out of window
    END_IF

    // Timeout — no valid signal detected in 30s
    IF ChannelTimeout.Q THEN
        AI_Results[CurrentChannel, CurrentPass] := 2;  // FAIL — no signal
        ALM_AI_TIMEOUT := TRUE;
        ChannelTimeout(IN := FALSE);
        CurrentChannel := CurrentChannel + 1;
        // (same end-of-pass logic as above)
    END_IF
END_IF
```

### 7.4 Wire Break Test (Optional 4th Pass)

After the three signal passes, the operator can optionally run a **wire break pass**:
1. Disconnect the QH-VISG3-ED entirely
2. Press **START WIRE BREAK TEST**
3. PLC verifies all 32 AI channels read <500 counts (0mA / open circuit)
4. This is automatic — no per-channel interaction. The PLC reads all channels simultaneously and reports any channel that does NOT show a wire break condition (indicating a stuck or shorted input).

### 7.5 HMI Display

```
+-- AI TEST (PASS 1 of 3: 4mA) ------------------------------------------------+
|                                                                               |
|  QH-VISG3-ED SETTING: 4.00 mA                                                |
|                                                                               |
|  CONNECT TO: %IW4  hwAI_CondenserVacuum  "PT-201: 0-1 bar(a)"               |
|                                                                               |
|  LIVE READING:  Raw: [ 3301 ]    Scaled: [ 0.01 bar(a) ]                     |
|  EXPECTED:      Raw: [ 3277 ]    Scaled: [ 0.00 bar(a) ]                     |
|  STATUS:        [ SIGNAL DETECTED — SETTLING... ]                             |
|                                                                               |
|  Channel 3 of 32          Pass 1 of 3          Elapsed: 0:28                  |
|                                                                               |
|  ┌─ PROGRESS ───────────────────────────────────────────┐                     |
|  │ %IW0  [PASS]   %IW2  [PASS]   %IW4  [>>>>]          │                     |
|  │ %IW6  [    ]   %IW8  [    ]   %IW10 [    ]  ...     │                     |
|  └──────────────────────────────────────────────────────┘                     |
|                                                                               |
|  [ SKIP CHANNEL ]    [ STOP TEST ]                                            |
+-------------------------------------------------------------------------------+
```

Between passes:
```
|  PASS 1 COMPLETE (32/32 channels)                                             |
|                                                                               |
|  Set QH-VISG3-ED to: 12.00 mA                                                |
|                                                                               |
|  [ CONTINUE ]                                                                 |
```

### 7.6 Estimated Time

At ~5 seconds per channel (move lead, settle, auto-advance):
- 32 channels × 5s × 3 passes = **~8 minutes** + 30s between passes = **~9 minutes**
- Wire break pass: ~10 seconds (all channels simultaneously)

---

## 8. Analog Output Test

### 8.1 Concept

The PLC ramps each AO channel from 4mA → 20mA over 3 seconds, then 20mA → 4mA over 3 seconds, then advances to the next channel. The operator holds DMM leads on each output terminal and watches the reading sweep up then down. If the needle sweeps smoothly from ~4mA to ~20mA and back, the channel is good.

This is faster than stepping to discrete values and waiting — the operator sees the full range in one continuous motion.

### 8.2 Procedure

1. Connect DMM (in mA mode) in series with 250Ω load resistor across the first AO terminal
2. Press **START AO TEST** on HMI
3. PLC ramps %QW0 from 4mA → 20mA over 3 seconds (linear ramp)
4. PLC ramps %QW0 from 20mA → 4mA over 3 seconds
5. HMI shows: `"Move DMM to %QW2 (hwAO_LoadSetpoint)"` with 2-second pause to reposition
6. PLC ramps %QW2 up and down
7. Continue through all 12 channels

### 8.3 Logic

```
PROGRAM PRG_AO_Test
VAR
    CurrentChannel  : INT := 0;
    Phase           : INT := 0;       // 0=ramp up, 1=ramp down, 2=pause/advance
    RampTimer       : TON;
    RampDuration    : TIME := T#3s;
    PauseDuration   : TIME := T#2s;   // Pause between channels to move DMM
    RampProgress    : REAL;           // 0.0 to 1.0
    OutputRaw       : INT;
    TestActive      : BOOL;
END_VAR

IF TestActive THEN
    RampTimer(IN := TRUE, PT := CASE Phase OF 0,1: RampDuration; 2: PauseDuration; END_CASE);
    RampProgress := TIME_TO_REAL(RampTimer.ET) / TIME_TO_REAL(
                    CASE Phase OF 0,1: RampDuration; 2: PauseDuration; END_CASE);

    CASE Phase OF
    0: // Ramp up: 4mA → 20mA
        OutputRaw := REAL_TO_INT(RampProgress * 32767.0);
        WriteAO(CurrentChannel, OutputRaw);

        // Display current output in mA
        CurrentOutput_mA := 4.0 + (RampProgress * 16.0);

        IF RampTimer.Q THEN
            RampTimer(IN := FALSE);
            Phase := 1;
        END_IF

    1: // Ramp down: 20mA → 4mA
        OutputRaw := REAL_TO_INT((1.0 - RampProgress) * 32767.0);
        WriteAO(CurrentChannel, OutputRaw);
        CurrentOutput_mA := 4.0 + ((1.0 - RampProgress) * 16.0);

        IF RampTimer.Q THEN
            WriteAO(CurrentChannel, 0);  // Return to 4mA
            RampTimer(IN := FALSE);
            Phase := 2;
        END_IF

    2: // Pause — operator moves DMM to next channel
        WriteAO(CurrentChannel, 0);

        IF RampTimer.Q THEN
            RampTimer(IN := FALSE);
            CurrentChannel := CurrentChannel + 1;
            Phase := 0;

            IF CurrentChannel >= TotalAOChannels THEN
                ClearAllAO();
                TestActive := FALSE;
                AO_TestComplete := TRUE;
            END_IF
        END_IF
    END_CASE
END_IF
```

### 8.4 HMI Display

```
+-- AO TEST (AUTO-RAMPING, 3s up / 3s down per channel) -----------------------+
|                                                                               |
|  ACTIVE:  %QW0  hwAO_SpeedSetpoint  "Speed setpoint to Woodward 505"         |
|                                                                               |
|  OUTPUT:  [████████████████░░░░░░░░░░░░░░] 14.2 mA   PHASE: RAMP UP         |
|           4 mA ─────────────────────────── 20 mA                              |
|                                                                               |
|  Verify DMM reads ~14.2 mA and sweeping upward                               |
|                                                                               |
|  NEXT:    %QW2  hwAO_LoadSetpoint  (move DMM after ramp-down)                 |
|                                                                               |
|  Channel 1 of 12          Elapsed: 0:04                                       |
|                                                                               |
|  [ PAUSE ]    [ MARK FAIL ]    [ SKIP ]    [ STOP / ALL OFF ]                |
+-------------------------------------------------------------------------------+
```

### 8.5 Estimated Time

12 channels × (3s up + 3s down + 2s pause) = **~1.5 minutes**

---

## 9. AUTO ALL Mode

Pressing **AUTO ALL** runs the complete test sequence back-to-back:

```
1. DI Test         ~3.5 min    (operator: jumper wire, touch each terminal)
2. DO Test         ~3.0 min    (operator: DMM, follow the sequence)
3. AI Test Pass 1  ~2.5 min    (operator: QH-VISG3-ED at 4mA, move leads)
   -- "Set to 12mA, press CONTINUE" --
4. AI Test Pass 2  ~2.5 min    (operator: QH-VISG3-ED at 12mA)
   -- "Set to 20mA, press CONTINUE" --
5. AI Test Pass 3  ~2.5 min    (operator: QH-VISG3-ED at 20mA)
6. AI Wire Break   ~0.2 min    (operator: disconnect signal gen)
7. AO Test         ~1.5 min    (operator: DMM on each AO terminal)
                   ──────────
                   ~16 minutes total (plus transition time)
```

**Realistic total with transitions: ~25–30 minutes.**

---

## 10. Results and Reporting

### 10.1 Auto-Detected Results

| IO Type | Auto-Pass Criteria | Auto-Fail Criteria |
|---------|-------------------|-------------------|
| DI | Rising + falling edge detected on expected channel | Timeout (30s no response), wrong channel activated |
| AI | Raw reading within ±500 counts of expected, scaled error <1% | Timeout, reading >1% error, wire break not detected in pass 4 |
| DO | N/A (operator visual) | Operator presses MARK FAIL |
| AO | N/A (operator visual) | Operator presses MARK FAIL |

### 10.2 Results Summary Screen

```
+-- IO WALK TEST RESULTS -------------------------------------------------------+
|                                                                               |
|  Test Date: 2026-04-12    Duration: 27 minutes                                |
|                                                                               |
|  DIGITAL INPUTS:   72 channels   70 PASS   1 FAIL   1 SKIP                   |
|    FAIL: %IX2.4 — timeout (no edge detected)                                 |
|    SKIP: %IX8.3 — operator skipped (spare)                                   |
|                                                                               |
|  DIGITAL OUTPUTS:  56 channels   56 PASS   0 FAIL   0 SKIP                   |
|                                                                               |
|  ANALOG INPUTS:    32 channels                                                |
|    Pass 1 (4mA):  32 PASS   0 FAIL        Max error: 0.3%                    |
|    Pass 2 (12mA): 31 PASS   1 FAIL        Max error: 0.8%                    |
|    Pass 3 (20mA): 32 PASS   0 FAIL        Max error: 0.4%                    |
|    Wire break:    32 PASS   0 FAIL                                            |
|    FAIL: %IW22 Pass 2 — read 16801 (expected 16384, error 1.3%)             |
|                                                                               |
|  ANALOG OUTPUTS:   12 channels   12 PASS   0 FAIL   0 SKIP                   |
|                                                                               |
|  OVERALL: 171/172 PASSED                                                      |
|                                                                               |
|  [ EXPORT CSV ]    [ RE-TEST FAILED ]    [ PRINT ]                            |
+-------------------------------------------------------------------------------+
```

### 10.3 CSV Export

Results are exported to `/var/log/turbine/io_walktest_YYYY-MM-DD.csv`:

```csv
Date,Type,Address,Tag,Test,RawValue,ExpectedRaw,ScaledValue,ExpectedScaled,Error%,Result
2026-04-12,DI,%IX0.0,hwDI_PumpRunFeedback,Edge,1,1,,,, PASS
2026-04-12,AI,%IW0,hwAI_LubeOilPressure,4mA,3290,3277,0.4,0.0,0.4,PASS
2026-04-12,AI,%IW0,hwAI_LubeOilPressure,12mA,16401,16384,50.1,50.0,0.1,PASS
2026-04-12,AI,%IW0,hwAI_LubeOilPressure,20mA,32750,32767,99.9,100.0,0.1,PASS
...
```

### 10.4 Re-Test Failed Only

The **RE-TEST FAILED** button runs only the channels that failed, using the same automated approach. This avoids re-testing all 172 channels after fixing a wiring issue.

---

## 11. Safety Considerations

### 11.1 All-Off Button

The HMI has a prominent **STOP / ALL OFF** button that immediately:
- De-energizes all DO outputs
- Sets all AO outputs to 0 (4mA)
- Stops all test sequences
- Returns to IDLE

### 11.2 Mutual Exclusion

- `PRG_IOWalkTest` and `PRG_Main` must NEVER run simultaneously
- Walk test task only enabled via a dedicated flag in CODESYS device config
- All normal application logic is bypassed during walk test
- Watchdog heartbeat is not toggled — safety relay will trip (expected during bench test)

### 11.3 No Field Devices Connected

The walk test is designed for **panel-only testing** with no field cables landed. If field cables are connected, DO sequencing will energize contactors and solenoids — ensure equipment is safe or disconnect field cables first.

---

## 12. Module Diagnostic Pre-Check

Before starting any walk test, the program reads all module health flags and displays a summary:

```
+-- MODULE HEALTH CHECK --------------------------------------------------------+
|                                                                               |
|  DI-1 [OK]  DI-2 [OK]  DI-3 [OK]  DI-4 [OK]  DI-5 [OK]                    |
|  DI-6 [OK]  DI-7 [OK]  DI-8 [OK]  DI-9 [OK]                                |
|  DO-1 [OK]  DO-2 [OK]  DO-3 [OK]  DO-4 [OK]  DO-5 [OK]                     |
|  DO-6 [OK]  DO-7 [OK]                                                        |
|  AI-1 [OK]  AI-2 [OK]  AI-3 [OK]  AI-4 [OK]  AI-5 [OK]                     |
|  AI-6 [OK]  AI-7 [OK]  AI-8 [OK]                                             |
|  AO-1 [OK]  AO-2 [OK]  AO-3 [OK]                                             |
|                                                                               |
|  ALL MODULES OK — ready to test                                               |
|                                                                               |
|  [ START DI ]  [ START DO ]  [ START AI ]  [ START AO ]  [ AUTO ALL ]        |
+-------------------------------------------------------------------------------+
```

Any module showing FAIL blocks that module's test until the issue is resolved.

---

## 13. Integration with commission.md

This replaces commission.md Phase 3 (Static Testing, Day 5) Sections 5.3–5.6 with a faster, more automated procedure:

| Commission.md | Old Approach | New Approach | Time Saved |
|---------------|-------------|-------------|------------|
| 5.3 DI Testing | Manual force per channel, document each | Auto-edge detect, touch-and-go | ~25 min |
| 5.4 DO Testing | Manual force per channel, measure each | Auto-sequence 3s dwell | ~20 min |
| 5.5 AI Testing | 3 injections per channel, read each | 3 passes, auto-detect on connect | ~30 min |
| 5.6 AO Testing | Set 3 values per channel, measure each | Auto-ramp, watch sweep | ~10 min |

**Old estimated time: ~2 hours. New estimated time: ~30 minutes.**

---

## Revision History

| Rev | Date | Author | Changes |
|-----|------|--------|---------|
| 1.0 | 2026-04-08 | Claude Code | Initial release — per-channel pass/fail workflow |
| 2.0 | 2026-04-08 | Claude Code | Redesigned for minimal interaction: DI auto-edge detect, AI 3-pass approach, DO auto-sequence with 3s dwell, AO auto-ramp sweep. Reduced test time from ~2 hours to ~30 minutes |
