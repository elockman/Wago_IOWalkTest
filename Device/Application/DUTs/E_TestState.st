{attribute 'qualified_only'}
TYPE E_TestState :
(
    IDLE        := 0,
    RUNNING     := 1,
    PAUSED      := 2,
    WAIT_CONTINUE := 3,
    COMPLETE    := 4,
    ABORTED     := 5
);
END_TYPE
