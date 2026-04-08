PROGRAM PRG_IOWalkTest
VAR
    fbDITest    : FB_DITest;
    fbDOTest    : FB_DOTest;
    fbAITest    : FB_AITest;
    fbAOTest    : FB_AOTest;

    bAutoAllActive  : BOOL;
    nAutoAllStep    : INT;      // 0=idle, 1=DI, 2=DO, 3=AI(waiting continue between passes), 4=AO
    bAutoAllStartPrev : BOOL;

    // Internal edge detection for auto-all sequencing
    bDI_WasRunning  : BOOL;
    bDO_WasRunning  : BOOL;
    bAI_WasRunning  : BOOL;
    bAO_WasRunning  : BOOL;

    i : INT;
END_VAR

// ============================================================
// STOP / ALL OFF — top priority
// ============================================================
IF GVL_IOWalkTest.bStopAllOff THEN
    fbDITest(bStop := TRUE);
    fbDOTest(bStop := TRUE);
    fbAITest(bStop := TRUE);
    fbAOTest(bStop := TRUE);
    bAutoAllActive := FALSE;
    nAutoAllStep := 0;
    GVL_IOWalkTest.eOverallState := E_TestState.ABORTED;
    GVL_IOWalkTest.bStopAllOff := FALSE;
    RETURN;
END_IF

// ============================================================
// Individual test start commands from HMI
// ============================================================
IF GVL_IOWalkTest.bStartDITest THEN
    bAutoAllActive := FALSE;
    nAutoAllStep := 0;
    fbDITest(bStart := TRUE);
    GVL_IOWalkTest.bStartDITest := FALSE;
END_IF

IF GVL_IOWalkTest.bStartDOTest THEN
    bAutoAllActive := FALSE;
    nAutoAllStep := 0;
    fbDOTest(bStart := TRUE);
    GVL_IOWalkTest.bStartDOTest := FALSE;
END_IF

IF GVL_IOWalkTest.bStartAITest THEN
    bAutoAllActive := FALSE;
    nAutoAllStep := 0;
    fbAITest(bStart := TRUE);
    GVL_IOWalkTest.bStartAITest := FALSE;
END_IF

IF GVL_IOWalkTest.bStartAOTest THEN
    bAutoAllActive := FALSE;
    nAutoAllStep := 0;
    fbAOTest(bStart := TRUE);
    GVL_IOWalkTest.bStartAOTest := FALSE;
END_IF

// ============================================================
// AUTO ALL sequence
// ============================================================
IF GVL_IOWalkTest.bStartAutoAll AND NOT bAutoAllStartPrev THEN
    bAutoAllActive := TRUE;
    nAutoAllStep := 1;
    GVL_IOWalkTest.eOverallState := E_TestState.RUNNING;
    fbDITest(bStart := TRUE);
    GVL_IOWalkTest.bStartAutoAll := FALSE;
END_IF
bAutoAllStartPrev := GVL_IOWalkTest.bStartAutoAll;

IF bAutoAllActive THEN
    CASE nAutoAllStep OF
    1: // DI Test running
        IF fbDITest.eState = E_TestState.COMPLETE OR fbDITest.eState = E_TestState.ABORTED THEN
            nAutoAllStep := 2;
            fbDOTest(bStart := TRUE);
        END_IF

    2: // DO Test running
        IF fbDOTest.eState = E_TestState.COMPLETE OR fbDOTest.eState = E_TestState.ABORTED THEN
            nAutoAllStep := 3;
            fbAITest(bStart := TRUE);
        END_IF

    3: // AI Test running (handles its own WAIT_CONTINUE between passes)
        IF fbAITest.eState = E_TestState.COMPLETE OR fbAITest.eState = E_TestState.ABORTED THEN
            nAutoAllStep := 4;
            fbAOTest(bStart := TRUE);
        END_IF

    4: // AO Test running
        IF fbAOTest.eState = E_TestState.COMPLETE OR fbAOTest.eState = E_TestState.ABORTED THEN
            nAutoAllStep := 0;
            bAutoAllActive := FALSE;
            GVL_IOWalkTest.eOverallState := E_TestState.COMPLETE;
        END_IF
    END_CASE

    GVL_IOWalkTest.nAutoAllStep := nAutoAllStep;
END_IF

// ============================================================
// Retest failed channels
// ============================================================
IF GVL_IOWalkTest.bRetestFailed THEN
    fbDITest(bStart := TRUE, bRetestOnly := TRUE);
    fbDOTest(bStart := TRUE, bRetestOnly := TRUE);
    fbAITest(bStart := TRUE, bRetestOnly := TRUE);
    fbAOTest(bStart := TRUE, bRetestOnly := TRUE);
    GVL_IOWalkTest.bRetestFailed := FALSE;
END_IF

// ============================================================
// Pass through HMI commands to active FBs
// ============================================================
fbDITest(
    bStop   := FALSE,
    bSkip   := GVL_IOWalkTest.bSkipChannel
);

fbDOTest(
    bStop     := FALSE,
    bSkip     := GVL_IOWalkTest.bSkipChannel,
    bPause    := GVL_IOWalkTest.bPause,
    bMarkFail := GVL_IOWalkTest.bMarkFail
);

fbAITest(
    bStop           := FALSE,
    bSkip           := GVL_IOWalkTest.bSkipChannel,
    bContinue       := GVL_IOWalkTest.bContinue,
    bStartWireBreak := GVL_IOWalkTest.bStartWireBreak
);

fbAOTest(
    bStop     := FALSE,
    bSkip     := GVL_IOWalkTest.bSkipChannel,
    bPause    := GVL_IOWalkTest.bPause,
    bMarkFail := GVL_IOWalkTest.bMarkFail
);

// Clear one-shot HMI commands
GVL_IOWalkTest.bSkipChannel  := FALSE;
GVL_IOWalkTest.bMarkFail     := FALSE;
GVL_IOWalkTest.bContinue     := FALSE;
GVL_IOWalkTest.bPause        := FALSE;
GVL_IOWalkTest.bStartWireBreak := FALSE;

// ============================================================
// Update summary counters for HMI
// ============================================================
GVL_IOWalkTest.nDI_Passed  := fbDITest.nPassed;
GVL_IOWalkTest.nDI_Failed  := fbDITest.nFailed;
GVL_IOWalkTest.nDI_Skipped := fbDITest.nSkipped;

GVL_IOWalkTest.nDO_Passed  := fbDOTest.nPassed;
GVL_IOWalkTest.nDO_Failed  := fbDOTest.nFailed;
GVL_IOWalkTest.nDO_Skipped := fbDOTest.nSkipped;

GVL_IOWalkTest.nAI_Passed  := fbAITest.nPassed;
GVL_IOWalkTest.nAI_Failed  := fbAITest.nFailed;

GVL_IOWalkTest.nAO_Passed  := fbAOTest.nPassed;
GVL_IOWalkTest.nAO_Failed  := fbAOTest.nFailed;
GVL_IOWalkTest.nAO_Skipped := fbAOTest.nSkipped;

GVL_IOWalkTest.bALM_DI_Timeout      := fbDITest.bAlmTimeout;
GVL_IOWalkTest.bALM_DI_WrongChannel := fbDITest.bAlmWrongChan;
GVL_IOWalkTest.nWrongChannelIndex   := fbDITest.nWrongChanIdx;
GVL_IOWalkTest.bALM_AI_Timeout      := fbAITest.bAlmTimeout;
