FUNCTION_BLOCK FB_DOTest
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
    nTotalChannels  : INT := GVL_IOWalkTest.C_NUM_DO;
    aResults        : ARRAY[0..55] OF E_TestResult;
    sCurrentAddress : STRING(15);
    sCurrentTag     : STRING(40);
    sCurrentDesc    : STRING(80);
    sCurrentNote    : STRING(120);
    sNextAddress    : STRING(15);
    sNextTag        : STRING(40);
    rSecondsRemain  : REAL;
    nPassed         : INT;
    nFailed         : INT;
    nSkipped        : INT;
END_VAR
VAR
    fbDwell         : TON;
    aDO_Channels    : ARRAY[0..55] OF ST_DOChannel;
    bStartPrev      : BOOL;
    bSkipPrev       : BOOL;
    bMarkFailPrev   : BOOL;
    bChannelMarkedFail : BOOL;
    i               : INT;
END_VAR

// One-shot start
IF bStart AND NOT bStartPrev THEN
    IF eState = E_TestState.IDLE OR eState = E_TestState.COMPLETE OR eState = E_TestState.ABORTED THEN
        eState := E_TestState.RUNNING;
        nCurrentChannel := 0;
        nPassed := 0;
        nFailed := 0;
        nSkipped := 0;
        bChannelMarkedFail := FALSE;
        fbDwell(IN := FALSE);

        IF NOT bRetestOnly THEN
            FOR i := 0 TO 55 DO
                aResults[i] := E_TestResult.UNTESTED;
            END_FOR
        END_IF

        // De-energize all outputs
        FOR i := 0 TO 55 DO
            IF aDO_Channels[i].pOutput <> 0 THEN
                aDO_Channels[i].pOutput^ := FALSE;
            END_IF
        END_FOR

        // Skip passed channels in retest mode
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
    FOR i := 0 TO 55 DO
        IF aDO_Channels[i].pOutput <> 0 THEN
            aDO_Channels[i].pOutput^ := FALSE;
        END_IF
    END_FOR
    IF eState = E_TestState.RUNNING OR eState = E_TestState.PAUSED THEN
        eState := E_TestState.ABORTED;
        fbDwell(IN := FALSE);
    END_IF
END_IF

// Pause toggle
IF bPause AND eState = E_TestState.RUNNING THEN
    eState := E_TestState.PAUSED;
ELSIF bPause AND eState = E_TestState.PAUSED THEN
    eState := E_TestState.RUNNING;
END_IF

// Skip channel (one-shot)
IF bSkip AND NOT bSkipPrev AND (eState = E_TestState.RUNNING OR eState = E_TestState.PAUSED) THEN
    IF aDO_Channels[nCurrentChannel].pOutput <> 0 THEN
        aDO_Channels[nCurrentChannel].pOutput^ := FALSE;
    END_IF
    aResults[nCurrentChannel] := E_TestResult.SKIPPED;
    nSkipped := nSkipped + 1;
    fbDwell(IN := FALSE);
    bChannelMarkedFail := FALSE;
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

// Main sequencing logic
IF eState = E_TestState.RUNNING AND nCurrentChannel < nTotalChannels THEN
    // Update HMI info
    sCurrentAddress := aDO_Channels[nCurrentChannel].sAddress;
    sCurrentTag     := aDO_Channels[nCurrentChannel].sTag;
    sCurrentDesc    := aDO_Channels[nCurrentChannel].sDescription;
    sCurrentNote    := aDO_Channels[nCurrentChannel].sNote;

    IF nCurrentChannel + 1 < nTotalChannels THEN
        sNextAddress := aDO_Channels[nCurrentChannel + 1].sAddress;
        sNextTag     := aDO_Channels[nCurrentChannel + 1].sTag;
    ELSE
        sNextAddress := '';
        sNextTag     := '(last channel)';
    END_IF

    // Energize current channel
    IF aDO_Channels[nCurrentChannel].pOutput <> 0 THEN
        aDO_Channels[nCurrentChannel].pOutput^ := TRUE;
    END_IF

    // Dwell timer
    fbDwell(IN := TRUE, PT := GVL_IOWalkTest.C_DO_DWELL_TIME);
    rSecondsRemain := TIME_TO_REAL(GVL_IOWalkTest.C_DO_DWELL_TIME - fbDwell.ET) / 1000.0;

    IF fbDwell.Q THEN
        // De-energize
        IF aDO_Channels[nCurrentChannel].pOutput <> 0 THEN
            aDO_Channels[nCurrentChannel].pOutput^ := FALSE;
        END_IF

        // Record result
        IF bChannelMarkedFail THEN
            aResults[nCurrentChannel] := E_TestResult.FAILED;
            nFailed := nFailed + 1;
        ELSE
            aResults[nCurrentChannel] := E_TestResult.PASSED;
            nPassed := nPassed + 1;
        END_IF

        bChannelMarkedFail := FALSE;
        fbDwell(IN := FALSE);
        nCurrentChannel := nCurrentChannel + 1;

        IF bRetestOnly THEN
            WHILE nCurrentChannel < nTotalChannels
                  AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
                nCurrentChannel := nCurrentChannel + 1;
            END_WHILE
        END_IF

        IF nCurrentChannel >= nTotalChannels THEN
            // De-energize all
            FOR i := 0 TO 55 DO
                IF aDO_Channels[i].pOutput <> 0 THEN
                    aDO_Channels[i].pOutput^ := FALSE;
                END_IF
            END_FOR
            eState := E_TestState.COMPLETE;
        END_IF
    END_IF
END_IF
