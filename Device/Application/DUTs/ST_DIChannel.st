TYPE ST_DIChannel :
STRUCT
    sAddress     : STRING(15);      // e.g. '%IX0.0'
    sTag         : STRING(40);      // e.g. 'hwDI_PumpRunFeedback'
    sDescription : STRING(80);
    eContactType : E_ContactType;   // NO or NC
    pInput       : POINTER TO BOOL; // Pointer to hardware input
END_STRUCT
END_TYPE
