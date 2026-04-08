TYPE ST_AIChannel :
STRUCT
    sAddress     : STRING(15);      // e.g. '%IW0'
    sTag         : STRING(40);      // e.g. 'hwAI_LubeOilPressure'
    sDescription : STRING(80);
    rRangeLow    : REAL;            // Engineering unit low (e.g. 0.0)
    rRangeHigh   : REAL;            // Engineering unit high (e.g. 10.0)
    sUnit        : STRING(15);      // e.g. 'bar', 'degC'
    pInput       : POINTER TO INT;  // Pointer to hardware input word
END_STRUCT
END_TYPE
