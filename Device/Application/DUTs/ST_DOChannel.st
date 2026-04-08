TYPE ST_DOChannel :
STRUCT
    sAddress     : STRING(15);      // e.g. '%QX0.0'
    sTag         : STRING(40);      // e.g. 'hwDO_PumpStart'
    sDescription : STRING(80);
    sNote        : STRING(120);     // Special handling notes
    pOutput      : POINTER TO BOOL; // Pointer to hardware output
END_STRUCT
END_TYPE
