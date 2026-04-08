FUNCTION_BLOCK FB_DITest
VAR_INPUT
    bStart          : BOOL;
    bStop           : BOOL;
    bSkip           : BOOL;
    bRetestOnly     : BOOL;     // Only retest channels that previously failed
END_VAR
VAR_OUTPUT
    eState          : E_TestState;
    nCurrentChannel : INT;
    nTotalChannels  : INT := GVL_IOWalkTest.C_NUM_DI;
    aResults        : ARRAY[0..71] OF E_TestResult;
    bWaitingForRise : BOOL;
    bWaitingForFall : BOOL;
    sCurrentAddress : STRING(15);
    sCurrentTag     : STRING(40);
    sCurrentDesc    : STRING(80);
    eCurrentContact : E_ContactType;
    nPassed         : INT;
    nFailed         : INT;
    nSkipped        : INT;
    bAlmTimeout     : BOOL;
    bAlmWrongChan   : BOOL;
    nWrongChanIdx   : INT;
END_VAR
VAR
    fbTimeout       : TON;
    aDI_Prev        : ARRAY[0..71] OF BOOL;
    aDI_Channels    : ARRAY[0..71] OF ST_DIChannel;
    bInitDone       : BOOL;
    bStartPrev      : BOOL;
    bSkipPrev       : BOOL;
    i               : INT;
    bCurrentState   : BOOL;
    bPrevState      : BOOL;
    bExpectRise     : BOOL;     // TRUE = waiting for active edge
    bExpectFall     : BOOL;     // TRUE = waiting for release edge
END_VAR

// One-shot start detection
IF bStart AND NOT bStartPrev THEN
    IF eState = E_TestState.IDLE OR eState = E_TestState.COMPLETE OR eState = E_TestState.ABORTED THEN
        eState := E_TestState.RUNNING;
        nCurrentChannel := 0;
        bAlmTimeout := FALSE;
        bAlmWrongChan := FALSE;
        nPassed := 0;
        nFailed := 0;
        nSkipped := 0;
        fbTimeout(IN := FALSE);

        IF NOT bRetestOnly THEN
            FOR i := 0 TO 71 DO
                aResults[i] := E_TestResult.UNTESTED;
            END_FOR
        END_IF

        // Skip to first untested/failed channel if retest mode
        IF bRetestOnly THEN
            WHILE nCurrentChannel < nTotalChannels
                  AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
                nCurrentChannel := nCurrentChannel + 1;
            END_WHILE
        END_IF

        // Determine initial edge expectations
        IF nCurrentChannel < nTotalChannels THEN
            IF aDI_Channels[nCurrentChannel].eContactType = E_ContactType.NC THEN
                bExpectRise := FALSE;
                bExpectFall := TRUE;    // NC: wait for fall first
            ELSE
                bExpectRise := TRUE;
                bExpectFall := FALSE;   // NO: wait for rise first
            END_IF
        END_IF
    END_IF
END_IF
bStartPrev := bStart;

// Stop
IF bStop THEN
    IF eState = E_TestState.RUNNING THEN
        eState := E_TestState.ABORTED;
        fbTimeout(IN := FALSE);
    END_IF
END_IF

// Skip channel (one-shot)
IF bSkip AND NOT bSkipPrev AND eState = E_TestState.RUNNING THEN
    aResults[nCurrentChannel] := E_TestResult.SKIPPED;
    nSkipped := nSkipped + 1;
    fbTimeout(IN := FALSE);
    nCurrentChannel := nCurrentChannel + 1;

    // Skip already-passed channels in retest mode
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

// Main test logic
IF eState = E_TestState.RUNNING AND nCurrentChannel < nTotalChannels THEN
    // Update HMI display info
    sCurrentAddress := aDI_Channels[nCurrentChannel].sAddress;
    sCurrentTag     := aDI_Channels[nCurrentChannel].sTag;
    sCurrentDesc    := aDI_Channels[nCurrentChannel].sDescription;
    eCurrentContact := aDI_Channels[nCurrentChannel].eContactType;

    // Read current channel state via pointer
    IF aDI_Channels[nCurrentChannel].pInput <> 0 THEN
        bCurrentState := aDI_Channels[nCurrentChannel].pInput^;
    END_IF
    bPrevState := aDI_Prev[nCurrentChannel];

    // Channel timeout
    fbTimeout(IN := TRUE, PT := GVL_IOWalkTest.C_DI_TIMEOUT);

    // Edge detection based on contact type
    // NO contacts: rise then fall
    // NC contacts: fall then rise (inverted)
    IF bExpectRise AND bCurrentState AND NOT bPrevState THEN
        // Rising edge detected
        bExpectRise := FALSE;
        bExpectFall := TRUE;
        fbTimeout(IN := FALSE);
        fbTimeout(IN := TRUE, PT := GVL_IOWalkTest.C_DI_TIMEOUT);
    END_IF

    IF bExpectFall AND NOT bCurrentState AND bPrevState THEN
        // Falling edge detected - channel PASS
        aResults[nCurrentChannel] := E_TestResult.PASSED;
        nPassed := nPassed + 1;
        fbTimeout(IN := FALSE);

        // Advance
        nCurrentChannel := nCurrentChannel + 1;

        // Skip already-passed in retest mode
        IF bRetestOnly THEN
            WHILE nCurrentChannel < nTotalChannels
                  AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
                nCurrentChannel := nCurrentChannel + 1;
            END_WHILE
        END_IF

        IF nCurrentChannel >= nTotalChannels THEN
            eState := E_TestState.COMPLETE;
        ELSE
            // Set up edge expectations for next channel
            IF aDI_Channels[nCurrentChannel].eContactType = E_ContactType.NC THEN
                bExpectRise := FALSE;
                bExpectFall := TRUE;
            ELSE
                bExpectRise := TRUE;
                bExpectFall := FALSE;
            END_IF
            fbTimeout(IN := TRUE, PT := GVL_IOWalkTest.C_DI_TIMEOUT);
        END_IF
    END_IF

    // Check for out-of-order channel activation
    FOR i := 0 TO nTotalChannels - 1 DO
        IF i <> nCurrentChannel AND aDI_Channels[i].pInput <> 0 THEN
            IF aDI_Channels[i].pInput^ AND NOT aDI_Prev[i] THEN
                bAlmWrongChan := TRUE;
                nWrongChanIdx := i;
            END_IF
        END_IF
    END_FOR

    // Timeout handling
    IF fbTimeout.Q THEN
        aResults[nCurrentChannel] := E_TestResult.FAILED;
        nFailed := nFailed + 1;
        bAlmTimeout := TRUE;
        fbTimeout(IN := FALSE);

        nCurrentChannel := nCurrentChannel + 1;
        IF bRetestOnly THEN
            WHILE nCurrentChannel < nTotalChannels
                  AND aResults[nCurrentChannel] = E_TestResult.PASSED DO
                nCurrentChannel := nCurrentChannel + 1;
            END_WHILE
        END_IF

        IF nCurrentChannel >= nTotalChannels THEN
            eState := E_TestState.COMPLETE;
        ELSE
            IF aDI_Channels[nCurrentChannel].eContactType = E_ContactType.NC THEN
                bExpectRise := FALSE;
                bExpectFall := TRUE;
            ELSE
                bExpectRise := TRUE;
                bExpectFall := FALSE;
            END_IF
            fbTimeout(IN := TRUE, PT := GVL_IOWalkTest.C_DI_TIMEOUT);
        END_IF
    END_IF

    // Store previous states for all channels
    FOR i := 0 TO nTotalChannels - 1 DO
        IF aDI_Channels[i].pInput <> 0 THEN
            aDI_Prev[i] := aDI_Channels[i].pInput^;
        END_IF
    END_FOR
END_IF
