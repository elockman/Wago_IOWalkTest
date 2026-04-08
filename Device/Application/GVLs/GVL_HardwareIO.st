{attribute 'qualified_only'}
VAR_GLOBAL
    // ============================================================
    // Digital Inputs — 9 modules x 8 channels = 72 channels
    // Modules: 750-1415 (8DI 24VDC)
    // ============================================================
    hwDI_00 AT %IX0.0 : BOOL;  // DI Module 1, Ch 0
    hwDI_01 AT %IX0.1 : BOOL;  // DI Module 1, Ch 1
    hwDI_02 AT %IX0.2 : BOOL;  // DI Module 1, Ch 2
    hwDI_03 AT %IX0.3 : BOOL;  // DI Module 1, Ch 3
    hwDI_04 AT %IX0.4 : BOOL;  // DI Module 1, Ch 4
    hwDI_05 AT %IX0.5 : BOOL;  // DI Module 1, Ch 5
    hwDI_06 AT %IX0.6 : BOOL;  // DI Module 1, Ch 6
    hwDI_07 AT %IX0.7 : BOOL;  // DI Module 1, Ch 7

    hwDI_08 AT %IX1.0 : BOOL;  // DI Module 2, Ch 0
    hwDI_09 AT %IX1.1 : BOOL;  // DI Module 2, Ch 1
    hwDI_10 AT %IX1.2 : BOOL;  // DI Module 2, Ch 2
    hwDI_11 AT %IX1.3 : BOOL;  // DI Module 2, Ch 3
    hwDI_12 AT %IX1.4 : BOOL;  // DI Module 2, Ch 4
    hwDI_13 AT %IX1.5 : BOOL;  // DI Module 2, Ch 5
    hwDI_14 AT %IX1.6 : BOOL;  // DI Module 2, Ch 6
    hwDI_15 AT %IX1.7 : BOOL;  // DI Module 2, Ch 7

    hwDI_16 AT %IX2.0 : BOOL;  // DI Module 3, Ch 0
    hwDI_17 AT %IX2.1 : BOOL;  // DI Module 3, Ch 1
    hwDI_18 AT %IX2.2 : BOOL;  // DI Module 3, Ch 2
    hwDI_19 AT %IX2.3 : BOOL;  // DI Module 3, Ch 3
    hwDI_20 AT %IX2.4 : BOOL;  // DI Module 3, Ch 4
    hwDI_21 AT %IX2.5 : BOOL;  // DI Module 3, Ch 5
    hwDI_22 AT %IX2.6 : BOOL;  // DI Module 3, Ch 6
    hwDI_23 AT %IX2.7 : BOOL;  // DI Module 3, Ch 7

    hwDI_24 AT %IX3.0 : BOOL;  // DI Module 4, Ch 0
    hwDI_25 AT %IX3.1 : BOOL;  // DI Module 4, Ch 1
    hwDI_26 AT %IX3.2 : BOOL;  // DI Module 4, Ch 2
    hwDI_27 AT %IX3.3 : BOOL;  // DI Module 4, Ch 3
    hwDI_28 AT %IX3.4 : BOOL;  // DI Module 4, Ch 4
    hwDI_29 AT %IX3.5 : BOOL;  // DI Module 4, Ch 5
    hwDI_30 AT %IX3.6 : BOOL;  // DI Module 4, Ch 6
    hwDI_31 AT %IX3.7 : BOOL;  // DI Module 4, Ch 7

    hwDI_32 AT %IX4.0 : BOOL;  // DI Module 5, Ch 0
    hwDI_33 AT %IX4.1 : BOOL;  // DI Module 5, Ch 1
    hwDI_34 AT %IX4.2 : BOOL;  // DI Module 5, Ch 2
    hwDI_35 AT %IX4.3 : BOOL;  // DI Module 5, Ch 3
    hwDI_36 AT %IX4.4 : BOOL;  // DI Module 5, Ch 4
    hwDI_37 AT %IX4.5 : BOOL;  // DI Module 5, Ch 5
    hwDI_38 AT %IX4.6 : BOOL;  // DI Module 5, Ch 6
    hwDI_39 AT %IX4.7 : BOOL;  // DI Module 5, Ch 7

    hwDI_40 AT %IX5.0 : BOOL;  // DI Module 6, Ch 0
    hwDI_41 AT %IX5.1 : BOOL;  // DI Module 6, Ch 1
    hwDI_42 AT %IX5.2 : BOOL;  // DI Module 6, Ch 2
    hwDI_43 AT %IX5.3 : BOOL;  // DI Module 6, Ch 3
    hwDI_44 AT %IX5.4 : BOOL;  // DI Module 6, Ch 4
    hwDI_45 AT %IX5.5 : BOOL;  // DI Module 6, Ch 5
    hwDI_46 AT %IX5.6 : BOOL;  // DI Module 6, Ch 6
    hwDI_47 AT %IX5.7 : BOOL;  // DI Module 6, Ch 7

    hwDI_48 AT %IX6.0 : BOOL;  // DI Module 7, Ch 0
    hwDI_49 AT %IX6.1 : BOOL;  // DI Module 7, Ch 1
    hwDI_50 AT %IX6.2 : BOOL;  // DI Module 7, Ch 2
    hwDI_51 AT %IX6.3 : BOOL;  // DI Module 7, Ch 3
    hwDI_52 AT %IX6.4 : BOOL;  // DI Module 7, Ch 4
    hwDI_53 AT %IX6.5 : BOOL;  // DI Module 7, Ch 5
    hwDI_54 AT %IX6.6 : BOOL;  // DI Module 7, Ch 6
    hwDI_55 AT %IX6.7 : BOOL;  // DI Module 7, Ch 7

    hwDI_56 AT %IX7.0 : BOOL;  // DI Module 8, Ch 0
    hwDI_57 AT %IX7.1 : BOOL;  // DI Module 8, Ch 1
    hwDI_58 AT %IX7.2 : BOOL;  // DI Module 8, Ch 2
    hwDI_59 AT %IX7.3 : BOOL;  // DI Module 8, Ch 3
    hwDI_60 AT %IX7.4 : BOOL;  // DI Module 8, Ch 4
    hwDI_61 AT %IX7.5 : BOOL;  // DI Module 8, Ch 5
    hwDI_62 AT %IX7.6 : BOOL;  // DI Module 8, Ch 6
    hwDI_63 AT %IX7.7 : BOOL;  // DI Module 8, Ch 7

    hwDI_64 AT %IX8.0 : BOOL;  // DI Module 9 (Spare), Ch 0
    hwDI_65 AT %IX8.1 : BOOL;  // DI Module 9 (Spare), Ch 1
    hwDI_66 AT %IX8.2 : BOOL;  // DI Module 9 (Spare), Ch 2
    hwDI_67 AT %IX8.3 : BOOL;  // DI Module 9 (Spare), Ch 3
    hwDI_68 AT %IX8.4 : BOOL;  // DI Module 9 (Spare), Ch 4
    hwDI_69 AT %IX8.5 : BOOL;  // DI Module 9 (Spare), Ch 5
    hwDI_70 AT %IX8.6 : BOOL;  // DI Module 9 (Spare), Ch 6
    hwDI_71 AT %IX8.7 : BOOL;  // DI Module 9 (Spare), Ch 7

    // ============================================================
    // Digital Outputs — 7 modules x 8 channels = 56 channels
    // Modules: 750-1504 (8DO 24VDC)
    // ============================================================
    hwDO_00 AT %QX0.0 : BOOL;  // DO Module 1, Ch 0
    hwDO_01 AT %QX0.1 : BOOL;  // DO Module 1, Ch 1
    hwDO_02 AT %QX0.2 : BOOL;  // DO Module 1, Ch 2
    hwDO_03 AT %QX0.3 : BOOL;  // DO Module 1, Ch 3
    hwDO_04 AT %QX0.4 : BOOL;  // DO Module 1, Ch 4
    hwDO_05 AT %QX0.5 : BOOL;  // DO Module 1, Ch 5
    hwDO_06 AT %QX0.6 : BOOL;  // DO Module 1, Ch 6
    hwDO_07 AT %QX0.7 : BOOL;  // DO Module 1, Ch 7

    hwDO_08 AT %QX1.0 : BOOL;  // DO Module 2, Ch 0
    hwDO_09 AT %QX1.1 : BOOL;  // DO Module 2, Ch 1
    hwDO_10 AT %QX1.2 : BOOL;  // DO Module 2, Ch 2
    hwDO_11 AT %QX1.3 : BOOL;  // DO Module 2, Ch 3
    hwDO_12 AT %QX1.4 : BOOL;  // DO Module 2, Ch 4
    hwDO_13 AT %QX1.5 : BOOL;  // DO Module 2, Ch 5
    hwDO_14 AT %QX1.6 : BOOL;  // DO Module 2, Ch 6
    hwDO_15 AT %QX1.7 : BOOL;  // DO Module 2, Ch 7

    hwDO_16 AT %QX2.0 : BOOL;  // DO Module 3, Ch 0
    hwDO_17 AT %QX2.1 : BOOL;  // DO Module 3, Ch 1
    hwDO_18 AT %QX2.2 : BOOL;  // DO Module 3, Ch 2
    hwDO_19 AT %QX2.3 : BOOL;  // DO Module 3, Ch 3
    hwDO_20 AT %QX2.4 : BOOL;  // DO Module 3, Ch 4
    hwDO_21 AT %QX2.5 : BOOL;  // DO Module 3, Ch 5
    hwDO_22 AT %QX2.6 : BOOL;  // DO Module 3, Ch 6
    hwDO_23 AT %QX2.7 : BOOL;  // DO Module 3, Ch 7

    hwDO_24 AT %QX3.0 : BOOL;  // DO Module 4, Ch 0
    hwDO_25 AT %QX3.1 : BOOL;  // DO Module 4, Ch 1
    hwDO_26 AT %QX3.2 : BOOL;  // DO Module 4, Ch 2
    hwDO_27 AT %QX3.3 : BOOL;  // DO Module 4, Ch 3
    hwDO_28 AT %QX3.4 : BOOL;  // DO Module 4, Ch 4
    hwDO_29 AT %QX3.5 : BOOL;  // DO Module 4, Ch 5
    hwDO_30 AT %QX3.6 : BOOL;  // DO Module 4, Ch 6
    hwDO_31 AT %QX3.7 : BOOL;  // DO Module 4, Ch 7

    hwDO_32 AT %QX4.0 : BOOL;  // DO Module 5, Ch 0
    hwDO_33 AT %QX4.1 : BOOL;  // DO Module 5, Ch 1
    hwDO_34 AT %QX4.2 : BOOL;  // DO Module 5, Ch 2
    hwDO_35 AT %QX4.3 : BOOL;  // DO Module 5, Ch 3
    hwDO_36 AT %QX4.4 : BOOL;  // DO Module 5, Ch 4
    hwDO_37 AT %QX4.5 : BOOL;  // DO Module 5, Ch 5
    hwDO_38 AT %QX4.6 : BOOL;  // DO Module 5, Ch 6
    hwDO_39 AT %QX4.7 : BOOL;  // DO Module 5, Ch 7

    hwDO_40 AT %QX5.0 : BOOL;  // DO Module 6, Ch 0
    hwDO_41 AT %QX5.1 : BOOL;  // DO Module 6, Ch 1
    hwDO_42 AT %QX5.2 : BOOL;  // DO Module 6, Ch 2
    hwDO_43 AT %QX5.3 : BOOL;  // DO Module 6, Ch 3
    hwDO_44 AT %QX5.4 : BOOL;  // DO Module 6, Ch 4
    hwDO_45 AT %QX5.5 : BOOL;  // DO Module 6, Ch 5
    hwDO_46 AT %QX5.6 : BOOL;  // DO Module 6, Ch 6
    hwDO_47 AT %QX5.7 : BOOL;  // DO Module 6, Ch 7

    hwDO_48 AT %QX6.0 : BOOL;  // DO Module 7 (Spare), Ch 0
    hwDO_49 AT %QX6.1 : BOOL;  // DO Module 7 (Spare), Ch 1
    hwDO_50 AT %QX6.2 : BOOL;  // DO Module 7 (Spare), Ch 2
    hwDO_51 AT %QX6.3 : BOOL;  // DO Module 7 (Spare), Ch 3
    hwDO_52 AT %QX6.4 : BOOL;  // DO Module 7 (Spare), Ch 4
    hwDO_53 AT %QX6.5 : BOOL;  // DO Module 7 (Spare), Ch 5
    hwDO_54 AT %QX6.6 : BOOL;  // DO Module 7 (Spare), Ch 6
    hwDO_55 AT %QX6.7 : BOOL;  // DO Module 7 (Spare), Ch 7

    // ============================================================
    // Analog Inputs — 8 modules x 4 channels = 32 channels
    // Modules: 750-0469 (4AI 4-20mA)
    // Address stride: 2 words per channel
    // ============================================================
    hwAI_00 AT %IW0  : INT;    // AI Module 1, Ch 0
    hwAI_01 AT %IW2  : INT;    // AI Module 1, Ch 1
    hwAI_02 AT %IW4  : INT;    // AI Module 1, Ch 2
    hwAI_03 AT %IW6  : INT;    // AI Module 1, Ch 3

    hwAI_04 AT %IW8  : INT;    // AI Module 2, Ch 0
    hwAI_05 AT %IW10 : INT;    // AI Module 2, Ch 1
    hwAI_06 AT %IW12 : INT;    // AI Module 2, Ch 2
    hwAI_07 AT %IW14 : INT;    // AI Module 2, Ch 3

    hwAI_08 AT %IW16 : INT;    // AI Module 3, Ch 0
    hwAI_09 AT %IW18 : INT;    // AI Module 3, Ch 1
    hwAI_10 AT %IW20 : INT;    // AI Module 3, Ch 2
    hwAI_11 AT %IW22 : INT;    // AI Module 3, Ch 3

    hwAI_12 AT %IW24 : INT;    // AI Module 4, Ch 0
    hwAI_13 AT %IW26 : INT;    // AI Module 4, Ch 1
    hwAI_14 AT %IW28 : INT;    // AI Module 4, Ch 2
    hwAI_15 AT %IW30 : INT;    // AI Module 4, Ch 3

    hwAI_16 AT %IW32 : INT;    // AI Module 5, Ch 0
    hwAI_17 AT %IW34 : INT;    // AI Module 5, Ch 1
    hwAI_18 AT %IW36 : INT;    // AI Module 5, Ch 2
    hwAI_19 AT %IW38 : INT;    // AI Module 5, Ch 3

    hwAI_20 AT %IW40 : INT;    // AI Module 6, Ch 0
    hwAI_21 AT %IW42 : INT;    // AI Module 6, Ch 1
    hwAI_22 AT %IW44 : INT;    // AI Module 6, Ch 2
    hwAI_23 AT %IW46 : INT;    // AI Module 6, Ch 3

    hwAI_24 AT %IW48 : INT;    // AI Module 7, Ch 0
    hwAI_25 AT %IW50 : INT;    // AI Module 7, Ch 1
    hwAI_26 AT %IW52 : INT;    // AI Module 7, Ch 2
    hwAI_27 AT %IW54 : INT;    // AI Module 7, Ch 3

    hwAI_28 AT %IW56 : INT;    // AI Module 8 (Spare), Ch 0
    hwAI_29 AT %IW58 : INT;    // AI Module 8 (Spare), Ch 1
    hwAI_30 AT %IW60 : INT;    // AI Module 8 (Spare), Ch 2
    hwAI_31 AT %IW62 : INT;    // AI Module 8 (Spare), Ch 3

    // ============================================================
    // Analog Outputs — 3 modules x 4 channels = 12 channels
    // Modules: 750-0552 (4AO 4-20mA)
    // Address stride: 2 words per channel
    // ============================================================
    hwAO_00 AT %QW0  : INT;    // AO Module 1, Ch 0
    hwAO_01 AT %QW2  : INT;    // AO Module 1, Ch 1
    hwAO_02 AT %QW4  : INT;    // AO Module 1, Ch 2
    hwAO_03 AT %QW6  : INT;    // AO Module 1, Ch 3

    hwAO_04 AT %QW8  : INT;    // AO Module 2, Ch 0
    hwAO_05 AT %QW10 : INT;    // AO Module 2, Ch 1
    hwAO_06 AT %QW12 : INT;    // AO Module 2, Ch 2
    hwAO_07 AT %QW14 : INT;    // AO Module 2, Ch 3

    hwAO_08 AT %QW16 : INT;    // AO Module 3 (Spare), Ch 0
    hwAO_09 AT %QW18 : INT;    // AO Module 3 (Spare), Ch 1
    hwAO_10 AT %QW20 : INT;    // AO Module 3 (Spare), Ch 2
    hwAO_11 AT %QW22 : INT;    // AO Module 3 (Spare), Ch 3
END_VAR
