TYPE ST_AOChannel :
STRUCT
    sAddress     : STRING(15);      // e.g. '%QW0'
    sTag         : STRING(40);      // e.g. 'hwAO_SpeedSetpoint'
    sDescription : STRING(80);
    pOutput      : POINTER TO INT;  // Pointer to hardware output word
END_STRUCT
END_TYPE
