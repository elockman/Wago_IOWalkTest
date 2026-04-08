FUNCTION_BLOCK FB_AOTest
VAR_INPUT
    bStart      : BOOL;
    bStop       : BOOL;
    bSkip       : BOOL;
    bPause      : BOOL;
    bMarkFail   : BOOL;
    bRetestOnly : BOOL;
END_VAR
VAR_OUTPUT
    eState          : E_TestState;
    nCurrentChannel : INT;
    nTotalChannels  : INT := GVL_IOWalkTest.C_NUM_AO;
    aResults        : ARRAY[0..11] OF E_TestResult;
    ePhase          : E_AOPhase;
    sCurrentAddress : STRING(15);
    sCurrentTag     : STRING(40);
    sCurrentDesc    : STRING(80);
    sNextAddress    : STRING(15);
    sNextTag        : STRING(40);
    rCurrentOutput_mA : REAL;
    rRampProgress   : REAL;       // 0.0 to 1.0
    nPassed         : INT;
    nFailed         : INT;
    nSkipped        : INT;
END_VAR
VAR
    fbRampTimer     : TON;
    aAO_Channels    : ARRAY[0..11] OF ST_AOChannel;
    bStartPrev      : BOOL;
    bSkipPrev       : BOOL;
    bMarkFailPrev   : BOOL;
    bChannelMarkedFail : BOOL;
    nOutputRaw      : INT;
    rProgress       : REAL;
    tCurrentPT      : TIME;
    i               : INT;
END_VAR

// One-shot start
IF bStart AND NOT bStartPrev THEN
    IF eState = E_TestState.IDLE OR eState = E_TestState.COMPLETE OR eState = E_TestState.ABORTED THEN
        eState := E_TestState.RUNNING;
        nCurrentChannel := 0;
        ePhase := E_AOPhase.RAMP_UP;
        nPassed := 0;
        nFailed := 0;
        nSkipped := 0;
        bChannelMarkedFail := FALSE;
        fbRampTimer(IN := FALSE);

        IF NOT bRetestOnly THEN
            FOR i := 0 TO 11 DO
                aResults[i] := E_TestResult.UNTESTED;
            END_FOR
        END_IF

        // Zero all outputs
        FOR i := 0 TO 11 DO
            IF aAO_Channels[i].pOutput <> 0 THEN
                aAO_Channels[i].pOutput^ := 0;
            END_IF
        END_FOR

        IF bRetestOnly THEN
            WHILE nCurrentChannel < nTotalChannels
                  AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
                nCurrentChannel := nCurrentChannel + 1;
            END_WHILE
        END_IF
    END_IF
END_IF
bStartPrev := bStart;

// Stop / All Off
IF bStop THEN
    FOR i := 0 TO 11 DO
        IF aAO_Channels[i].pOutput <> 0 THEN
            aAO_Channels[i].pOutput^ := 0;
        END_IF
    END_FOR
    IF eState = E_TestState.RUNNING OR eState = E_TestState.PAUSED THEN
        eState := E_TestState.ABORTED;
        fbRampTimer(IN := FALSE);
    END_IF
END_IF

// Pause toggle
IF bPause AND eState = E_TestState.RUNNING THEN
    eState := E_TestState.PAUSED;
ELSIF bPause AND eState = E_TestState.PAUSED THEN
    eState := E_TestState.RUNNING;
END_IF

// Skip (one-shot)
IF bSkip AND NOT bSkipPrev AND eState = E_TestState.RUNNING THEN
    IF aAO_Channels[nCurrentChannel].pOutput <> 0 THEN
        aAO_Channels[nCurrentChannel].pOutput^ := 0;
    END_IF
    aResults[nCurrentChannel] := E_TestResult.SKIPPED;
    nSkipped := nSkipped + 1;
    bChannelMarkedFail := FALSE;
    fbRampTimer(IN := FALSE);
    ePhase := E_AOPhase.RAMP_UP;
    nCurrentChannel := nCurrentChannel + 1;

    IF bRetestOnly THEN
        WHILE nCurrentChannel < nTotalChannels
              AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
            nCurrentChannel := nCurrentChannel + 1;
        END_WHILE
    END_IF

    IF nCurrentChannel >= nTotalChannels THEN
        eState := E_TestState.COMPLETE;
    END_IF
END_IF
bSkipPrev := bSkip;

// Mark fail (one-shot)
IF bMarkFail AND NOT bMarkFailPrev AND eState = E_TestState.RUNNING THEN
    bChannelMarkedFail := TRUE;
END_IF
bMarkFailPrev := bMarkFail;

// Main ramp logic
IF eState = E_TestState.RUNNING AND nCurrentChannel < nTotalChannels THEN
    // HMI info
    sCurrentAddress := aAO_Channels[nCurrentChannel].sAddress;
    sCurrentTag     := aAO_Channels[nCurrentChannel].sTag;
    sCurrentDesc    := aAO_Channels[nCurrentChannel].sDescription;

    IF nCurrentChannel + 1 < nTotalChannels THEN
        sNextAddress := aAO_Channels[nCurrentChannel + 1].sAddress;
        sNextTag     := aAO_Channels[nCurrentChannel + 1].sTag;
    ELSE
        sNextAddress := '';
        sNextTag     := '(last channel)';
    END_IF

    // Select timer preset based on phase
    CASE ePhase OF
        E_AOPhase.RAMP_UP, E_AOPhase.RAMP_DOWN:
            tCurrentPT := GVL_IOWalkTest.C_AO_RAMP_TIME;
        E_AOPhase.PAUSE:
            tCurrentPT := GVL_IOWalkTest.C_AO_PAUSE_TIME;
    END_CASE

    fbRampTimer(IN := TRUE, PT := tCurrentPT);
    rProgress := TIME_TO_REAL(fbRampTimer.ET) / TIME_TO_REAL(tCurrentPT);
    IF rProgress > 1.0 THEN rProgress := 1.0; END_IF
    rRampProgress := rProgress;

    CASE ePhase OF
    E_AOPhase.RAMP_UP:
        // 4mA -> 20mA (raw 0 -> 32767)
        nOutputRaw := REAL_TO_INT(rProgress * 32767.0);
        IF aAO_Channels[nCurrentChannel].pOutput <> 0 THEN
            aAO_Channels[nCurrentChannel].pOutput^ := nOutputRaw;
        END_IF
        rCurrentOutput_mA := 4.0 + (rProgress * 16.0);

        IF fbRampTimer.Q THEN
            fbRampTimer(IN := FALSE);
            ePhase := E_AOPhase.RAMP_DOWN;
        END_IF

    E_AOPhase.RAMP_DOWN:
        // 20mA -> 4mA (raw 32767 -> 0)
        nOutputRaw := REAL_TO_INT((1.0 - rProgress) * 32767.0);
        IF aAO_Channels[nCurrentChannel].pOutput <> 0 THEN
            aAO_Channels[nCurrentChannel].pOutput^ := nOutputRaw;
        END_IF
        rCurrentOutput_mA := 4.0 + ((1.0 - rProgress) * 16.0);

        IF fbRampTimer.Q THEN
            IF aAO_Channels[nCurrentChannel].pOutput <> 0 THEN
                aAO_Channels[nCurrentChannel].pOutput^ := 0;
            END_IF
            fbRampTimer(IN := FALSE);
            ePhase := E_AOPhase.PAUSE;
        END_IF

    E_AOPhase.PAUSE:
        // Pause between channels
        IF aAO_Channels[nCurrentChannel].pOutput <> 0 THEN
            aAO_Channels[nCurrentChannel].pOutput^ := 0;
        END_IF
        rCurrentOutput_mA := 4.0;

        IF fbRampTimer.Q THEN
            // Record result
            IF bChannelMarkedFail THEN
                aResults[nCurrentChannel] := E_TestResult.FAILED;
                nFailed := nFailed + 1;
            ELSE
                aResults[nCurrentChannel] := E_TestResult.PASSED;
                nPassed := nPassed + 1;
            END_IF

            bChannelMarkedFail := FALSE;
            fbRampTimer(IN := FALSE);
            ePhase := E_AOPhase.RAMP_UP;
            nCurrentChannel := nCurrentChannel + 1;

            IF bRetestOnly THEN
                WHILE nCurrentChannel < nTotalChannels
                      AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
                    nCurrentChannel := nCurrentChannel + 1;
                END_WHILE
            END_IF

            IF nCurrentChannel >= nTotalChannels THEN
                FOR i := 0 TO 11 DO
                    IF aAO_Channels[i].pOutput <> 0 THEN
                        aAO_Channels[i].pOutput^ := 0;
                    END_IF
                END_FOR
                eState := E_TestState.COMPLETE;
            END_IF
        END_IF
    END_CASE
END_IF
