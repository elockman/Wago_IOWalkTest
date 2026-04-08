FUNCTION_BLOCK FB_AITest
VAR_INPUT
    bStart          : BOOL;
    bStop           : BOOL;
    bSkip           : BOOL;
    bContinue       : BOOL;        // Operator presses between passes
    bStartWireBreak : BOOL;        // Start optional wire break pass
    bRetestOnly     : BOOL;
END_VAR
VAR_OUTPUT
    eState          : E_TestState;
    nCurrentChannel : INT;
    nCurrentPass    : INT;         // 1=4mA, 2=12mA, 3=20mA, 4=wirebreak
    nTotalChannels  : INT := GVL_IOWalkTest.C_NUM_AI;
    aReadings       : ARRAY[0..31, 1..3] OF INT;
    aResults        : ARRAY[0..31, 1..4] OF E_TestResult;  // 4th = wire break
    sCurrentAddress : STRING(15);
    sCurrentTag     : STRING(40);
    sCurrentDesc    : STRING(80);
    sCurrentUnit    : STRING(15);
    nCurrentRaw     : INT;
    nExpectedRaw    : INT;
    rCurrentScaled  : REAL;
    rExpectedScaled : REAL;
    rErrorPct       : REAL;
    rMaxErrorPct    : REAL;
    bSignalDetected : BOOL;
    bSettling       : BOOL;
    nPassed         : INT;
    nFailed         : INT;
    bAlmTimeout     : BOOL;
    bWireBreakDone  : BOOL;
END_VAR
VAR
    fbSettle        : TON;
    fbTimeout       : TON;
    aAI_Channels    : ARRAY[0..31] OF ST_AIChannel;
    bStartPrev      : BOOL;
    bSkipPrev       : BOOL;
    bContinuePrev   : BOOL;
    bWireBreakPrev  : BOOL;
    i               : INT;
    nRaw            : INT;
    bInWindow       : BOOL;
    rScaledActual   : REAL;
    rScaledExpected : REAL;
    rSpan           : REAL;
    rErr            : REAL;
END_VAR

// One-shot start
IF bStart AND NOT bStartPrev THEN
    IF eState = E_TestState.IDLE OR eState = E_TestState.COMPLETE OR eState = E_TestState.ABORTED THEN
        eState := E_TestState.RUNNING;
        nCurrentChannel := 0;
        nCurrentPass := 1;
        nPassed := 0;
        nFailed := 0;
        rMaxErrorPct := 0.0;
        bAlmTimeout := FALSE;
        bWireBreakDone := FALSE;
        fbSettle(IN := FALSE);
        fbTimeout(IN := FALSE);

        IF NOT bRetestOnly THEN
            FOR i := 0 TO 31 DO
                aResults[i, 1] := E_TestResult.UNTESTED;
                aResults[i, 2] := E_TestResult.UNTESTED;
                aResults[i, 3] := E_TestResult.UNTESTED;
                aResults[i, 4] := E_TestResult.UNTESTED;
            END_FOR
        END_IF
    END_IF
END_IF
bStartPrev := bStart;

// Stop
IF bStop THEN
    IF eState = E_TestState.RUNNING OR eState = E_TestState.WAIT_CONTINUE THEN
        eState := E_TestState.ABORTED;
        fbSettle(IN := FALSE);
        fbTimeout(IN := FALSE);
    END_IF
END_IF

// Continue between passes (one-shot)
IF bContinue AND NOT bContinuePrev AND eState = E_TestState.WAIT_CONTINUE THEN
    eState := E_TestState.RUNNING;
    fbTimeout(IN := FALSE);
END_IF
bContinuePrev := bContinue;

// Skip channel (one-shot)
IF bSkip AND NOT bSkipPrev AND eState = E_TestState.RUNNING THEN
    aResults[nCurrentChannel, nCurrentPass] := E_TestResult.SKIPPED;
    fbSettle(IN := FALSE);
    fbTimeout(IN := FALSE);
    nCurrentChannel := nCurrentChannel + 1;

    IF nCurrentChannel >= nTotalChannels THEN
        IF nCurrentPass < 3 THEN
            eState := E_TestState.WAIT_CONTINUE;
            nCurrentChannel := 0;
            nCurrentPass := nCurrentPass + 1;
        ELSE
            eState := E_TestState.COMPLETE;
        END_IF
    END_IF
END_IF
bSkipPrev := bSkip;

// Wire break test (one-shot)
IF bStartWireBreak AND NOT bWireBreakPrev THEN
    IF eState = E_TestState.COMPLETE OR eState = E_TestState.IDLE THEN
        nCurrentPass := 4;
        bWireBreakDone := FALSE;

        FOR i := 0 TO nTotalChannels - 1 DO
            IF aAI_Channels[i].pInput <> 0 THEN
                nRaw := aAI_Channels[i].pInput^;
                IF nRaw < GVL_IOWalkTest.C_AI_WIREBREAK_MAX THEN
                    aResults[i, 4] := E_TestResult.PASSED;
                    nPassed := nPassed + 1;
                ELSE
                    aResults[i, 4] := E_TestResult.FAILED;
                    nFailed := nFailed + 1;
                END_IF
            END_IF
        END_FOR

        bWireBreakDone := TRUE;
    END_IF
END_IF
bWireBreakPrev := bStartWireBreak;

// Main test logic (passes 1-3)
IF eState = E_TestState.RUNNING AND nCurrentPass >= 1 AND nCurrentPass <= 3
   AND nCurrentChannel < nTotalChannels THEN

    // Update HMI info
    sCurrentAddress := aAI_Channels[nCurrentChannel].sAddress;
    sCurrentTag     := aAI_Channels[nCurrentChannel].sTag;
    sCurrentDesc    := aAI_Channels[nCurrentChannel].sDescription;
    sCurrentUnit    := aAI_Channels[nCurrentChannel].sUnit;
    nExpectedRaw    := GVL_IOWalkTest.C_AI_EXPECTED_RAW[nCurrentPass];

    // Read current raw value
    IF aAI_Channels[nCurrentChannel].pInput <> 0 THEN
        nCurrentRaw := aAI_Channels[nCurrentChannel].pInput^;
    END_IF

    // Scale for display
    rSpan := aAI_Channels[nCurrentChannel].rRangeHigh - aAI_Channels[nCurrentChannel].rRangeLow;
    IF rSpan > 0.0 THEN
        rCurrentScaled  := aAI_Channels[nCurrentChannel].rRangeLow
                           + (INT_TO_REAL(nCurrentRaw) / 32767.0) * rSpan;
        rExpectedScaled := aAI_Channels[nCurrentChannel].rRangeLow
                           + (INT_TO_REAL(nExpectedRaw) / 32767.0) * rSpan;
    END_IF

    // Channel timeout
    fbTimeout(IN := TRUE, PT := GVL_IOWalkTest.C_AI_TIMEOUT);

    // Check if signal is within expected window
    bInWindow := ABS(nCurrentRaw - nExpectedRaw) < GVL_IOWalkTest.C_AI_RAW_TOLERANCE;
    bSignalDetected := bInWindow;

    IF bInWindow THEN
        // Settle timer
        fbSettle(IN := TRUE, PT := GVL_IOWalkTest.C_AI_SETTLE_TIME);
        bSettling := TRUE;

        IF fbSettle.Q THEN
            // Record reading
            aReadings[nCurrentChannel, nCurrentPass] := nCurrentRaw;

            // Evaluate pass/fail
            rScaledActual   := aAI_Channels[nCurrentChannel].rRangeLow
                               + (INT_TO_REAL(nCurrentRaw) / 32767.0) * rSpan;
            rScaledExpected := aAI_Channels[nCurrentChannel].rRangeLow
                               + (INT_TO_REAL(nExpectedRaw) / 32767.0) * rSpan;

            IF rSpan > 0.0 THEN
                rErr := ABS(rScaledActual - rScaledExpected) / rSpan * 100.0;
            ELSE
                rErr := 0.0;
            END_IF

            rErrorPct := rErr;
            IF rErr > rMaxErrorPct THEN
                rMaxErrorPct := rErr;
            END_IF

            IF rErr < GVL_IOWalkTest.C_AI_ERROR_PCT_MAX THEN
                aResults[nCurrentChannel, nCurrentPass] := E_TestResult.PASSED;
                nPassed := nPassed + 1;
            ELSE
                aResults[nCurrentChannel, nCurrentPass] := E_TestResult.FAILED;
                nFailed := nFailed + 1;
            END_IF

            // Advance
            fbSettle(IN := FALSE);
            fbTimeout(IN := FALSE);
            bSettling := FALSE;
            nCurrentChannel := nCurrentChannel + 1;

            IF nCurrentChannel >= nTotalChannels THEN
                IF nCurrentPass < 3 THEN
                    eState := E_TestState.WAIT_CONTINUE;
                    nCurrentChannel := 0;
                    nCurrentPass := nCurrentPass + 1;
                ELSE
                    eState := E_TestState.COMPLETE;
                END_IF
            END_IF
        END_IF
    ELSE
        fbSettle(IN := FALSE);
        bSettling := FALSE;
    END_IF

    // Timeout
    IF fbTimeout.Q THEN
        aResults[nCurrentChannel, nCurrentPass] := E_TestResult.FAILED;
        nFailed := nFailed + 1;
        bAlmTimeout := TRUE;
        fbSettle(IN := FALSE);
        fbTimeout(IN := FALSE);
        bSettling := FALSE;
        nCurrentChannel := nCurrentChannel + 1;

        IF nCurrentChannel >= nTotalChannels THEN
            IF nCurrentPass < 3 THEN
                eState := E_TestState.WAIT_CONTINUE;
                nCurrentChannel := 0;
                nCurrentPass := nCurrentPass + 1;
            ELSE
                eState := E_TestState.COMPLETE;
            END_IF
        END_IF
    END_IF
END_IF
