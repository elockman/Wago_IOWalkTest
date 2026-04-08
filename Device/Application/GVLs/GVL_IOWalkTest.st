{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    C_NUM_DI        : INT := 72;
    C_NUM_DO        : INT := 56;
    C_NUM_AI        : INT := 32;
    C_NUM_AO        : INT := 12;
    C_NUM_AI_PASSES : INT := 3;

    // AI expected raw values per pass (4mA, 12mA, 20mA)
    C_AI_EXPECTED_RAW : ARRAY[1..3] OF INT := [3277, 16384, 32767];

    // Tolerances
    C_AI_RAW_TOLERANCE : INT  := 500;     // +/- raw counts
    C_AI_ERROR_PCT_MAX : REAL := 1.0;     // Max scaled error %
    C_AI_WIREBREAK_MAX : INT  := 500;     // Max raw for wire break detection

    // Timing
    C_DI_TIMEOUT       : TIME := T#30s;
    C_AI_TIMEOUT       : TIME := T#30s;
    C_AI_SETTLE_TIME   : TIME := T#500ms;
    C_DO_DWELL_TIME    : TIME := T#3s;
    C_AO_RAMP_TIME     : TIME := T#3s;
    C_AO_PAUSE_TIME    : TIME := T#2s;
END_VAR

VAR_GLOBAL
    // HMI command interface
    bStartDITest     : BOOL;
    bStartDOTest     : BOOL;
    bStartAITest     : BOOL;
    bStartAOTest     : BOOL;
    bStartAutoAll    : BOOL;
    bContinue        : BOOL;    // Operator continue between AI passes
    bSkipChannel     : BOOL;
    bMarkFail        : BOOL;
    bPause           : BOOL;
    bStopAllOff      : BOOL;
    bStartWireBreak  : BOOL;
    bRetestFailed    : BOOL;

    // Overall status
    eOverallState    : E_TestState;
    nAutoAllStep     : INT;

    // Counters for HMI summary
    nDI_Passed       : INT;
    nDI_Failed       : INT;
    nDI_Skipped      : INT;
    nDO_Passed       : INT;
    nDO_Failed       : INT;
    nDO_Skipped      : INT;
    nAI_Passed       : INT;
    nAI_Failed       : INT;
    nAO_Passed       : INT;
    nAO_Failed       : INT;
    nAO_Skipped      : INT;

    // HMI display strings
    sCurrentAction   : STRING(120);
    sNextAction      : STRING(120);

    // Alarms
    bALM_DI_Timeout      : BOOL;
    bALM_DI_WrongChannel : BOOL;
    nWrongChannelIndex   : INT;
    bALM_AI_Timeout      : BOOL;
END_VAR
