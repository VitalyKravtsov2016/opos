unit FREmulator;

{ Fiscal registrar (FR) emulator for acceptance tests.

  This single module contains the whole emulator that used to be split across
  EmulBinUtils, FptrTypes, EmulTables, EmulSerialPort, PrinterEmulator,
  EmulFNState, EmulFECommands, EmulFNCommands, EmulProtocolCommands,
  EmulProtocolServer and FREmulator. }

interface

uses
  Windows, Classes, SysUtils;



function Min(V1, V2: Integer): Integer;
function IntToBin(Value, Count: Int64): AnsiString;
function BinToInt(const S: AnsiString; Index, Count: Integer): Int64;




const
  /////////////////////////////////////////////////////////////////////////////
  // Error codes constants
  /////////////////////////////////////////////////////////////////////////////

  FPTR_E_INVALID_PARAM                           = $33; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜
  FPTR_E_INVALID_PARAM_SETUP                     = $35; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜
  FPTR_E_INVALID_PARAM_REAL                      = $36; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜
  FPTR_E_CMD_NOT_SUPPORT                         = $37; //
  FPTR_E_ROM_FAIL                                = $38; // ˜˜˜˜˜˜ ˜ ˜˜˜
  FPTR_E_INTERNAL_FR_SOFT                        = $39; // ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜ ˜˜
  FPTR_E_SMENA_SUMM_CHARGE                       = $3A; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_EKLZ_INVALID_REG_NUM                    = $3c; // ˜˜˜˜ c ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜
  FPTR_E_SMENA_SUMM_DEP_OVF                      = $3e; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_SMENA_SUMM_DISCOUNT_OVF                 = $3f; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_DISCOUNT_PARAM_OVF                      = $40; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_SUMM_PARAM_OVF                          = $41; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_SUMM_2_PARAM_OVF                        = $42; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜ 1 (˜˜˜˜˜)
  FPTR_E_SUMM_3_PARAM_OVF                        = $43; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜ 2 (˜˜˜˜˜)
  FPTR_E_SUMM_4_PARAM_OVF                        = $44; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜ 3 (˜˜˜˜˜)
  FPTR_E_ALLSUMM_LESS_ITOG                       = $45; // ˜˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜(˜˜˜˜˜)
  FPTR_E_SMENA_CASH_MINUS                        = $46; // ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_SMENA_TAX_OVF                           = $47; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_CHECK_OVF                               = $48; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜ ˜ +
  FPTR_E_CHECK_OPEN_OPERATE_NOT_POSSIBLY         = $4a; // ˜˜˜ ˜˜˜˜˜˜, ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜
  FPTR_E_CHECK_BUFFER_OVF                        = $4b; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜
  FPTR_E_SMENA_ALLTAX_OVF                        = $4c; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_BEZNAL_MORE_CHECK_SUMM                  = $4d; // ˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜
  FPTR_E_SMENA_MORE_24                           = $4e; // ˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ 24 ˜˜˜˜
  FPTR_E_INVALID_PASSWORD                        = $4f; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜
  FPTR_E_PRINT_PREVIOS_CMD                       = $50; // ˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜
  FPTR_E_SMENA_SUMM_OVF                          = $51; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_SMENA_SUMM_2_OVF                        = $52; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜ ˜˜˜˜˜˜ 2 ˜ ˜˜˜˜˜
  FPTR_E_SMENA_SUMM_3_OVF                        = $53; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜ ˜˜˜˜˜˜ 3 ˜ ˜˜˜˜˜
  FPTR_E_SMENA_SUMM_4_OVF                        = $54; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜ ˜˜˜˜˜˜ 4 ˜ ˜˜˜˜˜
  FPTR_E_NOT_REPEAT_DOC                          = $56; // ˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜
  FPTR_E_EKLZ_SMENA_NOT_EQU                      = $57; // ˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜ ˜ ˜˜
  FPTR_E_WAIT_CMD_REPEAT                         = $58;
  FPTR_E_DOC_OPEN_ANOTHER_USER                   = $59; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜
  FPTR_E_CARGE_PARAM_OVF                         = $5B; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜
  FPTR_E_24_LOW                                  = $5c; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ 24 ˜
  FPTR_E_TABLE_NOT_DEFINE                        = $5d; // ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜
  FPTR_E_INVALID_OPERATE                         = $5e; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜  (˜˜˜˜˜)
  FPTR_E_CHECK_ITOG_MINUS                        = $5f; // ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜(˜˜˜˜˜)
  FPTR_E_MUL_OVF                                 = $60; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜˜(˜˜˜˜˜)
  FPTR_E_PRICE_PARAM_OVF                         = $61; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜(˜˜˜˜˜)
  FPTR_E_QUANTITY_PARAM_OVF                      = $62; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜(˜˜˜˜˜)
  FPTR_E_PLACE_PARAM_OVF                         = $63; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_FP_ABSENT                               = $64; // ˜˜˜˜˜˜˜˜˜˜˜ ˜˜
  FPTR_E_PLACE_CASH_MINUS                        = $65; // ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜ ˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_PLACE_CASH_OVF                          = $66; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜ ˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_FP_CONNECT_ERROR                        = $67; // ˜˜˜˜˜˜ ˜˜˜˜˜ ˜ ˜˜
  FPTR_E_ALLTAX_CASH_MINUS                       = $68; // ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_ALLTAX_CASH_OVF                         = $69; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_I2C_ANSWER_POWER_FAIL                   = $6a; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜ I2c
  FPTR_E_NO_RECEIPT_PAPER                        = $6b;
  FPTR_E_NO_JOURNAL_PAPER                        = $6c;
  FPTR_E_TAX_CASH_MINUS                          = $6d; // ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_TAX_CASH_OVF                            = $6e; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_CASHE_OUT_OVF                           = $6f; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_FP_OVF                                  = $70; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜
  FPTR_E_CUT_FAIL                                = $71; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜
  FPTR_E_CMD_NOT_SUPPORT_CURRENT_SUB_ROUTINE     = $72; // ˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜  ˜˜˜˜˜˜˜˜˜
  FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE           = $73; // ˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜
  FPTR_E_RAM_FAIL                                = $74; // ˜˜˜˜˜˜ ˜ ˜˜˜ ()
  RS_PC_POWER_FAIL                               = $75; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜
  FPTR_E_PRINTER_TN                              = $76; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜. ˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_PRINTER_ALL_DAT                         = $77; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜  ˜ ˜˜˜˜˜ ˜˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_NEW_SOFT                                = $78; // ˜˜˜˜˜˜ ˜˜
  FPTR_E_FP_CHANGE                               = $79; // ˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜ (˜˜˜˜˜)
  FPTR_E_FIELD_NOT_CHANGE                        = $7A; // ˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_HDW                                     = $7B; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜(˜˜˜˜˜)
  FPTR_E_DATE_NOT_COMPARE                        = $7C; // ˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_DATE_INVALID_FORMAT                     = $7D; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_INVALID_CMD_LEN                         = $7E; // ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜˜!!!
  FPTR_E_SUMM_ITOG_PARAM_OVF                     = $7f; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜  ˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_CASH_OVF                                = $84; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ (˜˜˜˜˜)
  FPTR_E_SMENA_SALE_OVF                          = $85; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_SMENA_BUY_OVF                           = $86; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_SMENA_SALE_RET_OVF                      = $87; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_SMENA_BUY_RET_OVF                       = $88; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_CASHE_IN_OVF                            = $89; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜
  FPTR_E_CARGE_OVF_CHECK                         = $8a; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜
  FPTR_E_DISCOUNT_OVF_CHECK                      = $8b; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜ ˜˜˜˜
  FPTR_E_CARGE_MINUS_CHECK                       = $8c; // ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜
  FPTR_E_DISCOUNT_MINUS_CHECK                    = $8d; // ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜˜˜ ˜ ˜˜˜˜
  FPTR_E_ZERO_ITOG                               = $8e; // ˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜
  FPTR_E_NO_FISK                                 = $8f; // ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜
  FPTR_E_FORMAT_FIELD_OVF                        = $90; // ˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜˜˜˜˜
  FPTR_E_FORMAT_OVER_PRINT_SIZE                  = $91; // ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜
  FPTR_E_FORMAT_OVERFLOW_FIELD                   = $92; // ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜
  FPTR_E_FORMAT_RESTORE_SUCCESS                  = $93; // ˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜
  FPTR_E_END_LIMIT_OPERATE_CHECK                 = $94;
  FPTR_E_EKLZ_UNKNOWN_ERROR                      = $95;
  FPTR_E_EKLZ_CONNECT_ERROR                      = $A0; // ˜˜˜˜˜˜ ˜˜˜˜˜ ˜ ˜˜˜˜
  FPTR_E_EKLZ_ABSENT                             = $A1; // ˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜
  FPTR_E_EKLZ_OFS                                = $A1; // ˜˜˜˜˜˜ ˜˜˜˜
  FPTR_E_EKLZ_PARAM_OVF_QUANTITY                 = $b0; // ˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜
  FPTR_E_EKLZ_PARAM_OVF_SUM_CHECK                = $b1; // ˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜
  FPTR_E_EKLZ_AKTIV                              = $b2; // ˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜
  FPTR_E_DATE_ENT                                = $c0; // ˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜ ˜˜˜˜˜˜˜  (˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜ ˜˜˜˜˜)
  FPTR_E_UPIT_OVF                                = $c2; // ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜˜˜˜
  FPTR_E_ITOG_NO_EQU_EKLZ                        = $c3; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜ ˜ ˜˜˜˜
  FPTR_E_SMENA_NO_EQU_EKLZ                       = $c4; // ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜
  FPTR_E_SLIP_NODATD                             = $c5; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜
  FPTR_E_SLIP_NOSLIP                             = $c6; // ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜
  FPTR_E_FIELD_NOT_CHANGE_MODE                   = $c7; // ˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜
  FPTR_E_PRINTER_FAIL                            = $c8; // ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜

  DUMP_BLOCK_SIZE = 32;

  TABLE_PASSWORDS_INDEX_ADMIN          = 29;
  TABLE_PASSWORDS_INDEX_SYS_ADMIN      = 30;

  CRLF = #13#10;

  /////////////////////////////////////////////////////////////////////////////
  // Font constants
  /////////////////////////////////////////////////////////////////////////////

  FPTR_FONT_DEFAULT   = 1; // ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜
  FPTR_FONT_BOLD      = 2; // ˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜ bold

  /////////////////////////////////////////////////////////////////////////////
  // Command codes
  /////////////////////////////////////////////////////////////////////////////

  FPTR_COMMAND_START_DUMP               = $01;
  FPTR_COMMAND_GETDUMPBLOCK             = $02;
  FPTR_COMMAND_STOP_DUMP                = $03;
  FPTR_COMMAND_LONG_FISCALIZATION       = $0D;
  FPTR_COMMAND_SET_LONG_SERIAL          = $0E;
  FPTR_COMMAND_GET_LONG_SERIAL          = $0F;
  FPTR_COMMAND_GET_SHORT_STATUS         = $10;
  FPTR_COMMAND_GET_STATUS               = $11;
  FPTR_COMMAND_PRINT_BOLD_LINE          = $12;
  FPTR_COMMAND_BEEP                     = $13;
  FPTR_COMMAND_SET_PORT_PARAMS          = $14;
  FPTR_COMMAND_GET_PORT_PARAMS          = $15;
  FPTR_COMMAND_RESETFM                  = $16;
  FPTR_COMMAND_PRINT_LINE               = $17;
  FPTR_COMMAND_PRINT_DOC_HEADER         = $18;
  FPTR_COMMAND_START_TEST               = $19;
  FPTR_COMMAND_READ_CASH_TOTALIZER      = $1A;
  FPTR_COMMAND_READ_OPER_TOTALIZER      = $1B;
  FPTR_COMMAND_WRITE_LICENSE            = $1C;
  FPTR_COMMAND_READ_LICENSE             = $1D;
  FPTR_COMMAND_WRITE_TABLE              = $1E;
  FPTR_COMMAND_READ_TABLE               = $1F;
  FPTR_COMMAND_WRITE_DECIMAL            = $20;
  FPTR_COMMAND_WRITE_TIME               = $21;
  FPTR_COMMAND_WRITE_DATE               = $22;
  FPTR_COMMAND_CONFIRM_DATE             = $23;
  FPTR_COMMAND_INIT_TABLES              = $24;
  FPTR_COMMAND_CUT_PAPER                = $25;
  FPTR_COMMAND_READ_FONT                = $26;
  FPTR_COMMAND_CLEAR_FM                 = $27;
  FPTR_COMMAND_OPEN_DRAWER              = $28;
  FPTR_COMMAND_FEED_PAPER               = $29;
  FPTR_COMMAND_SLIP_EJECT               = $2A;
  FPTR_COMMAND_STOP_TEST                = $2B;
  FPTR_COMMAND_PRINT_OPREG              = $2C;
  FPTR_COMMAND_READ_TABLE_INFO          = $2D;
  FPTR_COMMAND_READ_FIELD_INFO          = $2E;
  FPTR_COMMAND_PRINT_STRING_FONT        = $2F;
  FPTR_COMMAND_PRINT_X_REPORT           = $40;
  FPTR_COMMAND_PRINT_Z_REPORT           = $41;
  FPTR_COMMAND_PRINT_DEPARTMENT_REPORT  = $42;
  FPTR_COMMAND_PRINT_TAX_REPORT         = $43;
  FPTR_COMMAND_CASH_IN                  = $50;
  FPTR_COMMAND_CASH_OUT                 = $51;
  FPTR_COMMAND_PRINT_HEADER             = $52;
  FPTR_COMMAND_PRINT_DOCEND             = $53;
  FPTR_COMMAND_PRINT_TRAILER            = $54;
  FPTR_COMMAND_WRITE_SERIAL             = $60;
  FPTR_COMMAND_INIT_FM                  = $61;
  FPTR_COMMAND_READ_FM_TOTAL            = $62;
  FPTR_COMMAND_READ_LAST_FM_DATE        = $63;
  FPTR_COMMAND_READ_FM_RANGE            = $64;
  FPTR_COMMAND_FISCALIZE                = $65;
  FPTR_COMMAND_PRINT_DATES_REPORT       = $66;
  FPTR_COMMAND_PRINT_DAYS_REPORT        = $67;
  FPTR_COMMAND_STOP_REPORT              = $68;
  FPTR_COMMAND_READ_FISCALIZATION       = $69;
  FPTR_COMMAND_OPEN_FISCAL_SLIP         = $70;
  FPTR_COMMAND_OPEN_STD_SLIP            = $71;
  FPTR_COMMAND_SLIP_OPERATION           = $72;
  FPTR_COMMAND_SLIP_STD_OPERATION       = $73;
  FPTR_COMMAND_SLIP_DISCOUNT            = $74;
  FPTR_COMMAND_SLIP_STD_DISCOUNT        = $75;
  FPTR_COMMAND_SLIP_CLOSE               = $76;
  FPTR_COMMAND_SLIP_STD_CLOSE           = $77;
  FPTR_COMMAND_SET_SLIP_CONFIG          = $78;
  FPTR_COMMAND_SET_STD_SLIP_CONFIG      = $79;
  FPTR_COMMAND_SET_SLIP_LINE            = $7A;
  FPTR_COMMAND_CLEAR_SLIP_LINE          = $7B;
  FPTR_COMMAND_CLEAR_SLIP_LINES         = $7C;
  FPTR_COMMAND_PRINT_SLIP               = $7D;
  FPTR_COMMAND_SLIP_CONFIG              = $7E;
  FPTR_COMMAND_SALE                     = $80;
  FPTR_COMMAND_BUY                      = $81;
  FPTR_COMMAND_RETSALE                  = $82;
  FPTR_COMMAND_RETBUY                   = $83;
  FPTR_COMMAND_STORNO                   = $84;
  FPTR_COMMAND_RECCLOSE                 = $85;
  FPTR_COMMAND_DISCOUNT                 = $86;
  FPTR_COMMAND_CHARGE                   = $87;
  FPTR_COMMAND_CANCEL_RECEIPT           = $88;
  FPTR_COMMAND_READ_SUBTOTAL            = $89;
  FPTR_COMMAND_STORNO_DISCOUNT          = $8A;
  FPTR_COMMAND_STORNO_CHARGE            = $8B;
  FPTR_COMMAND_PRINT_COPY               = $8C;
  FPTR_COMMAND_OPEN_RECEIPT             = $8D;
  FPTR_COMMAND_EJ_PRINT_DEP_DATES_REPORT  = $A0;
  FPTR_COMMAND_EJ_PRINT_DEP_DAYS_REPORT   = $A1;
  FPTR_COMMAND_EJ_PRINT_DATES_REPORT      = $A2;
  FPTR_COMMAND_EJ_PRINT_DAYS_REPORT       = $A3;
  FPTR_COMMAND_EJ_PRINT_DAY_RESULT        = $A4;
  FPTR_COMMAND_EJ_PRINT_DOCUMENT          = $A5;
  FPTR_COMMAND_EJ_PRINT_DAY_DOCUMENTS     = $A6;
  FPTR_COMMAND_EJ_STOP_REPORT             = $A7;
  FPTR_COMMAND_EJ_PRINT_ACTIVATION        = $A8;
  FPTR_COMMAND_EJ_ACTIVATION              = $A9;
  FPTR_COMMAND_EJ_CLOSE_ARCHIVE           = $AA;
  FPTR_COMMAND_EJ_READ_SERIAL             = $AB;
  FPTR_COMMAND_EJ_STOP                    = $AC;
  FPTR_COMMAND_EJ_READ_STATUS_CODE1       = $AD;
  FPTR_COMMAND_EJ_READ_STATUS_CODE2       = $AE;
  FPTR_COMMAND_EJ_TEST_ARCHIVE            = $AF;
  FPTR_COMMAND_CONTINUE_PRINT             = $B0;
  FPTR_COMMAND_EJ_READ_VERSION            = $B1;
  FPTR_COMMAND_EJ_INIT_ARCHIVE            = $B2;
  FPTR_COMMAND_EJ_READ_LINE               = $B3;
  FPTR_COMMAND_EJ_READ_REPORT             = $B4;
  FPTR_COMMAND_EJ_READ_DOCUMENT           = $B5;
  FPTR_COMMAND_EJ_READ_DEP_DATES_REPORT   = $B6;
  FPTR_COMMAND_EJ_READ_DEP_DAYS_REPORT    = $B7;
  FPTR_COMMAND_EJ_READ_DATES_REPORT       = $B8;
  FPTR_COMMAND_EJ_READ_DAYS_REPORT        = $B9;
  FPTR_COMMAND_EJ_READ_DAY_RESULT         = $BA;
  FPTR_COMMAND_EJ_READ_ACTIVATION         = $BB;
  FPTR_COMMAND_EJ_SET_ERROR               = $BC;
  FPTR_COMMAND_LOAD_GRAPHICS              = $C0;
  FPTR_COMMAND_PRINT_GRAPHICS             = $C1;
  FPTR_COMMAND_PRINT_BARCODE              = $C2;
  FPTR_COMMAND_PRINT_GRAPHICS_EX          = $C3;
  FPTR_COMMAND_LOAD_GRAPHICS_EX           = $C4;
  FPTR_COMMAND_PRINT_GRAPHICS_LINE        = $C5;
  FPTR_COMMAND_READ_BUFFER_LINE_COUNT     = $C8;
  FPTR_COMMAND_READ_BUFFER_LINE           = $C9;
  FPTR_COMMAND_CLEAR_BUFFER               = $CA;


  /////////////////////////////////////////////////////////////////////////////
  // Device code constants
  /////////////////////////////////////////////////////////////////////////////

  FPTR_DEVICE_CODE_FM1    = 1; // Fiscal Memory 1
  FPTR_DEVICE_CODE_FM2    = 2; // Fiscal Memory 2
  FPTR_DEVICE_CODE_CLOCK  = 3; // Clock
  FPTR_DEVICE_CODE_NVRAM  = 4; // Nonvolatile memory
  FPTR_DEVICE_CODE_FMPROC = 5; // Fiscal Memory processor
  FPTR_DEVICE_CODE_ROM    = 6; // Fiscal Printer ROM
  FPTR_DEVICE_CODE_RAM    = 7; // Fiscal Printer RAM

  /////////////////////////////////////////////////////////////////////////////
  // Receipt type
  /////////////////////////////////////////////////////////////////////////////

  FPTR_RECTYPE_SALE     = 0; // Sale
  FPTR_RECTYPE_BUY      = 1; // Buy
  FPTR_RECTYPE_RETSALE  = 2; // Sale refund
  FPTR_RECTYPE_RETBUY   = 3; // Buy refund

  EncodingWindows       = 0;
  Encoding866           = 1;

  BoolToInt: array [Boolean] of Integer = (0, 1);

  // printer stations
  PRINTER_STATION_JRN       = 1;    // Bit 0 - Journal
  PRINTER_STATION_REC       = 2;    // Bit 1 - Receipt
  PRINTER_STATION_SLP       = 4;    // Bit 2 - Slip

  // Report type
  PRINTER_REPORT_TYPE_SHORT     = 0;    // Short
  PRINTER_REPORT_TYPE_FULL      = 1;    // Full

  // Field types
  PRINTER_FIELD_TYPE_INT        = 0;    // Integer
  PRINTER_FIELD_TYPE_STR        = 1;    // String

  // Decimal point position
  PRINTER_POINT_POSITION_0      = 0;    // 0 digits
  PRINTER_POINT_POSITION_2      = 1;    // 2 digits


  /////////////////////////////////////////////////////////////////////////////
  // Cut type
  /////////////////////////////////////////////////////////////////////////////

  PRINTER_CUTTYPE_FULL          = 0;    // Full
  PRINTER_CUTTYPE_PARTIAL       = 1;    // Partial

  /////////////////////////////////////////////////////////////////////////////
  // Table constants
  /////////////////////////////////////////////////////////////////////////////

  FPTR_TABLE_SETUP           = 1;    // ECR type and mode
  FPTR_TABLE_CASHIER         = 2;    // Cashier and admin's passwords
  FPTR_TABLE_TIME            = 3;    // Time conversion table
  FPTR_TABLE_TEXT            = 4;    // Text in receipt
  FPTR_TABLE_PAYTYPE         = 5;    // Payment type names
  FPTR_TABLE_TAX             = 6;    // Taxes
  FPTR_TABLE_DEPARTMENT      = 7;    // Department names
  FPTR_TABLE_FONTS           = 8;    // Font settings
  FPTR_TABLE_RECFORMAT       = 9;    // Receipt format table

  /////////////////////////////////////////////////////////////////////////////
  // Mode constants
  /////////////////////////////////////////////////////////////////////////////

  FPTR_MODE_DUMP		      = $01; // Dump mode
  FPTR_MODE_DAY_OPENED		= $02; // Day opened, 24 hours not left
  FPTR_MODE_DAY_OVER		  = $03; // Day opened, 24 hours is over
  FPTR_MODE_DAY_CLOSED		= $04; // Fiscal day closed
  FPTR_MODE_LOCKED		    = $05; // ECR is bloced because of incorrect tax officer password
  FPTR_MODE_WAITDATE	  	= $06; // Waiting for date confirm
  FPTR_MODE_POINTPOS		  = $07; // Change decimal point position permission
  FPTR_MODE_RECSALE		    = $08; // Opened document: sale
  FPTR_MODE_RECBUY		    = $18; // Opened document: buy
  FPTR_MODE_RECRETSALE		= $28; // Opened document: sale refund
  FPTR_MODE_RECRETBUY		  = $38; // Opened document: buy refund
  FPTR_MODE_TECH			    = $09; // Technological reset permission
  FPTR_MODE_TEST			    = $0A; // Test run
  FPTR_MODE_FULLREPORT		= $0B; // Full fiscal report printing
  FPTR_MODE_EKLZREPORT		= $0C; // EJ report printing
  FPTR_MODE_SLPSALE	     	= $0D; // Opened fiscal slip: sale
  FPTR_MODE_SLPBUY		    = $1D; // Opened fiscal slip: buy
  FPTR_MODE_SLPRETSALE		= $2D; // Opened fiscal slip: sale refund
  FPTR_MODE_SLPRETBUY		  = $3D; // Opened fiscal slip: buy refund
  FPTR_MODE_SLPWAITLOAD		= $0E; // Waiting for slip load
  FPTR_MODE_SLPLOAD		    = $1E; // Slip loading and positioning
  FPTR_MODE_SLPPOSITION		= $2E; // Slip positioning
  FPTR_MODE_SLPPRINTING		= $3E; // Slip printing
  FPTR_MODE_SLPPRINTED		= $4E; // Slip is printed
  FPTR_MODE_SLPEJECT	  	= $5E; // Eject slip
  FPTR_MODE_SLPWAITEJECT  = $6E; // Waiting for slip eject
  FPTR_MODE_SLPREADY		  = $0F; // Fiscal slip is ready

  /////////////////////////////////////////////////////////////////////////////
  // Lowest 4 bits of mode
  /////////////////////////////////////////////////////////////////////////////

  FPTR_MODE4_DUMP   			= $01; // Dump mode
  FPTR_MODE4_24NOTOVER		= $02; // Opened shift, 24 hours not left
  FPTR_MODE4_24OVER			  = $03; // Opened shift, 24 hours is over
  FPTR_MODE4_CLOSED			  = $04; // Closed shift
  FPTR_MODE4_LOCKED			  = $05; // ECR is bloced because of incorrect tax offecer password
  FPTR_MODE4_WAITDATE			= $06; // Waiting for date confirm
  FPTR_MODE4_POINTPOS			= $07; // Change decimal point position permission
  FPTR_MODE4_REC		     	= $08; // Opened document
  FPTR_MODE4_TECH		     	= $09; // Technological reset permission
  FPTR_MODE4_TEST			    = $0A; // Test run
  FPTR_MODE4_FULLREPORT		= $0B; // Full fiscal report printing
  FPTR_MODE4_EKLZREPORT		= $0C; // EJ report printing
  FPTR_MODE4_SLP		     	= $0D; // Opened fiscal slip
  FPTR_MODE4_SLPPRINT			= $0E; // Slip printing
  FPTR_MODE4_SLPREADY			= $0F; // Fiscal slip is ready

  /////////////////////////////////////////////////////////////////////////////
  // Submode constants
  /////////////////////////////////////////////////////////////////////////////

  FPTR_SUBMODE_IDLE       = 0;	// 0.	Paper present
  FPTR_SUBMODE_PASSIVE	  = 1;	// 1.	Passive paper absense
  FPTR_SUBMODE_ACTIVE		  = 2;	// 2.	Active paper absense
  FPTR_SUBMODE_AFTER		  = 3;	// 3.	After active paper absense
  FPTR_SUBMODE_REPORT		  = 4;	// 4.	Report printing stage
  FPTR_SUBMODE_PRINT		  = 5;	// 5.	Operation printing stage

  /////////////////////////////////////////////////////////////////////////////
  // Models
  /////////////////////////////////////////////////////////////////////////////

  FPTR_MODEL_DEFAULT                 = -1;   // Default model
  FPTR_MODEL_SHTRIH_FRF              = 0;    // SHTRIH-FR-F (ver. 03 & 04)
  FPTR_MODEL_SHTRIH_FRFKAZ           = 1;    // SHTRIH-FR-F (Kazakhstan)
  FPTR_MODEL_ELVES_MINI_FRF          = 2;    // ELVES-MINI-FR-F
  FPTR_MODEL_FELIX                   = 3;    // FELIX-R F
  FPTR_MODEL_SHTRIH_FRK              = 4;    // SHTRIH-FR-K
  FPTR_MODEL_SHTRIH_950K             = 5;    // SHTRIH-950K
  FPTR_MODEL_ELVES_FRK               = 6;    // ELVES-FR-K
  FPTR_MODEL_SHTRIH_MINI_FRK         = 7;    // SHTRIH-MINI-FR-K
  FPTR_MODEL_SHTRIH_FRF_BEL          = 8;    // SHTRIH-FR-F (Belorussia)
  FPTR_MODEL_COMBO_FRK               = 9;    // SHTRIH-COMBO-FR-K
  FPTR_MODEL_SHTRIH_POSF             = 10;   // Fiscal module Shtrih-POS-F
  FPTR_MODEL_SHTRIH_950K_02          = 11;   // SHTRIH-950K
  FPTR_MODEL_COMBO_FRK_02            = 12;   // SHTRIH-COMBO-FR-K (ver. 02)
  FPTR_MODEL_SHTRIH_MINI_FRK_02      = 14;   // SHTRIH-MINI-FR-K (ver 02, 57 mm)
  FPTR_MODEL_SHTRIH_KIOSK_FRK        = 15;   // SHTRIH-KIOSK-FR-K
  FPTR_MODEL_SHTRIH_M_FRK            = 250;  // SHTRIH-M-FR-K
  FPTR_MODEL_SHTRIH_LIGHT_FRK        = 251;  // SHTRIH-LIGHT-FR-K
  FPTR_MODEL_YARUS_M2100K            = 20;   // YARUS M2100K

  /////////////////////////////////////////////////////////////////////////////
  // Cash registers
  /////////////////////////////////////////////////////////////////////////////

  REG_REC_SALE1			        = 0;   // Accumulation of sales in 1-st department in receipt
  REG_REC_BUY1			        = 1;   // Accumulation of buys in 1-st department in receipt
  REG_REC_RETSALE1		      = 2;   // Accumulation of sale refunds in 1-st department in receipt
  REG_REC_RETBUY1			      = 3;   // Accumulation of buy refunds in 1-st department in receipt
  REG_REC_DISC_SALE		      = 64;  // Accumulation of discounts from sales in receipt
  REG_REC_DISC_BUY		      = 65;  // Accumulation of discounts from buys in receipt
  REG_REC_DISC_RETSALE	    = 66;  // Accumulation of discounts from sale refunds in receipt
  REG_REC_DISC_RETBUY		    = 67;  // Accumulation of discounts from buy refunds in receipt
  REG_REC_CHRG_SALE		      = 68;  // Accumulation of charges from sales in receipt
  REG_REC_CHRG_BUY		      = 69;  // Accumulation of charges from buys in receipt
  REG_REC_CHRG_RETSALE	    = 70;  // Accumulation of charges from sale refunds in receipt
  REG_REC_CHRG_RETBUY		    = 71;  // Accumulation of charges from buy refunds in receipt
  REG_DAY_DISC_SALE		      = 185; // Accumulation of discounts from sales in shift
  REG_DAY_DISC_BUY		      = 186; // Accumulation of discounts from buys in shift
  REG_DAY_DISC_RETSALE	    = 187; // Accumulation of discounts froum sale refunds in shift
  REG_DAY_DISC_RETBUY		    = 188; // Accumulation of discounts from buy refunds in shift
  REG_DAY_CHRG_SALE		      = 189; // Accumulation of charges from sales in shift
  REG_DAY_CHRG_BUY		      = 190; // Accumulation of charges from buys in shift
  REG_DAY_CHRG_RETSALE	    = 191; // Accumulation of charges from sale refunds in shift
  REG_DAY_CHRG_RETBUY		    = 192; // Accumulation of charges from buy refunds in shift
  REG_DAY_SALE			        = 245; // Sales total in shift from EJ
  REG_DAY_BUY		        		= 246; // Buys total in shift from EJ
  REG_DAY_RETSALE			      = 247; // Sale refunds total in shift from EJ
  REG_DAY_RETBUY			      = 248; // Buy refunds totall in shift from EJ
  EJ_NO_MORE_DATA           = $A9; // EJ: No requested data available

  /////////////////////////////////////////////////////////////////////////////
  // Language codes

  FP_LANGUAGE_RUSSIAN     = 0;
  FP_LANGUAGE_ENGLISH     = 1;
  FP_LANGUAGE_ESTONIAN    = 2;
  FP_LANGUAGE_KAZAKH      = 3;
  FP_LANGUAGE_BELORUSSIAN = 4;
  FP_LANGUAGE_ARMENIAN    = 5;
  FP_LANGUAGE_GEORGIAN    = 6;
  FP_LANGUAGE_UKRANIAN    = 7;
  FP_LANGUAGE_KIRGHIZ     = 8;
  FP_LANGUAGE_TURKMEN     = 9;
  FP_LANGUAGE_MOLDOVA     = 10;

type
  { TDumpBlock }

  TDumpBlock = packed record
    DeviceCode: Byte;
    BlockNumber: Word;
    BlockData: array [0..31] of byte;
  end;

  { TPrinterDate }

  TPrinterDate = packed record
    Day: Byte;
    Month: Byte;
    Year: Byte;
  end;

  { TPrinterTime }

  TPrinterTime = packed record
    Hour: Byte;
    Min: Byte;
    Sec: Byte;
  end;

  { TEJTime }

  TEJTime = packed record
    Hour: Byte;
    Min: Byte;
  end;

  { TLongFiscResult }

  TLongFiscResult = packed record
    FiscNumber: Byte;       // Fiscalization/Refiscalization number(1 byte) 1˜16
    LeftNumber: Byte;       // Quantity of refiscalizations left in FM (1 byte) 0˜15
    ShiftNumber: Word;      // Last daily totals record number in FM (2 bytes) 0000˜2100
    Date: TPrinterDate;     // Fiscalization/Refiscalization date (3 bytes) DD-MM-YY
  end;

  { TShortPrinterStatus }

  TShortPrinterStatus = packed record
    Operator: Byte;
    Flags: Word;
    Mode: Byte;
    AdvancedMode: Byte;
    ItemCountLo: Byte;
    BatteryVoltage: Byte;
    PowerVoltage: Byte;
    FMErrorCode: Byte;
    EJErrorCode: Byte;
    ItemCountHi: Byte;
  end;

  { TLongPrinterStatus }

  TLongPrinterStatus = packed record
    Operator: Byte;
    FirmwareVersionHi: AnsiChar;
    FirmwareVersionLo: AnsiChar;
    FirmwareBuild: Word;
    FirmwareDate: TPrinterDate;
    LogicalNumber: Byte;
    DocNumber: Word;
    Flags: Word;
    Mode: Byte;
    AdvancedMode: Byte;
    PortNumber: Byte;
    FMVersionHi: AnsiChar;
    FMVersionLo: AnsiChar;
    FMBuild: Word;
    FMFirmwareDate: TPrinterDate;
    Date: TPrinterDate;
    Time: TPrinterTime;
    FMFlags: Byte;
    SerialNumber: string;
    DayNumber: Word;
    RemainingFiscalMemory: Word;
    RegistrationNumber: Byte;
    FreeRegistration: Byte;
    FiscalID: string;
  end;

  { TPrinterFlags }

  TPrinterFlags = packed record
    JrnNearEnd: Boolean; // Bit 0 - Journal station low paper (0 - yes, 1 - no)
    RecNearEnd: Boolean; // Bit 1 - Receipt station low paper (0 - yes, 1 - no)
    SlpUpSensor: Boolean; // Bit 2 - Paper in slip station upper sensor (0 - no, 1 - yes)
    SlpLoSensor: Boolean; // Bit 3 - Paper in slip station lower sensor (0 - no, 1 - yes)
    DecimalPosition: Boolean; // Bit 4 - Decimal dot position (0 - 0 digits after the dot, 1 - 2 digits after the dot)
    EJPresent: Boolean; // Bit 5 - EKLZ in FP (0 - no, 1 - yes)
    JrnEmpty: Boolean; // Bit 6 - Journal station out-of-paper (0 - no paper, 1 - paper in printing mechanism)
    RecEmpty: Boolean; // Bit 7 - Receipt station out-of-paper (0 - no paper, 1 - paper in printing mechanism)
    JrnLeverUp: Boolean; // Bit 8 -Thermal head lever position of journal station (0 - lever up, 1 - lever down)
    RecLeverUp: Boolean; // Bit 9 - Thermal head lever position of receipt station (0 - lever up, 1 - lever down)
    CoverOpened: Boolean; // Bit 10 - FP cabinet lid position (0 - lid down, 1 - lid up)
    DrawerOpened: Boolean; // Bit 11 - Cash drawer (0 - drawer closed, 1 - drawer open)
    Bit12: Boolean; // Bit 12a -Failure of right sensor of printing mechanism (0 - no, 1 - yes)
                    // Bit 12b - Paper on input to presenter (0 - no, 1 - yes)
                    // Bit 12c - Printing mechanism model (0 - MLT-286, 1 - MLT-286-1)
    Bit13: Boolean; // Bit 13a - Failure of left sensor of printing mechanism (0 - no, 1 - yes)
                    // Bit 13b - Paper in presenter (0 - no, 1 - yes)
    EJNearEnd: Boolean; // Bit 14 - EKLZ almost full (0 - no, 1 - yes)
    Bit15: Boolean; // Bit 15a - Quantity accuracy
                    // Bit 15b - Printer buffer status (0 - empty, 1 - not empty)
  end;

  { TFMFlags }

  TFMFlags = packed record
    FM1Present: Boolean;          // 0 - FM 1 (0 - not present, 1 - present)
    FM2Present: Boolean;          // 1 - FM 2 (0 - not present, 1 - present)
    LicenseEntered: Boolean;      // 2 - License (0 - not assigned, 1 - assigned)
    Overflow: Boolean;            // 3 - FM overflow (0 - no, 1 - yes)
    LowBattery: Boolean;          // 4 - FM battery (0 - >80%, 1 - <80%)
    LastRecordCorrupted: Boolean; // 5 - Last FM record (0 - corrupted, 1 - correct)
    DayOpened: Boolean;           // 6 - Shift in FM (0 - closed, 1 - opened)
    Is24HoursLeft: Boolean;       // 7 - 24 hours in FM (0 - not over, 1 - over)
  end;

  { TGetLongSerial }

  TGetLongSerial = packed record
    Serial: Int64;
    PrinterID: Int64;
  end;

  { TPortParams }

  TPortParams = packed record
    BaudRate: Integer;
    Timeout: Integer;
  end;

  { TFptrFontRec }

  TFptrFontRec = packed record
    PrintWidth: Word;   // Paper width in dots
    CharWidth: Byte;    // Character width in dots
    CharHeight: Byte; 	// Character heigth in dots
    FontCount: Byte; 	  // Font count
  end;

  { TPrinterTableRec }

  TPrinterTableRec = packed record
    Number: Integer;            // Table number
    Name: string;               // Table name (40 byts)
    RowCount: Integer;          // Row count (2 bytes)
    FieldCount: Integer;        // Field count (1 byte)
  end;

  { TPrinterFieldRec }

  TPrinterFieldRec = packed record
    Table: Integer;                     // Table number
    Row: Integer;                       // Row number
    Field: Integer;                     // Field number
    Name: string;                       // Name
    Size: Integer;                      // Field size
    FieldType: Integer;                 // Field type
    MinValue: Integer;                  // Min value
    MaxValue: Integer;                  // Max value
  end;

  { TFMTotals }

  TFMTotals = packed record
    Operator: Byte; // Operator number (1 byte) 29, 30
    SaleTotal: Int64;     // Shift sales totals sum (8 bytes)
    BuyTotal: Int64;      // Shift buys totals sum (6 bytes) in case of FM 2 absense: FFh FFh FFh FFh FFh FFh
    RetSaleTotal: Int64;  // Shift sale refunds totals sum (6 bytes) in case of FM 2 absense: FFh FFh FFh FFh FFh FFh
    RetBuyTotal: Int64;   // Shift buy refunds totals sum (6 bytes) in case of FM 2 absense: FFh FFh FFh FFh FFh FFh
  end;

  { TFMRecordDate }

  TFMRecordDate = packed record
    Operator: Byte;       // Operator number (1 byte) 29, 30
    RecordType: Byte;           // Last record type (1 byte) "0" - fiscalilzation (fefiscalization), "1" - Shift total
    Date: TPrinterDate;         // Date (3 bytes) DD-MM-YY
  end;

  { TShiftRange }

  TShiftRange = packed record
    Date1: TPrinterDate;        // First shift date (3 bytes) DD-MM-YY
    Date2: TPrinterDate;        // Last shift date (3 bytes) DD-MM-YY
    Number1: Word;              // First shift number (2 bytes) 0000˜2100
    Number2: Word;              // Last shift number (2 bytes) 0000˜2100
  end;

  { TFiscalizationResult }

  TFiscalizationResult = packed record
    FiscNumber: Byte;           // Fiscalization (refiscalization) number  (1 byte) 1˜16
    LeftFiscCount: Byte;        // Refiscalizations left count (1 byte) 0˜15
    LastShiftNumber: Word;      // Last closed shift number(2 bytes) 0000˜2100
    Date: TPrinterDate;         // Fiscalilzation (refiscalization) date (3 bytes) DD-MM-YY
  end;

  { TShiftDateRange }

  TShiftDateRange = packed record
    Date1: TPrinterDate;
    Date2: TPrinterDate;
  end;

  { TShiftNumberRange }

  TShiftNumberRange = packed record
    Number1: Word;
    Number2: Word;
  end;

  { TFiscInfo }

  TFiscInfo = packed record
    Password: DWORD;    // Password (4 bytes)
    PrinterID: Int64;   // ECRRN (5 bytes) 0000000000˜9999999999
    FiscalID: Int64;    // Taxpayer ID (6 byte) 000000000000˜999999999999
    ShiftNumber: Word;  // Shift number before fiscalization (refiscalization) (2 bytes) 0000˜2100
    Date: TPrinterDate; // Fiscalization (refiscalization) date (3 bytes) DD-MM-YY
  end;

  { TFptrDocResult }

  TFptrDocResult = packed record
    Operator: Byte; // Operator number (1 byte) 1˜30
    DocNumber: WORD; // Transparent document number (2 bytes)
  end;

  { TSlipParams }

  TSlipParams = packed record
    DocType: Byte;              // Document type (1 byte) "0" - sale, "1" - buy, "2" - sale refund, "3" - buy refund
    DupType: Byte;              // Duplicate type (1 byte) "0" - columns, "1" - line blocks
    DupCount: Byte;             // Duplicate count (1 byte) 0˜5
    DupOffset1: Byte;           // Spacing between original and 1-st duplicate (1 byte) *
    DupOffset2: Byte;           // Spacing between 1-st and 2-nd duplicate (1 byte) *
    DupOffset3: Byte;           // Spacing between 2-nd and 3-d duplicate (1 byte) *
    DupOffset4: Byte;           // Spacing between 3-d and 4-th duplicate (1 byte) *
    DupOffset5: Byte;           // Spacing between 4-th and 5-th duplicate (1 byte) *
    HeaderFont: Byte;           // Font number of fixed header (1 byte)
    DocHeaderFont: Byte;        // Font number of document header (1 byte)
    EJSerialFont: Byte;         // Font number of EJ serial number (1 byte)
    EJCRCFont: Byte;            // Font number of KPK value and KPK number (1 byte)
    HeaderLine: Byte;           // Vertical position of fixed header (1 byte)
    DocHeaderLine: Byte;        // Vertical position of document header (1 byte)
    EJSErialLine: Byte;         // Vertical position of EJ serial number (1 byte)
    DupSignLine: Byte;          // Vertical position of duplicate marker (1 byte)
    HeaderLineOffset: Byte;     // Horizontal position of fixed header (1 byte)
    DocHeaderLineOffset: Byte;  // Horizontal position of document header (1 byte)
    EJSerialLineOffset: Byte;   // Horizontal position of EJ serial number (1 byte)
    EJCRCLineOffset: Byte;      // Horizontal position of KPK value and KPK number (1 byte)
    EJDupSignLineOffset: Byte;  // Horizontal position of duplicate marker (1 byte)
  end;

  { TStdSlipParams }

  TStdSlipParams = packed record
    DocType: Byte;              // Document type (1 byte) "0" - sale, "1" - buy, "2" - sale refund, "3" - buy refund
    DupType: Byte;              // Duplicate type (1 byte) "0" - columns, "1" - string blocks
    DupCount: Byte;             // Duplicate count (1 byte) 0˜5
    DupOffset1: Byte;           // Spacing between original and 1-st duplicate (1 byte) *
    DupOffset2: Byte;           // Spacing between 1-st and 2-nd duplicate (1 byte) *
    DupOffset3: Byte;           // Spacing between 2-nd and 3-d duplicate (1 byte) *
    DupOffset4: Byte;           // Spacing between 3-d and 4-th duplicate (1 byte) *
    DupOffset5: Byte;           // Spacing between 4-th and 5-th duplicate (1 byte) *
  end;

  { TSlipOperation }

  TSlipOperation = packed record
    QuantityFormat: Byte;       // Quantitiy format (1 byte) "0" - without digits after delimeter, "1" - with digits after delimeter
    LineCount: Byte;            // Operation line count (1 byte) 1˜3
    TextLine: Byte;             // Text line number (1 byte) 0˜3, "0" - do not print
    QuantityLine: Byte;         // Quantity times price line number (1 byte) 0˜3, "0" - do not print
    SummLine: Byte;             // Sum line number (1 byte) 1˜3
    DepartmentLine: Byte;       // Department line number (1 byte) 1˜3
    TextFont: Byte;             // Text string font number (1 byte)
    QuantityFont: Byte;         // Quantity font numter (1 byte)
    MultSignFont: Byte;         // Multiplication sign font number (1 byte)
    PriceFont: Byte;            // Price font number (1 byte)
    SumFont: Byte;              // Sum font number (1 byte)
    DepartmentFont: Byte;       // Department font number (1 byte)
    TextWidth: Byte;            // Text string field character count (1 byte)
    QuantityWidth: Byte;        // Quantity field character count (1 byte)
    PriceWidth: Byte;           // Price field character count (1 byte)
    SumWidth: Byte;             // Sum field character count (1 byte)
    DepartmentWidth: Byte;      // Department field character count (1 byte)
    TextOffset: Byte;           // Text string field horizontal spacing (1 byte)
    QuantityOffset: Byte;       // Quantity times price field horizontal spacing (1 byte)
    SumOffset: Byte;            // Sum field horizontal spacing (1 byte)
    DepartmentOffset: Byte;     // Department field horizontal spacing (1 byte)
    LineNumber: Byte;           // Vertical position of first transaction string (1 byte)
  end;

  { TFptrItemRec }

  TFptrItemRec = packed record
    Quantity: Int64;    // Quantity (5 bytes)
    Price: Int64;       // Price (5 bytes)
    Department: Byte;   // Department (1 byte) 0˜16
    Tax1: Byte;         // Tax 1 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax2: Byte;         // Tax 2 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax3: Byte;         // Tax 3 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax4: Byte;         // Tax 4 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Text: string;       // Text (40 byte)
  end;

  { TFptrDiscount }

  TFptrDiscount = packed record
    Amount: Int64;       // Price (5 bytes)
    Tax1: Byte;         // Tax 1 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax2: Byte;         // Tax 2 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax3: Byte;         // Tax 3 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax4: Byte;         // Tax 4 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Text: string;       // Text (40 byte)
  end;

  { TSlipDiscountParams }

  TSlipDiscountParams = packed record
    LineCount: Byte;    // Transaction line count (1 byte) 1˜2
    TextLine: Byte;     // Text string line number (1 byte) 0˜2, "0" - do not print
    NameLine: Byte;     // Transaction name line number (1 byte) 1˜2
    AmountLine: Byte;   // Sum line number (1 byte) 1˜2
    TextFont: Byte;     // Text string font number (1 byte)
    NameFont: Byte;     // Transaction name font number (1 byte)
    AmountFont: Byte;   // Sum font number (1 byte)
    TextWidth: Byte;    // Text string field character count (1 byte)
    AmountWidth: Byte;  // Sum field character count (1 byte)
    TextOffset: Byte;   // Text string field horizontal spacing (1 byte)
    NameOffset: Byte;   // Transaction name field horizontal spacing (1 byte)
    AmountOffset: Byte; // Sum field horizontal spacing (1 byte)
  end;

  { TSlipDiscount }

  TSlipDiscount = packed record
    OperationType: Byte; // Operation type (1 byte) "0" - discount, "1" - charge
    LineNumber: Byte;    // First discount/charge element vertical position (1 byte)
    Amount: Int64;       // Sum (5 bytes)
    Department: Byte;    // Department (1 byte) 0˜16
    Tax1: Byte;          // Tax 1 (1 byte) "0" - not, "1"˜"4" - tax group
    Tax2: Byte;          // Tax 2 (1 byte) "0" - not, "1"˜"4" - tax group
    Tax3: Byte;          // Tax 3 (1 byte) "0" - not, "1"˜"4" - tax group
    Tax4: Byte;          // Tax 4 (1 byte) "0" - not, "1"˜"4" - tax group
    Text: string;        // Text (40 byte)
  end;

  { TFptrCloseReceipt }

  TFptrCloseReceipt = packed record
    Amount1: Int64;  // Cash payment sum (5 bytes)
    Amount2: Int64;     // Payment type 2 sum (5 bytes)
    Amount3: Int64;     // payment type 3 sum (5 bytes)
    Amount4: Int64;     // Payment type 4 sum (5 bytes)
    Discount: WORD;      // Receipt discount in value 0 to 99.99 % (2 bytes) 0000˜9999
    Tax1: Byte;         // Tax 1 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax2: Byte;         // Tax 2 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax3: Byte;         // Tax 3 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax4: Byte;         // Tax 4 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Text: string;       // Text (40 byte)
  end;

  { TFptrCloseReceiptResult }

  TFptrCloseReceiptResult = packed record
    Operator: Byte;       // Operator number (1 byte) 1˜30
    Change: Int64;        // Change (5 bytes) 0000000000˜9999999999
  end;

  { TSlipCloseParams }

  TSlipCloseParams = packed record
  
  end;

  { TFptrAmountOperation }

  TFptrAmountOperation = packed record
    Amount: Int64;      // Sum (5 bytes)
    Department: Byte;   // Department (1 byte) 0˜16
    Tax1: Byte;         // Tax 1 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax2: Byte;         // Tax 2 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax3: Byte;         // Tax 3 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Tax4: Byte;         // Tax 4 (1 byte) "0" - no tax, "1"˜"4" - tax group
    Text: string;       // Text (40 byte)
  end;

  { TFptrDeviceMetricsRec }

  TFptrDeviceMetricsRec = packed record
    DeviceType: Byte;           // Device type (1 byte) 0˜255
    DeviceSubtype: Byte;        // Device suptype (1 byte) 0˜255
    ProtocolVersion: Byte;      // Device protocol version (1 byte) 0˜255
    ProtocolSubVersion: Byte;   // Device protocol subversion (1 byte) 0˜255
    Model: Byte;                // Device model (1 byte) 0˜255
    Language: Byte;             // Device language (1 byte) 0˜255 Russian - 0; English - 1;
    DeviceName: string;         // Device name - string of characters in WIN1251.
  end;

  { TEJFlags }

  TEJFlags = packed record
    DocType: Byte;              // Document type, 0..3, Sale, buy, sale refund, buy refund
    ArcOpened: Boolean;         // Archive is opened
    Activated: Boolean;         // EJ is activated
    ReportMode: Boolean;        // Report mode
    DocOpened: Boolean;         // Document is opened
    DayOpened: Boolean;         // Shift is opened
    ErrorFlag: Boolean;         // Device error
  end;

  { TEJStatus1 }

  TEJStatus1 = packed record
    DocAmount: Int64;           // Last KPK document total KPK (5 bytes) 0000000000˜9999999999
    DocDate: TPrinterDate;      // Last KPK date (3 bytes) DD-MM-YY
    DocTime: TEJTime;           // Last KPK time (2 bytes) HH-MM
    DocNumber: DWORD;           // Last KPK number (4 bytes) 00000000˜99999999
    EJNumber: Int64;            // EJ serial number (5 bytes) 0000000000˜9999999999
    Flags: TEJFlags;            // EJ flags (1 byte)
  end;

  { TPrinterStatus }

  TPrinterStatus = packed record
    Mode: Byte;
    AdvancedMode: Byte;
    Flags: TPrinterFlags;
    Operator: Byte;
  end;

  { TReportOnDates }

  TDateReport = packed record
    ReportType: Byte;
    Date1: TPrinterDate;
    Date2: TPrinterDate;
  end;

  { TNumberReport }

  TNumberReport = packed record
    ReportType: Byte;
    Number1: Word;
    Number2: Word;
  end;


  { TModelInfo }

  TModelInfo = packed record
    ID: Integer;
    Name: string;
    CapShortEcrStatus: Boolean;         // Short ECR status available
    CapCoverSensor: Boolean;            // Cover sensor present
    CapJrnPresent: Boolean;             // Journal present
    CapJrnEmptySensor: Boolean;         // Journal empty sensor present
    CapJrnNearEndSensor: Boolean;       // Journal near end sensor present
    CapRecPresent: Boolean;             // Receipt paper present
    CapRecEmptySensor: Boolean;         // Receipt paper empty sensor present
    CapRecNearEndSensor: Boolean;       // Receipt paper near end sensor present
    CapSlpFullSlip: Boolean;            // Full slip size available
    CapSlpEmptySensor: Boolean;         // Slip upper sensor present
    CapSlpFiscalDocument: Boolean;      // Fiscal slip available
    CapSlpNearEndSensor: Boolean;       // Slip lower sensor available
    CapSlpPresent: Boolean;             // Slip present
    CapSetHeader: Boolean;              // Header is editable
    CapSetTrailer: Boolean;             // Trailer is editable
    CapRecLever: Boolean;               // Receipt lever is present
    CapJrnLever: Boolean;               // Journal lever is present
    CapFixedTrailer: Boolean;           // Trailer is fixed and can not be removed
    CapDisableTrailer: Boolean;
    DisableTrailerField: Integer;
    NumHeaderLines: Integer;
    NumTrailerLines: Integer;
    StartHeaderLine: Integer;
    StartTrailerLine: Integer;
    BaudRates: string;
    PrintWidth: Integer;                // Print width
    CutTypeField: Byte;                   // Field
    MaxGraphicsWidth: Word;             // Max graphics width
    MaxGraphicsHeight: Word;            // Max graphics height
    RecFormatEnabledField: Byte;        // "Use receipt format" field number
    CapFullCut: Boolean;                // Printer supports full paper cut
    CapPartialCut: Boolean;             // Printer supports partial paper cut
  end;

  { TFptrSubtotal }

  TFptrSubtotal = record
    Operator: Integer;
    Subtotal: Int64;
  end;

//function GetCommandName(Command: Integer): string;
function GetModeDescription(Value: Integer): string;
function GetDeviceCodeDescription(Value: Integer): string;
function GetErrorText(Code: Integer): string;
function GetAdvancedModeDescription(Value: Integer): string;
function GetCashRegisterName(Value: Integer): string;
function IsRecStation(Stations: Byte): Boolean;
function IsJrnStation(Stations: Byte): Boolean;
function IsSlpStation(Stations: Byte): Boolean;
function IsFieldStr(FieldType: Integer): Boolean;
function IsFieldInt(FieldType: Integer): Boolean;
function IntToBool(Value: Integer): Boolean;
function ComparePrinterDate(const Date1, Date2: TPrinterDate): Integer;

function EncodePrinterFlags(Flags: TPrinterFlags): Word;
function DecodePrinterFlags(Flags: Word): TPrinterFlags;
function GetLanguageName(Code: Integer): string;




type
  TEmulFieldDef = record
    Table: Integer;
    Row: Integer;
    Field: Integer;
    Size: Integer;
    FieldType: Integer;
    MinValue: Int64;
    MaxValue: Int64;
    Name: string;
    Value: string;
  end;

  TEmulTableDef = record
    Number: Integer;
    Name: string;
    RowCount: Integer;
    FieldCount: Integer;
  end;

  { TEmulTables }

  TEmulTables = class
  private
    FFields: TList;
    FTables: TList;
    FHeader: TStringList;
    function GetFieldCount: Integer;
    function GetField(Index: Integer): TEmulFieldDef;
    function GetTableCount: Integer;
    function GetTable(Index: Integer): TEmulTableDef;
    function FieldKey(Table, Row, Field: Integer): string;
    function FindFieldIndex(Table, Row, Field: Integer): Integer;
    procedure RebuildTableDefs;
    function ParseCsvString(const Text: string; Number: Integer): string;
    procedure AddFieldFromLine(const Line: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromFile(const FileName: string);
    function FindTable(TableNumber: Integer): TEmulTableDef;
    function ReadFieldValue(Table, Row, Field: Integer): string;
    procedure WriteFieldValue(Table, Row, Field: Integer; const Value: string);
    function ReadFieldDef(Table, Row, Field: Integer; out Def: TEmulFieldDef): Boolean;
    property Header: TStringList read FHeader;
    property FieldCount: Integer read GetFieldCount;
    property Fields[Index: Integer]: TEmulFieldDef read GetField;
    property TableCount: Integer read GetTableCount;
    property Tables[Index: Integer]: TEmulTableDef read GetTable;
  end;




type
  TEmulSerialPort = class
  private
    FHandle: THandle;
    FPortName: string;
    FBaudRate: Integer;
    FTimeout: Integer;
    procedure ApplyCommState;
    procedure CheckOpened;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open(const APortName: string; ABaudRate: Integer);
    procedure Close;
    function Opened: Boolean;
    procedure Purge;
    procedure WriteData(const Data: AnsiString);
    function ReadChar(var C: AnsiChar): Boolean;
    function ReadCharTimeout(var C: AnsiChar; ATimeout: Integer): Boolean;
    function ReadExact(Count: Integer; ATimeout: Integer): AnsiString;
    property PortName: string read FPortName;
    property BaudRate: Integer read FBaudRate;
    property Timeout: Integer read FTimeout write FTimeout;
  end;




type
  TFptrTable = class;
  TFptrTables = class;
  TFptrCommand = class;
  TFptrCommands = class;
  TFptrPrintItem = class;
  TFptrPrintItems = class;

  { TFptrOperatorRec }

  TFptrOperatorRec = packed record
    Name: AnsiString;
    Password: Integer;
  end;

  { TFptrDepartmentRec }

  TFptrDepartmentRec = packed record
    Total: Int64;
  end;

  { TFptrReceipt }

  TFptrReceipt = class
  private
    FOpened: Boolean;
    FCharge: Int64;
    FDiscount: Int64;
    FRecType: Integer;
    FOperator: Integer;
    FOperations: Short;
    FDepartments: array [1..16] of TFptrDepartmentRec;

    procedure AddItem(AOperator: Integer; const Item: TFptrItemRec;
      ARecType: Integer);
    function GetDepartment(Value: Integer): Integer;
    function GetTotal: Int64;
  public
    procedure Reset;
    procedure Cancel(AOperator: Integer);
    procedure Open(AOperator, ARecType: Integer);
    procedure Buy(AOperator: Integer; const Item: TFptrItemRec);
    procedure Sale(AOperator: Integer; const Item: TFptrItemRec);
    procedure RetBuy(AOperator: Integer; const Item: TFptrItemRec);
    procedure RetSale(AOperator: Integer; const Item: TFptrItemRec);
    procedure Storno(AOperator: Integer; const Item: TFptrItemRec);
    function Close(AOperator: Integer; const Params: TFptrCloseReceipt): Int64;
    procedure MakeCharge(AOperator: Integer; const Charge: TFptrDiscount);
    procedure StornoCharge(AOperator: Integer; const Charge: TFptrDiscount);
    procedure MakeDiscount(AOperator: Integer; const Discount: TFptrDiscount);
    procedure StornoDiscount(AOperator: Integer; const Discount: TFptrDiscount);

    property Total: Int64 read GetTotal;
    property Opened: Boolean read FOpened;
    property RecType: Integer read FRecType;
    property Operator: Integer read FOperator;
    property Operations: Short read FOperations;
    property Charge: Int64 read FCharge;
    property Discount: Int64 read FDiscount;
  end;

  { TFptrEJournalRec }

  TFptrEJournalRec = packed record
    ErrorCode: Byte;
  end;

  { TFptrFirmwareRec }

  TFptrFirmwareRec = packed record
    Version: AnsiString;
    Build: Short;
    Date: TPrinterDate;
  end;

  { TFptrFiscalIDRec }

  TFptrFiscalIDRec = packed record
    Number: Int64;
    Valid: Boolean;
  end;

  { TFMRecord }

  TFMRecord = record
    RecType: Integer;
    Date: TPrinterDate;
  end;

  { TFMRecordResult }

  TFMRecordResult = record
    Operator: Byte;
    Data: TFMRecord;
  end;

  { TFptrFiscalMemoryRec }

  TFptrFiscalMemoryRec = packed record
    Flags: Byte;
    ErrorCode: Byte;
    Firmware: TFptrFirmwareRec;
    DayNumber: Short;
    FreeRecords: Short;
    FiscNumber: Short;
    LeftFiscNumber: Short;
    FiscalID: TFptrFiscalIDRec;

    SaleTotal: Int64;
    BuyTotal: Int64;
    RetSaleTotal: Int64;
    RetBuyTotal: Int64;

    GlobalSaleTotal: Int64;
    GlobalBuyTotal: Int64;
    GlobalRetSaleTotal: Int64;
    GlobalRetBuyTotal: Int64;


    LastRecord: TFMRecord;
  end;

  { TFptrSerialRec }

  TFptrSerialRec = packed record
    Valid: Boolean;
    Number: Integer;
  end;

  { TFptrPasswordRec }

  TFptrPasswordRec = packed record
    Valid: Boolean;
    Password: Integer;
  end;

  { TFptrLicenseRec }

  TFptrLicenseRec = record
    Valid: Boolean;
    Value: Int64;
  end;

  { TFptrPortRec }

  TFptrPortRec = record
    Number: Byte;
    BaudRate: Byte;
    Timeout: Byte;
  end;

  { TFptrAmountRegRec }

  TFptrAmountRegRec = record
    Operator: Byte;
    RegValue: Int64;
  end;

  { TFptrOperatingRegRec }

  TFptrOperatingRegRec = record
    Operator: Byte;
    RegValue: Word;
  end;

  { TFptrFieldRec }

  TFptrFieldRec = record
    Table: Integer;
    Row: Integer;
    Field: Integer;
    Value: AnsiString;
  end;

  { TFptrTableRec }

  TFptrTableRec = record
    Name: AnsiString;
    Number: Integer;
    RowCount: Integer;
    FieldCount: Integer;
  end;

  { TPrinterEmulator }

  TPrinterEmulator = class
  private
    FFlags: Short;
    FMode: Integer;
    FPort: TFptrPortRec;
    FStoreID: Integer;
    FSubMode: Integer;
    FDocNumber: Integer;
    FDate: TPrinterDate;
    FTime: TPrinterTime;
    FPortNumber: Integer;
    FReceipt: TFptrReceipt;
    FPowerVoltage: Integer;
    FSerial: TFptrSerialRec;
    FBatteryVoltage: Integer;
    FEJournal: TFptrEJournalRec;
    FFirmware: TFptrFirmwareRec;
    FCommands: TFptrCommands;
    FServicePassword: TFptrPasswordRec;
    FFiscalMemory: TFptrFiscalMemoryRec;
    FDeviceDumps: array [1..7] of string;
    FOperators: array [1..30] of TFptrOperatorRec;
    FReceiptLines: TFptrPrintItems;
    FJournalLines: TFptrPrintItems;
    FSlipLines: TFptrPrintItems;
    FAmountRegisters: array [Byte] of Int64;
    FOperatingRegisters: array [Byte] of Integer;
    FLicense: TFptrLicenseRec;
    FPointPosition: Integer;
    FDrawerOpened: Boolean;
    FFonts: array [1..7] of TFptrFontRec;
    FTables: TFptrTables;
    FDeviceMetrics: TFptrDeviceMetricsRec;
    FDayOpened: Boolean;
    FCashAmount: Int64;
    FEmulTables: TObject;
    FTableStorage: TObject;
    FFNState: TObject;
    FLongSerial: Int64;
    FSavedDumpMode: Integer;
    FReportInProgress: Boolean;

    function GetDeviceDump(Index: Integer): AnsiString;
    function GetMode4: Integer;
    function GetAmountRegister(Index: Integer): Int64;
    function GetOperatingRegister(Index: Integer): Integer;
    procedure WriteTablePassword(const Field: TFptrFieldRec);
    function GetOperator(Index: Integer): TFptrOperatorRec;
    function ReadTablePassword(const Field: TFptrFieldRec): TFptrFieldRec;
    procedure SetOperator(Index: Integer; const Value: TFptrOperatorRec);
    class function ValidTime(const Time: TPrinterTime): Boolean;
    class function ValidDate(const Date: TPrinterDate): Boolean;
    procedure InitializeTables;
    function GetFont(Index: Integer): TFptrFontRec;
    procedure SetFont(Index: Integer; const Value: TFptrFontRec);
    procedure CheckItem(const Item: TFptrItemRec);
    procedure CheckReceiptOpened;
    function GetDate: TPrinterDate;
    function GetTime: TPrinterTime;
    function GetSerial: TFptrSerialRec;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;
    procedure SaveToFile(const FileName: AnsiString);
    procedure LoadFromFile(const FileName: AnsiString);
    procedure ApplyTables(ATables: TObject);
    procedure ApplyOperatorPasswords;
    function ReadFieldStruct(Password, TableNumber, FieldNumber: Integer;
      out Def: TEmulFieldDef): Boolean;
    procedure SendCommand(var Data: AnsiString; Timeout: Integer);
    function Execute(const Data: AnsiString; Timeout: Integer): AnsiString;
    procedure PrintBoldLine(Flags: Byte; const Line: AnsiString);
    procedure PrintLine(Flags: Byte; const Line: AnsiString; Font: Byte);
    function FindOperator(Password, MinIndex: Integer): Integer;
    procedure PrintDocHeader(const DocName: AnsiString; DocNumber: Integer);
    procedure ResetStatus;
    function StartTest(Password, Period: Integer): Integer;
    function Beep(Password: Integer): Integer;
    function ReadCashReg(Password, RegNumber: Integer): TFptrAmountRegRec;
    function ReadOperatingReg(Password, RegNumber: Integer): TFptrOperatingRegRec;
    procedure WriteLicense(Password: Integer; ALicense: Int64);
    function ReadLicense(Password: Integer): Int64;
    procedure WriteTable(Password: Integer; const Field: TFptrFieldRec);
    function ReadTable(Password: Integer; const Field: TFptrFieldRec): TFptrFieldRec;
    procedure SetPointPosition(Password, APointPosition: Integer);
    procedure SetTime(Password: Integer; const ATime: TPrinterTime);
    procedure SetDate(Password: Integer; const ADate: TPrinterDate);
    procedure ConfirmDate(Password: Integer; const ADate: TPrinterDate);
    procedure InitTables(Password: Integer);
    function CutPaper(Password, CutType: Integer): Integer;
    function ReadFont(Password, FontNumber: Integer): TFptrFontRec;
    procedure TotalReset(Password: Integer);
    function OpenDrawer(Password, DrawerNumber: Integer): Integer;
    procedure CloseDrawer;
    function FeedPaper(Password, Flags, LineCount: Integer): Integer;
    function StopTest(Password: Integer): Integer;
    function PrintOperatingRegisters(Password: Integer): Integer;
    function ReadTableDef(Password, TableNumber: Integer): TFptrTableRec;
    procedure WriteServicePassword(OldPassword, NewPassword: Integer);
    function PrintBarcode(Password: Integer; Barcode: Int64): Integer;
    function OpenReceipt(Password, RecType: Integer): Integer;
    function PrintCopy(Password: Integer): Integer;
    function Sale(Password: Integer; const Item: TFptrItemRec): Integer;
    function Buy(Password: Integer; const Item: TFptrItemRec): Integer;
    function RetSale(Password: Integer; const Item: TFptrItemRec): Integer;
    function RetBuy(Password: Integer; const Item: TFptrItemRec): Integer;
    function Storno(Password: Integer; const Item: TFptrItemRec): Integer;
    function CloseReceipt(Password: Integer;
      const CloseReceipt: TFptrCloseReceipt): TFptrCloseReceiptResult;
    function Discount(Password: Integer; const Discount: TFptrDiscount): Integer;
    function StornoDiscount(Password: Integer; const Discount: TFptrDiscount): Integer;
    function Charge(Password: Integer; const Discount: TFptrDiscount): Integer;
    function StornoCharge(Password: Integer; const Discount: TFptrDiscount): Integer;
    function CancelReceipt(Password: Integer): Integer;
    function ReadSubtotal(Password: Integer): TFptrSubtotal;
    function XReport(Password: Integer): Integer;
    function ZReport(Password: Integer): Integer;
    function TaxReport(Password: Integer): Integer;
    function DepReport(Password: Integer): Integer;
    function CashIn(Password: Integer; Amount: Int64): TFptrDocResult;
    function CashOut(Password: Integer; Amount: Int64): TFptrDocResult;
    function PrintHeader(Password: Integer): Integer;
    function PrintDocEnd(Password, Parameter: Integer): Integer;
    function PrintTrailer(Password: Integer): Integer;
    procedure WriteSerial(Password, ASerial: Integer);
    function ReadFMTotals(Password, RequestType: Integer): TFMTotals;
    function OpenSession(Password: Integer): Integer;
    function ExecuteFNCommand(Code: Integer; const Data: AnsiString): AnsiString;
    function ExecuteFECommand(Code: Integer; const Data: AnsiString): AnsiString;
    function GetSessionNumber: Word;
    function GetFNKKTRegNumber: AnsiString;
    function GetFNINN: AnsiString;
    procedure ApplyFiscalFromTables;
    procedure ClearSlipDocument;

    property Flags: Short read FFlags;
    property Mode4: Integer read GetMode4;
    property Port: TFptrPortRec read FPort;
    property Tables: TFptrTables read FTables;
    property Date: TPrinterDate read GetDate;
    property StoreID: Integer read FStoreID;
    property SubMode: Integer read FSubMode;
    property DocNumber: Integer read FDocNumber;
    property PortNumber: Integer read FPortNumber;
    property Mode: Integer read FMode write FMode;
    property SlipLines: TFptrPrintItems read FSlipLines;
    property Serial: TFptrSerialRec read GetSerial;
    property Receipt: TFptrReceipt read FReceipt;
    property License: TFptrLicenseRec read FLicense;
    property PowerVoltage: Integer read FPowerVoltage;
    property EJournal: TFptrEJournalRec read FEJournal;
    property Firmware: TFptrFirmwareRec read FFirmware;
    property ReceiptLines: TFptrPrintItems read FReceiptLines;
    property JournalLines: TFptrPrintItems read FJournalLines;
    property BatteryVoltage: Integer read FBatteryVoltage;
    property DeviceDumps[Index: Integer]: AnsiString read GetDeviceDump;
    property AmountRegisters[Index: Integer]: Int64 read GetAmountRegister;
    property Time: TPrinterTime read GetTime;
    property PointPosition: Integer read FPointPosition write FPointPosition;
    property OperatingRegisters[Index: Integer]: Integer read GetOperatingRegister;
    property FiscalMemory: TFptrFiscalMemoryRec read FFiscalMemory write FFiscalMemory;
    property Operators[Index: Integer]: TFptrOperatorRec read GetOperator write SetOperator;
    property Fonts[Index: Integer]: TFptrFontRec read GetFont write SetFont;
    property DrawerOpened: Boolean read FDrawerOpened;
    property DeviceMetrics: TFptrDeviceMetricsRec read FDeviceMetrics;
    property ServicePassword: TFptrPasswordRec read FServicePassword write FServicePassword;
    property LongSerial: Int64 read FLongSerial write FLongSerial;
    property SavedDumpMode: Integer read FSavedDumpMode write FSavedDumpMode;
    property ReportInProgress: Boolean read FReportInProgress write FReportInProgress;
    property DayOpened: Boolean read FDayOpened;
    property CashAmount: Int64 read FCashAmount;
  end;

  { TFptrTable }

  TFptrTable = class
  private
    FOwner: TFptrTables;
    FData: TFptrTableRec;
    procedure SetOwner(AOwner: TFptrTables);
  public
    constructor Create(AOwner: TFptrTables; const AData: TFptrTableRec);
    destructor Destroy; override;

    property Data: TFptrTableRec read FData;
    property Name: AnsiString read FData.Name;
    property Number: Integer read FData.Number;
    property RowCount: Integer read FData.RowCount;
    property FieldCount: Integer read FData.FieldCount;
  end;

  { TFptrTables }

  TFptrTables = class
  private
    FList: TList;
    procedure Clear;
    function GetCount: Integer;
    procedure InsertItem(AItem: TFptrTable);
    procedure RemoveItem(AItem: TFptrTable);
    function GetItem(Index: Integer): TFptrTable;
  public
    constructor Create;
    destructor Destroy; override;
    function ItemByNumber(Number: Integer): TFptrTable;
    function Add(const AData: TFptrTableRec): TFptrTable;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFptrTable read GetItem; default;
  end;

  { TFptrPrintItem }

  TFptrPrintItem = class
  private
    FOwner: TFptrPrintItems;
    procedure SetOwner(AOwner: TFptrPrintItems);
  public
    constructor Create(AOwner: TFptrPrintItems); virtual;
    destructor Destroy; override;
  end;

  { TFptrLine }

  TFptrLine = class(TFptrPrintItem)
  private
    FFont: Byte;
    FLine: AnsiString;
  public
    constructor Create2(AOwner: TFptrPrintItems; const ALine: AnsiString; AFont: Integer);
    property Font: Byte read FFont;
    property Line: AnsiString read FLine;
  end;

  { TFptrBarcode }

  TFptrBarcode = class(TFptrPrintItem)
  private
    FBarcode: Int64;
  public
    constructor Create2(AOwner: TFptrPrintItems; ABarcode: Int64);
    property Barcode: Int64 read FBarcode;
  end;

  { TFptrCut }

  TFptrCut = class(TFptrPrintItem)
  private
    FCutType: Integer;
  public
    constructor Create2(AOwner: TFptrPrintItems; ACutType: Integer);
    property CutType: Integer read FCutType;
  end;

  { TFptrFeed }

  TFptrFeed = class(TFptrPrintItem)
  private
    FLineCount: Integer;
  public
    constructor Create2(AOwner: TFptrPrintItems; ALineCount: Integer);
    property LineCount: Integer read FLineCount;
  end;

  { TFptrPrintItems }

  TFptrPrintItems = class
  private
    FList: TList;
    procedure Clear;
    function GetCount: Integer;
    procedure InsertItem(AItem: TFptrPrintItem);
    procedure RemoveItem(AItem: TFptrPrintItem);
    function GetItem(Index: Integer): TFptrPrintItem;
  public
    constructor Create;
    destructor Destroy; override;
    function AddCut(ACutType: Integer): TFptrCut;
    function AddFeed(ALineCount: Integer): TFptrFeed;
    function AddBarcode(ABarcode: Int64): TFptrBarcode;
    function AddLine(const ALine: AnsiString; AFont: Integer): TFptrLine;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFptrPrintItem read GetItem; default;
  end;

  { TFptrCommand }

  TFptrCommand = class
  private
    FOwner: TFptrCommands;
    procedure SetOwner(AOwner: TFptrCommands);
  public
    constructor Create(AOwner: TFptrCommands);
    destructor Destroy; override;

    function GetCode: Integer; virtual; abstract;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; virtual; abstract;

    property Code: Integer read GetCode;
  end;

  { TFptrCommands }

  TFptrCommands = class
  private
    FList: TList;
    procedure Clear;
    function GetCount: Integer;
    function GetItem(Index: Integer): TFptrCommand;
    procedure InsertItem(AItem: TFptrCommand);
    procedure RemoveItem(AItem: TFptrCommand);
  public
    constructor Create;
    destructor Destroy; override;
    function ItemByCode(Code: Integer): TFptrCommand;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFptrCommand read GetItem; default;
  end;

  { TFptrFrame }

  TFptrFrame = class
  private
    class function GetCRC(const Data: AnsiString): Byte;
  public
    class function Encode(const Data: AnsiString): AnsiString;
    class function Decode(const Data: AnsiString): AnsiString;
  end;

  { EFptrError }

  EFptrError = class(Exception)
  private
   FErrorCode: Byte;
  public
    constructor Create2(Code: Byte; const Msg: AnsiString);
    property ErrorCode: Byte read FErrorCode write FErrorCode;
  end;

  { TFptrCommand_01h }

  TFptrCommand_01h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_02h }

  TFptrCommand_02h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_10h }

  TFptrCommand_10h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_11h }

  TFptrCommand_11h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_12h }

  TFptrCommand_12h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_13h }

  TFptrCommand_13h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_14h }

  TFptrCommand_14h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_15h }

  TFptrCommand_15h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_16h }

  TFptrCommand_16h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_17h }

  TFptrCommand_17h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_18h }

  TFptrCommand_18h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_19h }

  TFptrCommand_19h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Ah }

  TFptrCommand_1Ah = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Bh }

  TFptrCommand_1Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Ch }

  TFptrCommand_1Ch = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Dh }

  TFptrCommand_1Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Eh }

  TFptrCommand_1Eh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Fh }

  TFptrCommand_1Fh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_20h }

  TFptrCommand_20h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_21h }

  TFptrCommand_21h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_22h }

  TFptrCommand_22h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_23h }

  TFptrCommand_23h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_24h }

  TFptrCommand_24h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_25h }

  TFptrCommand_25h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_26h }

  TFptrCommand_26h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_27h }

  TFptrCommand_27h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_28h }

  TFptrCommand_28h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_29h }

  TFptrCommand_29h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Bh }

  TFptrCommand_2Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Ch }

  TFptrCommand_2Ch = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Dh }

  TFptrCommand_2Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Eh }

  TFptrCommand_2Eh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Fh }

  TFptrCommand_2Fh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_40h }

  TFptrCommand_40h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_41h }

  TFptrCommand_41h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_42h }

  TFptrCommand_42h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_43h }

  TFptrCommand_43h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_50h }

  TFptrCommand_50h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_51h }

  TFptrCommand_51h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_52h }

  TFptrCommand_52h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_53h }

  TFptrCommand_53h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_54h }

  TFptrCommand_54h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_60h }

  TFptrCommand_60h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_62h }

  TFptrCommand_62h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_63h }

  TFptrCommand_63h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_F3h }

  TFptrCommand_F3h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_FCh }

  TFptrCommand_FCh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_C2h }

  TFptrCommand_C2h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Dh }

  TFptrCommand_8Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Ch }

  TFptrCommand_8Ch = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_80h }

  TFptrCommand_80h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_81h }

  TFptrCommand_81h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_82h }

  TFptrCommand_82h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_83h }

  TFptrCommand_83h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_84h }

  TFptrCommand_84h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_85h }

  TFptrCommand_85h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_86h }

  TFptrCommand_86h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_87h }

  TFptrCommand_87h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_88h }

  TFptrCommand_88h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_89h }

  TFptrCommand_89h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Ah }

  TFptrCommand_8Ah = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Bh }

  TFptrCommand_8Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;




type
  TEmulFNDocument = record
    DocNumber: Cardinal;
    FiscalSign: Cardinal;
    DocType: Byte;
    SessionNumber: Word;
    ReceiptNumber: Word;
    Data: AnsiString;
  end;

  TEmulFNState = class
  private
    FDocuments: array of TEmulFNDocument;
    FDocCount: Integer;
    FReceiptTotal: Int64;
    FReceiptOpened: Boolean;
    FCheckType: Byte;
    FTLVBuffer: AnsiString;
    FDataBuffer: AnsiString;
    FDataBlockSize: Integer;
    FRandomSequence: AnsiString;
    FNotificationCount: Word;
    FNotificationNumber: Cardinal;
    FNotificationSize: Word;
    FNotificationOffset: Word;

    function NextDocNumber: Cardinal;
    function NextFiscalSign: Cardinal;
    function BuildDateTime5(Device: TObject): AnsiString;
    function PadRight(const S: AnsiString; Len: Integer): AnsiString;
    function RequireOperator(Device: TObject; const Data: AnsiString;
      out Operator: Integer): AnsiString;
    function OkOnly: AnsiString;
    function OkOperator(Operator: Integer): AnsiString;
    function CloseCheckResult(Total, CashPay: Int64): AnsiString;
    procedure SaveDocument(DocType: Byte; SessionNum: Word; ReceiptNum: Word);
    function FindDocument(DocNum: Cardinal; out Doc: TEmulFNDocument): Boolean;
  public
    LifeState: Byte;
    CurrentDocument: Byte;
    DocumentData: Byte;
    SessionState: Byte;
    WarningFlags: Byte;
    FNSerial: AnsiString;
    SoftVersion: AnsiString;
    SoftType: Byte;
    INN: AnsiString;
    KKTRegNumber: AnsiString;
    TaxType: Byte;
    WorkMode: Byte;
    WorkModeEx: Byte;
    SessionNumber: Word;
    ReceiptNumber: Word;
    DocumentNumber: Cardinal;
    FiscalSign: Cardinal;
    ExpirationDay: Byte;
    ExpirationMonth: Byte;
    ExpirationYear: Byte;
    FreeRegistration: Byte;
    RegNumber: Byte;
    UnconfirmedDocCount: Cardinal;
    InfoExchangeStatus: Byte;
    MessageState: Byte;
    MessageCount: Word;
    FN5YearResource: Cardinal;
    FN30DayResource: Cardinal;
    FNImplementation: AnsiString;

    constructor Create;
    procedure Reset;
    procedure SyncFromDevice(Device: TObject);
    procedure OnLegacySessionOpen;
    procedure OnLegacySessionClose;
    procedure OnLegacyReceiptOpen(RecType: Integer);
    procedure OnLegacyReceiptClosed(Total: Int64);
    function ExecuteCommand(Code: Integer; Device: TObject;
      const Data: AnsiString): AnsiString;
  end;




type
  TFptrFECommand = class(TFptrCommand)
  private
    FCode: Integer;
  public
    constructor Create(AOwner: TFptrCommands; ACode: Integer);
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

function EmulFEExecute(Device: TPrinterEmulator; Code: Integer;
  const Data: AnsiString): AnsiString;
procedure RegisterFECommands(Commands: TFptrCommands);




type
  TFptrFNCommand = class(TFptrCommand)
  private
    FCode: Integer;
  public
    constructor Create(AOwner: TFptrCommands; ACode: Integer);
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

procedure RegisterFNCommands(Commands: TFptrCommands);




type
  TFptrCommand_E0h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_03h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_0Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_0Eh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_0Fh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_2Ah = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_57h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_61h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_64h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_65h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_66h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_67h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_68h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_69h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_6Ah = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_6Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_Slip = class(TFptrCommand)
  private
    FCode: Integer;
  public
    constructor Create(AOwner: TFptrCommands; ACode: Integer);
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_Fuel = class(TFptrCommand)
  private
    FCode: Integer;
  public
    constructor Create(AOwner: TFptrCommands; ACode: Integer);
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_Graphics = class(TFptrCommand)
  private
    FCode: Integer;
  public
    constructor Create(AOwner: TFptrCommands; ACode: Integer);
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_D0h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_D1h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_F0h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_F1h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_F7h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

  TFptrCommand_FDh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator;
      const Data: AnsiString): AnsiString; override;
  end;

procedure RegisterAllProtocolCommands(Commands: TFptrCommands);




const
  STX = #2;
  ENQ = #5;
  ACK = #6;
  NAK = #21;

type
  TEmulProtocolServer = class(TThread)
  private
    FPort: TEmulSerialPort;
    FDevice: TPrinterEmulator;
    FActive: Boolean;
    FResponse: AnsiString;
    FHasResponse: Boolean;
    function GetCRC(const Data: AnsiString): Byte;
    function EncodeFrame(const Data: AnsiString): AnsiString;
    function ReadExact(Count: Integer): AnsiString;
    procedure WriteByte(B: AnsiChar);
    procedure ProcessCommand(const Command: AnsiString);
    function NeedsResponse(const Command, Response: AnsiString): Boolean;
    procedure SendResponse;
  protected
    procedure Execute; override;
  public
    constructor Create(ADevice: TPrinterEmulator; APort: TEmulSerialPort);
    procedure StopServer;
    property Active: Boolean read FActive;
  end;




const
  DEF_EMUL_PORT = 'COM8';
  DEF_DRIVER_PORT = 'COM7';
  DEF_BAUD_RATE = 7;

type
  TFREmulator = class
  private
    FDevice: TPrinterEmulator;
    FTables: TEmulTables;
    FPort: TEmulSerialPort;
    FServer: TEmulProtocolServer;
    FPortName: string;
    FBaudRate: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadTables(const FileName: string);
    procedure Start(const APortName: string = DEF_EMUL_PORT; ABaudRate: Integer = DEF_BAUD_RATE);
    procedure Stop;
    function Running: Boolean;
    property Device: TPrinterEmulator read FDevice;
    property Tables: TEmulTables read FTables;
    property PortName: string read FPortName;
  end;


implementation


function Min(V1, V2: Integer): Integer;
begin
  if V1 < V2 then
    Result := V1
  else
    Result := V2;
end;

function BinToInt(const S: AnsiString; Index, Count: Integer): Int64;
var
  N: Integer;
begin
  Result := 0;
  if (Index > 0) and (Index <= Length(S)) then
  begin
    N := Min(Length(S) - Index + 1, 8);
    if Count <= N then
      Move(S[Index], Result, Count);
  end;
end;

function IntToBin(Value, Count: Int64): AnsiString;
begin
  Result := '';
  if Count in [1..8] then
  begin
    SetLength(Result, Count);
    Move(Value, Result[1], Count);
  end;
end;



procedure SetBit(var Value: Word; Bit: Byte);
begin
  Value := Value or (1 shl Bit);
end;

function TestBit(Value, Bit: Integer): Boolean;
begin
  Result := (Value and (1 shl Bit)) <> 0;
end;

function EncodePrinterFlags(Flags: TPrinterFlags): Word;
begin
  Result := 0;
  if not Flags.JrnNearEnd then SetBit(Result, 0);
  if not Flags.RecNearEnd then SetBit(Result, 1);
  if Flags.SlpUpSensor then SetBit(Result, 2);
  if Flags.SlpLoSensor then SetBit(Result, 3);
  if Flags.DecimalPosition then SetBit(Result, 4);
  if not Flags.EJPresent then SetBit(Result, 5);
  if not Flags.JrnEmpty then SetBit(Result, 6);
  if not Flags.RecEmpty then SetBit(Result, 7);
  if not Flags.JrnLeverUp then SetBit(Result, 8);
  if not Flags.RecLeverUp then SetBit(Result, 9);
  if Flags.CoverOpened then SetBit(Result, 10);
  if Flags.DrawerOpened then SetBit(Result, 11);
  if Flags.Bit12 then SetBit(Result, 12);
  if Flags.Bit13 then SetBit(Result, 13);
  if Flags.EJNearEnd then SetBit(Result, 14);
  if Flags.Bit15 then SetBit(Result, 15);
end;

function DecodePrinterFlags(Flags: Word): TPrinterFlags;
begin
  Result.JrnNearEnd := not TestBit(Flags, 0);
  Result.RecNearEnd := not TestBit(Flags, 1);
  Result.SlpUpSensor := TestBit(Flags, 2);
  Result.SlpLoSensor := TestBit(Flags, 3);
  Result.DecimalPosition := TestBit(Flags, 4);
  Result.EJPresent := not TestBit(Flags, 5);
  Result.JrnEmpty := not TestBit(Flags, 6);
  Result.RecEmpty := not TestBit(Flags, 7);
  Result.JrnLeverUp := not TestBit(Flags, 8);
  Result.RecLeverUp := not TestBit(Flags, 9);
  Result.CoverOpened := TestBit(Flags, 10);
  Result.DrawerOpened := TestBit(Flags, 11);
  Result.Bit12 := TestBit(Flags, 12);
  Result.Bit13 := TestBit(Flags, 13);
  Result.EJNearEnd := TestBit(Flags, 14);
  Result.Bit15 := TestBit(Flags, 15);
end;


function IntToBool(Value: Integer): Boolean;
begin
  Result := Value <> 0;
end;

function GetErrorText(Code: Integer): string;
begin
  case Code of
// 0x00
    $00: Result := 'No errors';
    $01: Result := 'FM1, FM2 or RTC error';
    $02: Result := 'FM1 missing';
    $03: Result := 'FM2 missing';
    $04: Result := 'Incorrect parameters in FM command';
    $05: Result := 'No data requested available';
    $06: Result := 'FM is in data output mode';
    $07: Result := 'Invalid FM command parameters';
    $08: Result := 'Command is not supported by FM';
    $09: Result := 'Invalid command length';
    $0A: Result := 'Data format is not BCD';
    $0B: Result := 'FM memory cell failure';
// 0x10
    $11: Result := 'License in not entered';
    $12: Result := 'Serial number is already entered';
    $13: Result := 'Current date is less than last FM record date';
    $14: Result := 'FM shift sum area overflow';
    $15: Result := 'Shift is already opened';
    $16: Result := 'Shift is not opened';
    $17: Result := 'First shift number is larger than last shift number';
    $18: Result := 'First shift date is larger than last shift date';
    $19: Result := 'No FM data available';
    $1A: Result := 'FM fiscal area overflow';
    $1B: Result := 'Serial number is not assigned';
    $1C: Result := 'There is corrupted record in the defined range';
    $1D: Result := 'Last shift sum record is corrupted';
    $1E: Result := 'FM fiscal area overflow';
    $1F: Result := 'Registers memory is missing';
// 0x20
    $20: Result := 'Cash register overflow after add';
    $21: Result := 'Subtract summ is larger then cash register value';
    $22: Result := 'Invalid date';
    $23: Result := 'Activation record is not found';
    $24: Result := 'Activation area overflow';
    $25: Result := 'Activation with requested number is not found';
    $26: Result := 'Client pay sum is less than receipt sum';
    $27: Result := 'FM CRC are corrupted';
    $2B: Result := 'Unable to cancel previous command';
    $2C: Result := 'ECR is zero out (re-clearing is not available)';
    $2D: Result := 'Department receipt sum is less than void sum';
    $2F: Result := 'EKLZ not answered';
// 0x30
    $30: Result := 'ECR is blocked. Waiting for enter tax password';
    $32: Result := 'Common clearing is needed';
    $33: Result := 'Incorrect command parameters';
    $34: Result := 'No data';
    $35: Result := 'Incorrect command parameters for this settings';
    $36: Result := 'Incorrect command parameters for this ECR implementation';
    $37: Result := 'Command is not supported';
    $38: Result := 'PROM error';
    $39: Result := 'Internal software error';
    $3A: Result := 'Shift charge sum overflow';
    $3B: Result := 'Shift sum overflow';
    $3C: Result := 'EKLZ: Invalid registration number';
    $3D: Result := 'Shift is closed. Command is invalid';
    $3E: Result := 'Shift Department sum overflow';
    $3F: Result := 'Shift discount sum overflow';
// 0x40
    $40: Result := 'Discount range overflow';
    $41: Result := 'Cash pay range overflow';
    $42: Result := 'Pay type 2 range overflow';
    $43: Result := 'Pay type 3 range overflow';
    $44: Result := 'Pay type 4 range overflow';
    $45: Result := 'All payment types sum is less than receipt sum';
    $46: Result := 'No cash in ECR';
    $47: Result := 'Shift tax sum overflow';
    $48: Result := 'Receipt sum overflow';
    $49: Result := 'Command is invalid in opened receipt of this type';
    $4A: Result := 'Receipt is opened. Command is invalid';
    $4B: Result := 'Receipt buffer overflow';
    $4C: Result := 'Shift total tax sum overflow';
    $4D: Result := 'Cashless sum is larger than receipt sum';
    $4E: Result := '24 hours over';
    $4F: Result := 'Invalid password';
// 0x50
    $50: Result := 'Previous command is printing now';
    $51: Result := 'Shift cash sum overflow';
    $52: Result := 'Shift pay type 2 sum overflow';
    $53: Result := 'Shift pay type 3 sum overflow';
    $54: Result := 'Shift pay type 4 sum overflow';
    $55: Result := 'Receipt is closed. Command is invalid';
    $56: Result := 'There is no document to repeat';
    $57: Result := 'Closed shift count in EJ does not correspont to FM shift count';
    $58: Result := 'Waiting for continue print command';
    $59: Result := 'Document is opened by another operator';
    $5A: Result := 'Discount sum is larger than receipt sum';
    $5B: Result := 'Charge range overflow';
    $5C: Result := 'Low supply voltage, 24v';
    $5D: Result := 'Table is undefined';
    $5E: Result := 'Invalid command';
    $5F: Result := 'Negative receipt sum';
// 0x60
    $60: Result := 'Multiplication overflow';
    $61: Result := 'Price range overflow';
    $62: Result := 'Quantity range overflow';
    $63: Result := 'Department range overflow';
    $64: Result := 'FM is missing';
    $65: Result := 'Insufficient cash in Department';
    $66: Result := 'Department cash overflow';
    $67: Result := 'FM connection error';
    $68: Result := 'Insufficient tax sum';
    $69: Result := 'Tax sum overflow';
    $6A: Result := 'Supply error when I2C active';
    $6B: Result := 'No receipt paper';
    $6C: Result := 'No journal paper';
    $6D: Result := 'Insufficient tax sum';
    $6E: Result := 'Tax sum overflow';
    $6F: Result := 'Shift cash out overflow';
// 0x70
    $70: Result := 'FM overflow';
    $71: Result := 'Cutter failure';
    $72: Result := 'Command is not supported in this submode';
    $73: Result := 'Command is not supported in this mode';
    $74: Result := 'RAM failure';
    $75: Result := 'Supply failure';
    $76: Result := 'Printer failure: no impulse from tachometer generator';
    $77: Result := 'Printer failure: no signal from sensors';
    $78: Result := 'Software replaced';
    $79: Result := 'FM replaced';
    $7A: Result := 'Field is not editable';
    $7B: Result := 'Hardware failure';
    $7C: Result := 'Date does not match';
    $7D: Result := 'Invalid date format';
    $7E: Result := 'Invalid value in length field';
    $7F: Result := 'Receipt total sum range overflow';
// 0x80
    $80: Result := 'FM connection error';
    $81: Result := 'FM connection error';
    $82: Result := 'FM connection error';
    $83: Result := 'FM connection error';
    $84: Result := 'Cash sum overflow';
    $85: Result := 'Shift sale sum overflow';
    $86: Result := 'Shift buy sum overflow';
    $87: Result := 'Shift return sale sum overflow';
    $88: Result := 'Shift return buy sum overflow';
    $89: Result := 'Shift cash in sum overflow';
    $8A: Result := 'Receipt charge sum overflow';
    $8B: Result := 'Receipt discount sum overflow';
    $8C: Result := 'Negative receipt charge sum';
    $8D: Result := 'Negative receipt discount sum';
    $8E: Result := 'Zero receipt sum';
    $8F: Result := 'ECR is not fiscal';
// 0x90
    $90: Result := 'Field size is larger than settings value';
    $91: Result := 'Out of printing field area for this font settings';
    $92: Result := 'Field overlay';
    $93: Result := 'RAM recovery successful';
    $94: Result := 'Receipt operation count overflow';
// 0xA0
    $A0: Result := 'EJ connection error';
    $A1: Result := 'EJ is missing';
    $A2: Result := 'EJ: Invalid parameter or command format';
    $A3: Result := 'Invalid EJ state';
    $A4: Result := 'EJ failure';
    $A5: Result := 'EJ cryptoprocessor failure';
    $A6: Result := 'EJ Time limit exceeded';
    $A7: Result := 'EJ overflow';
    $A8: Result := 'EJ: invalid date and time';
    $A9: Result := 'EJ: no requested data available';
    $AA: Result := 'EJ overflow (negative document sum)';
// 0xB0
    $B0: Result := 'EJ: Quantity parameter overflow';
    $B1: Result := 'EJ: Sum parameter overflow';
    $B2: Result := 'EJ: Already activated';
// 0xC0
    $C0: Result := 'Date and time control(confirm date and time)';
    $C1: Result := 'EJ: Z-report is not interruptable';
    $C2: Result := 'Exceeding supply voltage';
    $C3: Result := 'Receipt sum and EJ sum mismatch';
    $C4: Result := 'Shift numbers mismatch';
    $C5: Result := 'Slip buffer is empty';
    $C6: Result := 'Slip is missing';
    $C7: Result := 'Field is not editable in this mode';
    $C8: Result := 'No impulses from tachometer sensor';
// 0xE0
    $E0: Result := 'Cash acceptor connection error';
    $E1: Result := 'Cash acceptor is busy';
    $E2: Result := 'Receipt sum does not correspond to cash acceptor sum';
    $E3: Result := 'Cash acceptor error';
    $E4: Result := 'Cash acceptor sum is not zero';
  else
    Result := 'Unknown error';
  end;
end;

resourcestring
  SPaperPresented = '˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜';
  SPassivePaperAbsense = '˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜';
  SActivePaperAbsence = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜';
  SAfterActivePaperAbsence = '˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜';
  SLongReportPrintingStage = '˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜';
  SOperationPrintingStage = '˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜';
  SUnknownDeviceSubmode = '˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ (%d)';

function GetAdvancedModeDescription(Value: Integer): string;
var
  Res: string;
begin
  Result := '';
  case Value of
    0: Res := SPaperPresented;
    1: Res := SPassivePaperAbsense;
    2: Res := SActivePaperAbsence;
    3: Res := SAfterActivePaperAbsence;
    4: Res := SLongReportPrintingStage;
    5: Res := SOperationPrintingStage;
  else
    Result := Format(SUnknownDeviceSubmode, [Value]);
  end;
  if Result = '' then
    Result := Res;
end;


resourcestring
  SFMAccumulator1 = '˜˜˜˜˜˜˜˜˜˜ ˜˜1';
  SFMAccumulator2 = '˜˜˜˜˜˜˜˜˜˜ ˜˜2';
  SClock = '˜˜˜˜';
  SVNRAM = 'VNRAM';
  SFMProcessor = '˜˜˜˜˜˜˜˜˜ ˜˜';
  SECRSoftMemory = '˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜';
  SECRRAM = '˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜';
  SUnknownDeviceCode = '˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜˜˜ (%d)';

function GetDeviceCodeDescription(Value: Integer): string;
var
  Res: string;
begin
  Result := '';
  case Value of
    1: Res := SFMAccumulator1;
    2: Res := SFMAccumulator2;
    3: Res := SClock;
    4: Res := SVNRAM;
    5: Res := SFMProcessor;
    6: Res := SECRSoftMemory;
    7: Res := SECRRAM;
  else
    Result := Format(SUnknownDeviceCode, [Value]);
  end;
  if Result = '' then
    Result := Res;
end;

resourcestring
  SDataDumping = '˜˜˜˜˜˜ ˜˜˜˜˜˜';
  SOpenedDayNot24hOver = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜, 24 ˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜';
  SOpenedDay24hOver = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜, 24 ˜˜˜˜ ˜˜˜˜˜˜˜˜˜';
  SClosedDay = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜';
  SBlockingByWrongPassword = '˜˜˜˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜';
  SWaitingForDateConfirm = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ ˜˜˜˜';
  SPermissionToChangeDecimalPoint = '˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜';
  SOpenedDocumentSale = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜: ˜˜˜˜˜˜˜';
  STechResetPermissionMode = '˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜';
  STestPassing = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜';
  SFullReportPrinting = '˜˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜';
  SEJReportPrinting = '˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜˜˜';
  SSalesSlipOpened = '˜˜˜˜˜˜˜˜ ˜˜: ˜˜˜˜˜˜˜';
  SWaitingForSlipCarge = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜';
  SSlipIsFormed = '˜˜ ˜˜˜˜˜˜˜˜˜˜˜';
  SOpenedDocumentBuy = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜: ˜˜˜˜˜˜˜';
  SOpenedBuySlip = '˜˜˜˜˜˜˜˜ ˜˜: ˜˜˜˜˜˜˜';
  SSlipLoadingAndPositioning = '˜˜˜˜˜˜˜˜ ˜ ˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜';
  SOpenedDocumentSaleReturn = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜: ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜';
  SOpenedSaleReturnSlip = '˜˜˜˜˜˜˜˜ ˜˜: ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜';
  SSlipPositioning = '˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜';
  SOpenedDocumentBuyReturn = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜: ˜˜˜˜˜˜˜';
  SOpenedBuyReturnSlip = '˜˜˜˜˜˜˜˜ ˜˜: ˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜';
  SSlipPrinting = '˜˜˜˜˜˜ ˜˜';
  SSlipPrintingIsFinished = '˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜˜˜';
  SSlipEject = '˜˜˜˜˜˜ ˜˜';
  SWaitingForSlipEject = '˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜';
  SUnknownMode = '˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜ (%d)';

function GetModeDescription(Value: Integer): string;
var
  Res: string;
begin
  Result := '';
  case Value of
    $01: Res := SDataDumping;
    $02: Res := SOpenedDayNot24hOver;
    $03: Res := SOpenedDay24hOver;
    $04: Res := SClosedDay;
    $05: Res := SBlockingByWrongPassword;
    $06: Res := SWaitingForDateConfirm;
    $07: Res := SPermissionToChangeDecimalPoint;
    $08: Res := SOpenedDocumentSale;
    $09: Res := STechResetPermissionMode;
    $0A: Res := STestPassing;
    $0B: Res := SFullReportPrinting;
    $0C: Res := SEJReportPrinting;
    $0D: Res := SSalesSlipOpened;
    $0E: Res := SWaitingForSlipCarge;
    $0F: Res := SSlipIsFormed;
    $18: Res := SOpenedDocumentBuy;
    $1D: Res := SOpenedBuySlip;
    $1E: Res := SSlipLoadingAndPositioning;
    $28: Res := SOpenedDocumentSaleReturn;
    $2D: Res := SOpenedSaleReturnSlip;
    $2E: Res := SSlipPositioning;
    $38: Res := SOpenedDocumentBuyReturn;
    $3D: Res := SOpenedBuyReturnSlip;
    $3E: Res := SSlipPrinting;
    $4C: Res := SSlipPrintingIsFinished;
    $5E: Res := SSlipEject;
    $6E: Res := SWaitingForSlipEject;
  else
    Result := Format(SUnknownMode, [Value]);
  end;
  if Result = '' then
    Result := Res;
end;

{ Get command name }

{function GetCommandName(Command: Integer): string;
begin
  case Command of
    $01: Result := 'Get dump';
    $02: Result := 'Get data block from dump';
    $03: Result := 'Interrupt data stream';
    $0D: Result := 'Fiscalization/refiscalization with long ECRRN';
    $0E: Result := 'Set long serial number';
    $0F: Result := 'Get long serial number and long ECRRN';
    $10: Result := 'Get short ECR status';
    $11: Result := 'Get ECR status';
    $12: Result := 'Print bold string';
    $13: Result := 'Beep';
    $14: Result := 'Set communication parameters';
    $15: Result := 'Read communication parameters';
    $16: Result := 'Technological reset';
    $17: Result := 'Print string';
    $18: Result := 'Print document header';
    $19: Result := 'Test run';
    $1A: Result := 'Get cash totalizer value';
    $1B: Result := 'Get operation totalizer value';
    $1C: Result := 'Write license';
    $1D: Result := 'Read license';
    $1E: Result := 'Write table';
    $1F: Result := 'Read table';
    $20: Result := 'Set decimal point position';
    $21: Result := 'Set clock time';
    $22: Result := 'Set calendar date';
    $23: Result := 'Confirm date';
    $24: Result := 'Initialize tables with default values';
    $25: Result := 'Cut receipt';
    $26: Result := 'Get font parameters';
    $27: Result := 'Common clear';
    $28: Result := 'Open cash drawer';
    $29: Result := 'Feed';
    $2A: Result := 'Eject slip';
    $2B: Result := 'Interrupt test';
    $2C: Result := 'Print operation totalizers report';
    $2D: Result := 'Get table structure';
    $2E: Result := 'Get field structure';
    $2F: Result := 'Print string with font';
    $40: Result := 'Daily report without cleaning';
    $41: Result := 'Daily report with cleaning';
    $42: Result := 'Print Department report';
    $43: Result := 'Print tax report';
    $50: Result := 'Cash in';
    $51: Result := 'Cash out';
    $52: Result := 'Print fixed document header';
    $53: Result := 'Print document footer';
    $54: Result := 'Print trailer';
    $60: Result := 'Set serial number';
    $61: Result := 'Initialize FM';
    $62: Result := 'Get FM totals';
    $63: Result := 'Get last FM record date';
    $64: Result := 'Get dates and sessions range';
    $65: Result := 'Fiscalization/refiscalization';
    $66: Result := 'Fiscal report in dates range';
    $67: Result := 'Fiscal report in shifts range';
    $68: Result := 'Interrupt full report';
    $69: Result := 'Get fiscalization parameters';
    $70: Result := 'Open fiscal slip';
    $71: Result := 'Open standard fiscal slip';
    $72: Result := 'Transaction on slip';
    $73: Result := 'Standard transaction on slip';
    $74: Result := 'Discount/charge on slip';
    $75: Result := 'Standard discount/charge on slip';
    $76: Result := 'Close fiscal slip';
    $77: Result := 'Close standard fiscal slip';
    $78: Result := 'Slip configuration';
    $79: Result := 'Standard slip configuration';
    $7A: Result := 'Fill slip buffer with nonfiscal information';
    $7B: Result := 'Clear slip buffer string';
    $7C: Result := 'Clear slip buffer';
    $7D: Result := 'Print slip';
    $7E: Result := 'Common slip configuration';
    $80: Result := 'Sale';
    $81: Result := 'Buy';
    $82: Result := 'Sale refund';
    $83: Result := 'Buy refund';
    $84: Result := 'Void transaction';
    $85: Result := 'Close receipt';
    $86: Result := 'Discount';
    $87: Result := 'Charge';
    $88: Result := 'Cancel receipt';
    $89: Result := 'Receipt subtotal';
    $8A: Result := 'Void discount';
    $8B: Result := 'Void charge';
    $8C: Result := 'Print last receipt duplicate';
    $8D: Result := 'Open receipt';
    $90: Result := 'Oil products sale receipt in defined dose pre-payment mode';
    $91: Result := 'Oil products sale receipt in defined sum pre-payment mode';
    $92: Result := 'Correction receipt on incomplete oil-products sale';
    $93: Result := 'Set fuel-dispensing unit dose in milliliters';
    $94: Result := 'Set fuel-dispensing unit dose in cash units';
    $95: Result := 'Oil products sale';
    $96: Result := 'Stop fuel-dispensing unit';
    $97: Result := 'Start fuel-dispensing unit';
    $98: Result := 'Reset fuel-dispensing unit';
    $99: Result := 'Reset all fuel-dispensing units';
    $9A: Result := 'Set fuel-dispensing unit parameters';
    $9B: Result := 'Read liter totals counter';
    $9E: Result := 'Get current fuel-dispensing unit dose';
    $9F: Result := 'Get fuel-dispensing unit status';
    $A0: Result := 'EJ department report in dates range';
    $A1: Result := 'EJ department report in shifts range';
    $A2: Result := 'EJ shift report in dates range';
    $A3: Result := 'EJ shift report in shifts range';
    $A4: Result := 'Print shift totals by EJ shift number';
    $A5: Result := 'Print pay document from EJ by KPK number';
    $A6: Result := 'Print EJ journal by shift number';
    $A7: Result := 'Interrupt full EJ report';
    $A8: Result := 'Print EJ activization result';
    $A9: Result := 'EJ activization';
    $AA: Result := 'Close EJ archive';
    $AB: Result := 'Get EJ serial number';
    $AC: Result := 'Interrupt EJ';
    $AD: Result := 'Get EJ status by code 1';
    $AE: Result := 'Get EJ status by code 2';
    $AF: Result := 'Test EJ integrity';
    $B0: Result := 'Continue printing';
    $B1: Result := 'Get EJ version';
    $B2: Result := 'Initialize EJ';
    $B3: Result := 'Get EJ report data';
    $B4: Result := 'Get EJ journal';
    $B5: Result := 'Get EJ document';
    $B6: Result := 'Get department EJ report in dates range';
    $B7: Result := 'Get EJ department report in shifts range';
    $B8: Result := 'Get EJ shift report in dates range';
    $B9: Result := 'Get EJ shift report in shifts range';
    $BA: Result := 'Get EJ shift totals by shift number';
    $BB: Result := 'Get EJ activization result';
    $BC: Result := 'Get EJ error';
    $C0: Result := 'Load graphics';
    $C1: Result := 'Print graphics';
    $C2: Result := 'Print barcode';
    $C3: Result := 'Print exteneded graphics';
    $C4: Result := 'Load extended graphics';
    $C5: Result := 'Print line';
    $C8: Result := 'Get line count in printing buffer';
    $C9: Result := 'Get line from printing buffer';
    $CA: Result := 'Clear printing buffer';
    $D0: Result := 'Get ECR IBM status';
    $D1: Result := 'Get short ECR IBM status';
    $F0: Result := 'Change shutter position';
    $F1: Result := 'Discharge receipt from presenter';
    $F3: Result := 'Set service center password';
    $FC: Result := 'Get device type';
    $FD: Result := 'Send commands to external device port';
    $E1: Result := 'Finish slip';
    $E2: Result := 'Close nonfiscal document';
    $E4: Result := 'Print attribute';
    $FF01: Result := SCommandNameFF01;
    $FF02: Result := SCommandNameFF02;
    $FF03: Result := SCommandNameFF03;
    $FF04: Result := SCommandNameFF04;
    $FF05: Result := SCommandNameFF05;
    $FF06: Result := SCommandNameFF06;
    $FF07: Result := SCommandNameFF07;
    $FF08: Result := SCommandNameFF08;
    $FF09: Result := SCommandNameFF09;
    $FF0A: Result := SCommandNameFF0A;
    $FF0B: Result := SCommandNameFF0B;
    $FF0C: Result := SCommandNameFF0C;
    $FF0D: Result := SCommandNameFF0D;
    $FF30: Result := SCommandNameFF30;
    $FF31: Result := SCommandNameFF31;
    $FF32: Result := SCommandNameFF32;
    $FF33: Result := SCommandNameFF33;
    $FF34: Result := SCommandNameFF34;
    $FF35: Result := SCommandNameFF35;
    $FF36: Result := SCommandNameFF36;
    $FF37: Result := SCommandNameFF37;
    $FF38: Result := SCommandNameFF38;
    $FF39: Result := SCommandNameFF39;
    $FF3A: Result := SCommandNameFF3A;
    $FF3B: Result := SCommandNameFF3B;
    $FF3C: Result := SCommandNameFF3C;
    $FF3D: Result := SCommandNameFF3D;
    $FF3E: Result := SCommandNameFF3E;
    $FF3F: Result := SCommandNameFF3F;
    $FF40: Result := SCommandNameFF40;
    $FF41: Result := SCommandNameFF41;
    $FF42: Result := SCommandNameFF42;
    $FF43: Result := SCommandNameFF43;
    $FF45: Result := SCommandNameFF45;
    $FF46: Result := SCommandNameFF46;
    $FF47: Result := SCommandNameFF47;
    $FF48: Result := SCommandNameFF48;
    $FF49: Result := SCommandNameFF49;
    $FF4A: Result := SCommandNameFF4A;
    $FF4B: Result := SCommandNameFF4B;
    $FF4C: Result := SCommandNameFF4C;
    $FF4D: Result := SCommandNameFF4D;
    $FF4E: Result := SCommandNameFF4E;
    $FF50: Result := SCommandNameFF50;
    $FF51: Result := SCommandNameFF51;
    $FF52: Result := SCommandNameFF52;
    $FF60: Result := SCommandNameFF60;
    $FF61: Result := SCommandNameFF61;
    $FF62: Result := SCommandNameFF62;
    $FF63: Result := SCommandNameFF63;
    $FF64: Result := SCommandNameFF64;

  else
    Result := '';
  end;
end; }

function GetCashRegisterName(Value: Integer): string;
begin
  case Value of
    0: Result := 'Sales accumulation in 1 department in receipt';
    1: Result := 'Buys accumulation in 1 department in receipt';
    2: Result := 'Sales refund accumulation in 1 department in receipt';
    3: Result := 'Buys refund accumulation in 1 department in receipt';
    4: Result := 'Sales accumulation in 2 department in receipt';
    5: Result := 'Buys accumulation in 2 department in receipt';
    6: Result := 'Sales refund accumulation in 2 department in receipt';
    7: Result := 'Buys refund accumulation in 2 department in receipt';
    8: Result := 'Sales accumulation in 3 department in receipt';
    9: Result := 'Buys accumulation in 3 department in receipt';
    10: Result := 'Sales refund accumulation in 3 department in receipt';
    11: Result := 'Buys refund accumulation in 3 department in receipt';
    12: Result := 'Sales accumulation in 4 department in receipt';
    13: Result := 'Buys accumulation in 4 department in receipt';
    14: Result := 'Sales refund accumulation in 4 department in receipt';
    15: Result := 'Buys refund accumulation in 4 department in receipt';
    16: Result := 'Sales accumulation in 5 department in receipt';
    17: Result := 'Buys accumulation in 5 department in receipt';
    18: Result := 'Sales refund accumulation in 5 department in receipt';
    19: Result := 'Buys refund accumulation in 5 department in receipt';
    20: Result := 'Sales accumulation in 6 department in receipt';
    21: Result := 'Buys accumulation in 6 department in receipt';
    22: Result := 'Sales refund accumulation in 6 department in receipt';
    23: Result := 'Buys refund accumulation in 6 department in receipt';
    24: Result := 'Sales accumulation in 7 department in receipt';
    25: Result := 'Buys accumulation in 7 department in receipt';
    26: Result := 'Sales refund accumulation in 7 department in receipt';
    27: Result := 'Buys refund accumulation in 7 department in receipt';
    28: Result := 'Sales accumulation in 8 department in receipt';
    29: Result := 'Buys accumulation in 8 department in receipt';
    30: Result := 'Sales refund accumulation in 8 department in receipt';
    31: Result := 'Buys refund accumulation in 8 department in receipt';
    32: Result := 'Sales accumulation in 9 department in receipt';
    33: Result := 'Buys accumulation in 9 department in receipt';
    34: Result := 'Sales refund accumulation in 9 department in receipt';
    35: Result := 'Buys refund accumulation in 9 department in receipt';
    36: Result := 'Sales accumulation in 10 department in receipt';
    37: Result := 'Buys accumulation in 10 department in receipt';
    38: Result := 'Sales refund accumulation in 10 department in receipt';
    39: Result := 'Buys refund accumulation in 10 department in receipt';
    40: Result := 'Sales accumulation in 11 department in receipt';
    41: Result := 'Buys accumulation in 11 department in receipt';
    42: Result := 'Sales refund accumulation in 11 department in receipt';
    43: Result := 'Buys refund accumulation in 11 department in receipt';
    44: Result := 'Sales accumulation in 12 department in receipt';
    45: Result := 'Buys accumulation in 12 department in receipt';
    46: Result := 'Sales refund accumulation in 12 department in receipt';
    47: Result := 'Buys refund accumulation in 12 department in receipt';
    48: Result := 'Sales accumulation in 13 department in receipt';
    49: Result := 'Buys accumulation in 13 department in receipt';
    50: Result := 'Sales refund accumulation in 13 department in receipt';
    51: Result := 'Buys refund accumulation in 13 department in receipt';
    52: Result := 'Sales accumulation in 14 department in receipt';
    53: Result := 'Buys accumulation in 14 department in receipt';
    54: Result := 'Sales refund accumulation in 14 department in receipt';
    55: Result := 'Buys refund accumulation in 14 department in receipt';
    56: Result := 'Sales accumulation in 15 department in receipt';
    57: Result := 'Buys accumulation in 15 department in receipt';
    58: Result := 'Sales refund accumulation in 15 department in receipt';
    59: Result := 'Buys refund accumulation in 15 department in receipt';
    60: Result := 'Sales accumulation in 16 department in receipt';
    61: Result := 'Buys accumulation in 16 department in receipt';
    62: Result := 'Sales refund accumulation in 16 department in receipt';
    63: Result := 'Buys refund accumulation in 16 department in receipt';
    64: Result := 'Discounts accumulation from sales in receipt';
    65: Result := 'Discounts accumulation from buys in receipt';
    66: Result := 'Discounts accumulation from sale refunds in receipt';
    67: Result := 'Discounts accumulation from buy refunds in receipt';
    68: Result := 'Charges accumulation on sales in receipt';
    69: Result := 'Charges accumulation on buys in receipt';
    70: Result := 'Charges accumulation on sale refunds in receipt';
    71: Result := 'Charges accumulation on buy refunds in receipt';
    72: Result := 'Cash payment accumulation of sales in receipt';
    73: Result := 'Cash payment accumulation of buys in receipt';
    74: Result := 'Cash payment accumulation of sale refunds in receipt';
    75: Result := 'Cash payment accumulation of buy refunds in receipt';
    76: Result := 'Payment type 2 accumulation of sales in receipt';
    77: Result := 'Payment type 2 accumulation of buys in receipt';
    78: Result := 'Payment type 2 accumulation of sale refunds in receipt';
    79: Result := 'Payment type 2 accumulation of buy refunds in receipt';
    80: Result := 'Payment type 3 accumulation of sales in receipt';
    81: Result := 'Payment type 3 accumulation of buys in receipt';
    82: Result := 'Payment type 3 accumulation of sale refunds in receipt';
    83: Result := 'Payment type 3 accumulation of buy refunds in receipt';
    84: Result := 'Payment type 4 accumulation of sales in receipt';
    85: Result := 'Payment type 4 accumulation of buys in receipt';
    86: Result := 'Payment type 4 accumulation of sale refunds in receipt';
    87: Result := 'Payment type 4 accumulation of buy refunds in receipt';
    88: Result := 'Tax A turnover of sales in receipt';
    89: Result := 'Tax A turnover of buys in receipt';
    90: Result := 'Tax A turnover of sale refunds in receipt';
    91: Result := 'Tax A turnover of buy refunds in receipt';
    92: Result := 'Tax B turnover of sales in receipt';
    93: Result := 'Tax B turnover of buys in receipt';
    94: Result := 'Tax B turnover of sale refunds in receipt';
    95: Result := 'Tax B turnover of buy refunds in receipt';
    96: Result := 'Tax C turnover of sales in receipt';
    97: Result := 'Tax C turnover of buys in receipt';
    98: Result := 'Tax C turnover of sale refunds in receipt';
    99: Result := 'Tax C turnover of buy refunds in receipt';
    100: Result := 'Tax D turnover of sales in receipt';
    101: Result := 'Tax D turnover of buys in receipt';
    102: Result := 'Tax D turnover of sale refunds in receipt';
    103: Result := 'Tax D turnover of buy refunds in receipt in receipt';
    104: Result := 'Tax A accumulations of sales in receipt';
    105: Result := 'Tax A accumulations of buys in receipt';
    106: Result := 'Tax A accumulations of sale refunds in receipt';
    107: Result := 'Tax A accumulations of buy refunds in receipt';
    108: Result := 'Tax B accumulations of sales in receipt';
    109: Result := 'Tax B accumulations of buys in receipt';
    110: Result := 'Tax B accumulations of sale refunds in receipt';
    111: Result := 'Tax B accumulations of buy refunds in receipt';
    112: Result := 'Tax C accumulations of sales in receipt';
    113: Result := 'Tax C accumulations of buys in receipt';
    114: Result := 'Tax C accumulations of sale refunds in receipt';
    115: Result := 'Tax C accumulations of buy refunds in receipt';
    116: Result := 'Tax D accumulations of sales in receipt';
    117: Result := 'Tax D accumulations of buys in receipt';
    118: Result := 'Tax D accumulations of sale refunds in receipt';
    119: Result := 'Tax D accumulations of buy refunds in receipt';
    120: Result := 'Cash total in ECR at receipt closing moment';
    121: Result := 'Sales accumulation in 1 department in shift';
    122: Result := 'Buys accumulation in 1 department in shift';
    123: Result := 'Sales refund accumulation in 1 department in shift';
    124: Result := 'Buys refund accumulation in 1 department in shift';
    125: Result := 'Sales accumulation in 2 department in shift';
    126: Result := 'Buys accumulation in 2 department in shift';
    127: Result := 'Sales refund accumulation in 2 department in shift';
    128: Result := 'Buys refund accumulation in 2 department in shift';
    129: Result := 'Sales accumulation in 3 department in shift';
    130: Result := 'Buys accumulation in 3 department in shift';
    131: Result := 'Sales refund accumulation in 3 department in shift';
    132: Result := 'Buys refund accumulation in 3 department in shift';
    133: Result := 'Sales accumulation in 4 department in shift';
    134: Result := 'Buys accumulation in 4 department in shift';
    135: Result := 'Sales refund accumulation in 4 department in shift';
    136: Result := 'Buys refund accumulation in 4 department in shift';
    137: Result := 'Sales accumulation in 5 department in shift';
    138: Result := 'Buys accumulation in 5 department in shift';
    139: Result := 'Sales refund accumulation in 5 department in shift';
    140: Result := 'Buys refund accumulation in 5 department in shift';
    141: Result := 'Sales accumulation in 6 department in shift';
    142: Result := 'Buys accumulation in 6 department in shift';
    143: Result := 'Sales refund accumulation in 6 department in shift';
    144: Result := 'Buys refund accumulation in 6 department in shift';
    145: Result := 'Sales accumulation in 7 department in shift';
    146: Result := 'Buys accumulation in 7 department in shift';
    147: Result := 'Sales refund accumulation in 7 department in shift';
    148: Result := 'Buys refund accumulation in 7 department in shift';
    149: Result := 'Sales accumulation in 8 department in shift';
    150: Result := 'Buys accumulation in 8 department in shift';
    151: Result := 'Sales refund accumulation in 8 department in shift';
    152: Result := 'Buys refund accumulation in 8 department in shift';
    153: Result := 'Sales accumulation in 9 department in shift';
    154: Result := 'Buys accumulation in 9 department in shift';
    155: Result := 'Sales refund accumulation in 9 department in shift';
    156: Result := 'Buys refund accumulation in 9 department in shift';
    157: Result := 'Sales accumulation in 10 department in shift';
    158: Result := 'Buys accumulation in 10 department in shift';
    159: Result := 'Sales refund accumulation in 10 department in shift';
    160: Result := 'Buys refund accumulation in 10 department in shift';
    161: Result := 'Sales accumulation in 11 department in shift';
    162: Result := 'Buys accumulation in 11 department in shift';
    163: Result := 'Sales refund accumulation in 11 department in shift';
    164: Result := 'Buys refund accumulation in 11 department in shift';
    165: Result := 'Sales accumulation in 12 department in shift';
    166: Result := 'Buys accumulation in 12 department in shift';
    167: Result := 'Sales refund accumulation in 12 department in shift';
    168: Result := 'Buys refund accumulation in 12 department in shift';
    169: Result := 'Sales accumulation in 13 department in receipt';
    170: Result := 'Buys accumulation in 13 department in receipt';
    171: Result := 'Sales refund accumulation in 13 department in receipt';
    172: Result := 'Buys refund accumulation in 13 department in receipt';
    173: Result := 'Sales accumulation in 14 department in shift';
    174: Result := 'Buys accumulation in 14 department in shift';
    175: Result := 'Sales refund accumulation in 14 department in shift';
    176: Result := 'Buys refund accumulation in 14 department in shift';
    177: Result := 'Sales accumulation in 15 department in shift';
    178: Result := 'Buys accumulation in 15 department in shift';
    179: Result := 'Sales refund accumulation in 15 department in shift';
    180: Result := 'Buys refund accumulation in 15 department in shift';
    181: Result := 'Sales accumulation in 16 department in shift';
    182: Result := 'Buys accumulation in 16 department in shift';
    183: Result := 'Sales refund accumulation in 16 department in shift';
    184: Result := 'Buys refund accumulation in 16 department in shift';
    185: Result := 'Discounts accumulation on sales in shift';
    186: Result := 'Discounts accumulation on buys in shift';
    187: Result := 'Discounts accumulation on sale refunds in shift';
    188: Result := 'Discounts accumulation on buy refunds in shift';
    189: Result := 'Charges accumulation on sales in shift';
    190: Result := 'Charges accumulation on buys in shift';
    191: Result := 'Charges accumulation on sale refunds in shift';
    192: Result := 'Charges accumulation on buy refunds in shift';
    193: Result := 'Cash payment accumulation of sales in shift';
    194: Result := 'Cash payment accumulation of buys in shift';
    195: Result := 'Cash payment accumulation of sale refunds shift';
    196: Result := 'Cash payment accumulation of buy refunds in shift';
    197: Result := 'Payment type 2 accumulation of sales in shift';
    198: Result := 'Payment type 2 accumulation of buys in shift';
    199: Result := 'Payment type 2 accumulation of sale refunds in shift';
    200: Result := 'Payment type 2 accumulation of buy refunds in shift';
    201: Result := 'Payment type 3 accumulation of sales in shift';
    202: Result := 'Payment type 3 accumulation of buys in shift';
    203: Result := 'Payment type 3 accumulation of sale refunds in shift';
    204: Result := 'Payment type 3 accumulation of buy refunds in shift';
    205: Result := 'Payment type 4 accumulation of sales in shift';
    206: Result := 'Payment type 4 accumulation of buys in shift';
    207: Result := 'Payment type 4 accumulation of sale refunds in shift';
    208: Result := 'Payment type 4 accumulation of buy refunds in shift';
    209: Result := 'Tax A turnover of sales in shift';
    210: Result := 'Tax A turnover of buys in shift';
    211: Result := 'Tax A turnover of sale refunds in shift';
    212: Result := 'Tax A turnover of buy refunds in shift';
    213: Result := 'Tax B turnover of sales in shift';
    214: Result := 'Tax B turnover of buys in shift';
    215: Result := 'Tax B turnover of sale refunds in shift';
    216: Result := 'Tax B turnover of buy refunds in shift';
    217: Result := 'Tax C turnover of sales in shift';
    218: Result := 'Tax C turnover of buys in shift';
    219: Result := 'Tax C turnover of sale refunds in shift';
    220: Result := 'Tax C turnover of buy refunds in shift';
    221: Result := 'Tax D turnover of sales in shift';
    222: Result := 'Tax D turnover of buys in shift';
    223: Result := 'Tax D turnover of sale refunds in shift';
    224: Result := 'Tax D turnover of buy refunds in shift';
    225: Result := 'Tax A accumulations of sales in shift';
    226: Result := 'Tax A accumulations of buys in shift';
    227: Result := 'Tax A accumulations of sale refunds in shift';
    228: Result := 'Tax A accumulations of buy refunds in shift';
    229: Result := 'Tax B accumulations of sales in shift';
    230: Result := 'Tax B accumulations of buys in shift';
    231: Result := 'Tax B accumulations of sale refunds in shift';
    232: Result := 'Tax B accumulations of buy refunds in shift';
    233: Result := 'Tax C accumulations of sales in shift';
    234: Result := 'Tax C accumulations of buys in shift';
    235: Result := 'Tax C accumulations of sale refunds in shift';
    236: Result := 'Tax C accumulations of buy refunds in shift';
    237: Result := 'Tax D accumulations of sales in shift';
    238: Result := 'Tax D accumulations of buys in shift';
    239: Result := 'Tax D accumulations of sale refunds in shift';
    240: Result := 'Tax D accumulations of buy refunds in shift';
    241: Result := 'Cash total in ECR accumulation';
    242: Result := 'Cash in accumulation in shift';
    243: Result := 'Cash out accumulation in shift';
    244: Result := 'Non-zeroise sum before fiscalization';
    245: Result := 'Sales total in shift from EJ';
    246: Result := 'Buys total in shift from EJ';
    247: Result := 'Sale refunds total in shift from EJ';
    248: Result := 'buy refunds total in shift from EJ';
  else
    Result := '';
  end;
end;

function IsRecStation(Stations: Byte): Boolean;
begin
  Result := (Stations and PRINTER_STATION_REC) <> 0;
end;

function IsJrnStation(Stations: Byte): Boolean;
begin
  Result := (Stations and PRINTER_STATION_JRN) <> 0;
end;

function IsSlpStation(Stations: Byte): Boolean;
begin
  Result := (Stations and PRINTER_STATION_SLP) <> 0;
end;

function IsFieldStr(FieldType: Integer): Boolean;
begin
  Result := FieldType = PRINTER_FIELD_TYPE_STR;
end;

function IsFieldInt(FieldType: Integer): Boolean;
begin
  Result := FieldType = PRINTER_FIELD_TYPE_INT;
end;

function CompareInt(Value1, Value2: Integer): Integer;
begin
  if Value1 > Value2 then Result := 1 else
  if Value1 < Value2 then Result := -1 else
  Result := 0;
end;

function ComparePrinterDate(const Date1, Date2: TPrinterDate): Integer;
begin
  // Year
  Result := CompareInt(Date1.Year, Date2.Year);
  if Result <> 0 then Exit;
  // Month
  Result := CompareInt(Date1.Month, Date2.Month);
  if Result <> 0 then Exit;
  // Day
  Result := CompareInt(Date1.Day, Date2.Day);
end;
resourcestring
  SCPRussian = '˜˜˜˜˜˜˜';
  SCPEnglish = '˜˜˜˜˜˜˜˜˜˜';
  SCPEstonian = '˜˜˜˜˜˜˜˜˜';
  SCPKazakh = '˜˜˜˜˜˜˜˜˜';
  SCPBelorussian = '˜˜˜˜˜˜˜˜˜˜˜';
  SCPArmenian = '˜˜˜˜˜˜˜˜˜';
  SCPGeorgian = '˜˜˜˜˜˜˜˜˜˜';
  SCPUkrainian = '˜˜˜˜˜˜˜˜˜˜';
  SCPKirghiz = '˜˜˜˜˜˜˜˜˜˜';
  SCPUnknown = '˜˜˜˜˜˜˜˜˜˜˜';
  SCPTurkmen = '˜˜˜˜˜˜˜˜˜˜˜';
  SCPMoldova = '˜˜˜˜˜˜˜˜˜˜';


function GetLanguageName(Code: Integer): string;
var
  Res: string;
begin
  case Code of
    FP_LANGUAGE_RUSSIAN     : Res := SCPRussian;
    FP_LANGUAGE_ENGLISH     : Res := SCPEnglish;
    FP_LANGUAGE_ESTONIAN    : Res := SCPEstonian;
    FP_LANGUAGE_KAZAKH      : Res := SCPKazakh;
    FP_LANGUAGE_BELORUSSIAN : Res := SCPBelorussian;
    FP_LANGUAGE_ARMENIAN    : Res := SCPArmenian;
    FP_LANGUAGE_GEORGIAN    : Res := SCPGeorgian;
    FP_LANGUAGE_UKRANIAN    : Res := SCPUkrainian;
    FP_LANGUAGE_KIRGHIZ     : Res := SCPKirghiz;
    FP_LANGUAGE_TURKMEN     : Res := SCPTurkmen;
    FP_LANGUAGE_MOLDOVA     : Res := SCPMoldova;
  else
    Res := SCPUnknown;
  end;
  Result := Res;
end;



type
  PEmulFieldDef = ^TEmulFieldDef;
  PEmulTableDef = ^TEmulTableDef;

function IsQuote(C: Char): Boolean;
begin
  Result := (C = '"') or (C = '''');
end;

{ TEmulTables }

constructor TEmulTables.Create;
begin
  inherited Create;
  FFields := TList.Create;
  FTables := TList.Create;
  FHeader := TStringList.Create;
end;

destructor TEmulTables.Destroy;
var
  i: Integer;
begin
  Clear;
  FFields.Free;
  FTables.Free;
  FHeader.Free;
  inherited Destroy;
end;

procedure TEmulTables.Clear;
var
  i: Integer;
begin
  for i := 0 to FFields.Count - 1 do
    Dispose(FFields[i]);
  FFields.Clear;
  for i := 0 to FTables.Count - 1 do
    Dispose(FTables[i]);
  FTables.Clear;
  FHeader.Clear;
end;

function TEmulTables.FieldKey(Table, Row, Field: Integer): string;
begin
  Result := Format('%d:%d:%d', [Table, Row, Field]);
end;

function TEmulTables.ParseCsvString(const Text: string; Number: Integer): string;
var
  i: Integer;
  Count: Integer;
  InText: Boolean;
  StartPos: Integer;
  EndPos: Integer;
begin
  Result := '';
  Count := 1;
  StartPos := 1;
  InText := False;
  EndPos := Length(Text);
  for i := 1 to Length(Text) do
  begin
    if Text[i] = ',' then
    begin
      if not InText then
      begin
        Inc(Count);
        if Count = Number then
          StartPos := i + 1;
        if Count = (Number + 1) then
          EndPos := i - 1;
      end;
    end;
    if IsQuote(Text[i]) then
      InText := not InText;
  end;
  Result := Copy(Text, StartPos, EndPos - StartPos + 1);
  if (Result <> '') and IsQuote(Result[1]) and IsQuote(Result[Length(Result)]) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

procedure TEmulTables.AddFieldFromLine(const Line: string);
var
  Def: PEmulFieldDef;
  Value: string;
begin
  New(Def);
  try
    Def^.Table := StrToInt(ParseCsvString(Line, 1));
    Def^.Row := StrToInt(ParseCsvString(Line, 2));
    Def^.Field := StrToInt(ParseCsvString(Line, 3));
    Def^.Size := StrToInt(ParseCsvString(Line, 4));
    Def^.FieldType := StrToInt(ParseCsvString(Line, 5));
    Def^.MinValue := StrToInt64(ParseCsvString(Line, 6));
    Def^.MaxValue := StrToInt64(ParseCsvString(Line, 7));
    Def^.Name := ParseCsvString(Line, 8);
    Value := ParseCsvString(Line, 9);
    Def^.Value := Value;
    FFields.Add(Def);
  except
    Dispose(Def);
    raise;
  end;
end;

procedure TEmulTables.RebuildTableDefs;
var
  i, j: Integer;
  Def: PEmulFieldDef;
  Table: PEmulTableDef;
  TableNumber: Integer;
  Found: Boolean;
begin
  for i := 0 to FTables.Count - 1 do
    Dispose(FTables[i]);
  FTables.Clear;

  for i := 0 to FFields.Count - 1 do
  begin
    Def := FFields[i];
    Found := False;
    for j := 0 to FTables.Count - 1 do
    begin
      Table := FTables[j];
      if Table^.Number = Def^.Table then
      begin
        Found := True;
        if Def^.Row > Table^.RowCount then
          Table^.RowCount := Def^.Row;
        if Def^.Field > Table^.FieldCount then
          Table^.FieldCount := Def^.Field;
        Break;
      end;
    end;
    if not Found then
    begin
      New(Table);
      Table^.Number := Def^.Table;
      Table^.Name := Format('Table %d', [Def^.Table]);
      Table^.RowCount := Def^.Row;
      Table^.FieldCount := Def^.Field;
      FTables.Add(Table);
    end;
  end;

  for i := 0 to FTables.Count - 1 do
  begin
    Table := FTables[i];
    TableNumber := Table^.Number;
    for j := 0 to FHeader.Count - 1 do
    begin
      if Pos(Format('// %d', [TableNumber]), FHeader[j]) > 0 then
      begin
        Table^.Name := Trim(Copy(FHeader[j], Pos(',', FHeader[j]) + 1, MaxInt));
        Break;
      end;
    end;
  end;
end;

procedure TEmulTables.LoadFromFile(const FileName: string);
var
  Lines: TStringList;
  i: Integer;
  Line: string;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('File not found: %s', [FileName]);
  Clear;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);
      if Line = '' then
        Continue;
      if Copy(Line, 1, 2) = '//' then
      begin
        if Copy(Line, 1, 3) = '///' then
          FHeader.Add(Copy(Line, 5, MaxInt));
        Continue;
      end;
      AddFieldFromLine(Line);
    end;
    RebuildTableDefs;
  finally
    Lines.Free;
  end;
end;

function TEmulTables.GetFieldCount: Integer;
begin
  Result := FFields.Count;
end;

function TEmulTables.GetField(Index: Integer): TEmulFieldDef;
begin
  Result := PEmulFieldDef(FFields[Index])^;
end;

function TEmulTables.GetTableCount: Integer;
begin
  Result := FTables.Count;
end;

function TEmulTables.GetTable(Index: Integer): TEmulTableDef;
begin
  Result := PEmulTableDef(FTables[Index])^;
end;

function TEmulTables.FindFieldIndex(Table, Row, Field: Integer): Integer;
var
  i: Integer;
  Def: PEmulFieldDef;
begin
  Result := -1;
  for i := 0 to FFields.Count - 1 do
  begin
    Def := FFields[i];
    if (Def^.Table = Table) and (Def^.Row = Row) and (Def^.Field = Field) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TEmulTables.FindTable(TableNumber: Integer): TEmulTableDef;
var
  i: Integer;
  Table: PEmulTableDef;
  Found: Boolean;
begin
  Found := False;
  for i := 0 to FTables.Count - 1 do
  begin
    Table := FTables[i];
    if Table^.Number = TableNumber then
    begin
      Result := Table^;
      Found := True;
      Exit;
    end;
  end;
  if not Found then
    raise Exception.CreateFmt('Table %d not found', [TableNumber]);
end;

function TEmulTables.ReadFieldValue(Table, Row, Field: Integer): string;
var
  Index: Integer;
begin
  Index := FindFieldIndex(Table, Row, Field);
  if Index < 0 then
    Result := ''
  else
    Result := PEmulFieldDef(FFields[Index])^.Value;
end;

procedure TEmulTables.WriteFieldValue(Table, Row, Field: Integer; const Value: string);
var
  Index: Integer;
begin
  Index := FindFieldIndex(Table, Row, Field);
  if Index < 0 then
    raise Exception.CreateFmt('Field %d.%d.%d not found', [Table, Row, Field]);
  PEmulFieldDef(FFields[Index])^.Value := Value;
end;

function TEmulTables.ReadFieldDef(Table, Row, Field: Integer; out Def: TEmulFieldDef): Boolean;
var
  Index: Integer;
begin
  Index := FindFieldIndex(Table, Row, Field);
  Result := Index >= 0;
  if Result then
    Def := PEmulFieldDef(FFields[Index])^;
end;



const
  CBR_9600 = 9600;
  CBR_19200 = 19200;
  CBR_38400 = 38400;
  CBR_57600 = 57600;
  CBR_115200 = 115200;

function BaudRateCodeToValue(Code: Integer): Integer;
begin
  case Code of
    0: Result := 1200;
    1: Result := 2400;
    2: Result := 4800;
    3: Result := CBR_9600;
    4: Result := CBR_19200;
    5: Result := CBR_38400;
    6: Result := CBR_57600;
    7: Result := CBR_115200;
  else
    Result := CBR_115200;
  end;
end;

{ TEmulSerialPort }

constructor TEmulSerialPort.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FTimeout := 3000;
end;

destructor TEmulSerialPort.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TEmulSerialPort.CheckOpened;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Serial port is not opened');
end;

procedure TEmulSerialPort.ApplyCommState;
var
  DCB: TDCB;
  Timeouts: TCommTimeOuts;
  Baud: Integer;
begin
  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FHandle, DCB) then
    raise Exception.Create(SysErrorMessage(GetLastError));
  Baud := BaudRateCodeToValue(FBaudRate);
  DCB.BaudRate := Baud;
  DCB.ByteSize := 8;
  DCB.Parity := NOPARITY;
  DCB.StopBits := ONESTOPBIT;
  DCB.Flags := $01;
  if not SetCommState(FHandle, DCB) then
    raise Exception.Create(SysErrorMessage(GetLastError));

  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout := MAXDWORD;
  Timeouts.ReadTotalTimeoutMultiplier := 0;
  Timeouts.ReadTotalTimeoutConstant := FTimeout;
  Timeouts.WriteTotalTimeoutMultiplier := 0;
  Timeouts.WriteTotalTimeoutConstant := FTimeout;
  if not SetCommTimeouts(FHandle, Timeouts) then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

procedure TEmulSerialPort.Open(const APortName: string; ABaudRate: Integer);
var
  DeviceName: string;
begin
  Close;
  FPortName := APortName;
  FBaudRate := ABaudRate;
  DeviceName := '\\.\' + APortName;
  FHandle := CreateFile(PChar(DeviceName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('Cannot open port %s: %s', [APortName, SysErrorMessage(GetLastError)]);
  ApplyCommState;
  PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

procedure TEmulSerialPort.Close;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

function TEmulSerialPort.Opened: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

procedure TEmulSerialPort.Purge;
begin
  if Opened then
    PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

procedure TEmulSerialPort.WriteData(const Data: AnsiString);
var
  Written: DWORD;
begin
  CheckOpened;
  if Data = '' then
    Exit;
  if not WriteFile(FHandle, Data[1], Length(Data), Written, nil) then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

function TEmulSerialPort.ReadChar(var C: AnsiChar): Boolean;
var
  ReadCount: DWORD;
begin
  Result := False;
  CheckOpened;
  if ReadFile(FHandle, C, 1, ReadCount, nil) and (ReadCount = 1) then
    Result := True;
end;

function TEmulSerialPort.ReadCharTimeout(var C: AnsiChar; ATimeout: Integer): Boolean;
var
  OldTimeout: Integer;
begin
  OldTimeout := FTimeout;
  try
    FTimeout := ATimeout;
    ApplyCommState;
    Result := ReadChar(C);
  finally
    FTimeout := OldTimeout;
    if Opened then
      ApplyCommState;
  end;
end;

function TEmulSerialPort.ReadExact(Count: Integer; ATimeout: Integer): AnsiString;
var
  i: Integer;
  C: AnsiChar;
begin
  SetLength(Result, Count);
  for i := 1 to Count do
  begin
    if not ReadCharTimeout(C, ATimeout) then
      raise Exception.Create('Serial read timeout');
    Result[i] := C;
  end;
end;




function GetStrLen(const S: AnsiString; Len: Integer): AnsiString;
begin
  Result := Copy(S, 1, Len);
  Result := Result + StringOfChar(#0, Len - Length(Result));
end;

function FptrFont(PrintWidth: Word; CharWidth, CharHeight,
  FontCount: Byte): TFptrFontRec;
begin
  Result.PrintWidth := PrintWidth;
  Result.CharWidth := CharWidth;
  Result.CharHeight := CharHeight;
  Result.FontCount := FontCount;
end;

function DataToBin(const P; Size: Integer): AnsiString;
begin
  SetLength(Result, Size);
  Move(P, Result[1], Size);
end;

function DateToBin(const Value: TPrinterDate): AnsiString;
begin
  Result := DataToBin(Value, Sizeof(Value));
end;

function TimeToBin(const Value: TPrinterTime): AnsiString;
begin
  Result := DataToBin(Value, Sizeof(Value));
end;

function FiscalIDToBin(const Value: TFptrFiscalIDRec): AnsiString;
begin
  if Value.Valid then
    Result := IntToBin(Value.Number, 6)
  else
    Result := #$FF#$FF#$FF#$FF#$FF#$FF;
end;

function SerialToBin(const Value: TFptrSerialRec): AnsiString;
begin
  if Value.Valid then
    Result := IntToBin(Value.Number, 4)
  else
    Result := #$FF#$FF#$FF#$FF;
end;

procedure RaiseFptrError(Code: Byte);
begin
  raise EFptrError.Create2(Code, '');
end;

procedure CheckMinLength(const Data: AnsiString; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    RaiseFptrError(FPTR_E_INVALID_CMD_LEN);
end;

function PrinterDate(Day, Month, Year: Byte): TPrinterDate;
begin
  Result.Day := Day;
  Result.Month := Month;
  Result.Year := Year;
end;

{ EFptrError }

constructor EFptrError.Create2(Code: Byte; const Msg: AnsiString);
begin
  inherited Create(Msg);
  FErrorCode := Code;
end;


{ TFptrFrame }

class function TFptrFrame.GetCRC(const Data: AnsiString): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Data) do

    Result := Result xor Ord(Data[i]);
end;

class function TFptrFrame.Encode(const Data: AnsiString): AnsiString;
var
  DataLen: Integer;
begin
  DataLen := Length(Data);
  Result := AnsiChar(DataLen) + Data;
  Result := STX + Result + AnsiChar(GetCRC(Result));
end;

class function TFptrFrame.Decode(const Data: AnsiString): AnsiString;
var
  S: AnsiString;
  DataCrc: Byte;
  DataLen: Integer;
begin
  if Length(Data) < 3 then
    raise Exception.Create('Invalid data length');

  if Data[1] <> STX then
    raise Exception.Create('First byte is not STX');

  DataLen := Ord(Data[2]);
  S := Copy(Data, 2, DataLen+1);
  Result := Copy(Data, 3, DataLen);
  if Length(Result) <> DataLen then
    raise Exception.Create('Invalid data length');

  DataCrc := Ord(Data[Length(Data)]);
  if DataCrc <> GetCRC(S) then
    raise Exception.Create('Invalid CRC');
end;

{ TFptrCommands }

constructor TFptrCommands.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TFptrCommands.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFptrCommands.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TFptrCommands.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFptrCommands.GetItem(Index: Integer): TFptrCommand;
begin
  Result := FList[Index];
end;

procedure TFptrCommands.InsertItem(AItem: TFptrCommand);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TFptrCommands.RemoveItem(AItem: TFptrCommand);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TFptrCommands.ItemByCode(Code: Integer): TFptrCommand;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.Code = Code then Exit;
  end;
  Result := nil;
end;

{ TFptrCommand }

constructor TFptrCommand.Create(AOwner: TFptrCommands);
begin
  inherited Create;
  SetOwner(AOwner);
end;

destructor TFptrCommand.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

procedure TFptrCommand.SetOwner(AOwner: TFptrCommands);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

{ TFptrPrintItems }

constructor TFptrPrintItems.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TFptrPrintItems.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFptrPrintItems.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TFptrPrintItems.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFptrPrintItems.GetItem(Index: Integer): TFptrPrintItem;
begin
  Result := FList[Index];
end;

procedure TFptrPrintItems.InsertItem(AItem: TFptrPrintItem);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TFptrPrintItems.RemoveItem(AItem: TFptrPrintItem);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TFptrPrintItems.AddLine(const ALine: AnsiString; AFont: Integer): TFptrLine;
begin
  Result := TFptrLine.Create2(Self, ALine, AFont);
end;

function TFptrPrintItems.AddCut(ACutType: Integer): TFptrCut;
begin
  Result := TFptrCut.Create2(Self, ACutType);
end;

function TFptrPrintItems.AddFeed(ALineCount: Integer): TFptrFeed;
begin
  Result := TFptrFeed.Create2(Self, ALineCount);
end;

function TFptrPrintItems.AddBarcode(ABarcode: Int64): TFptrBarcode;
begin
  Result := TFptrBarcode.Create2(Self, ABarcode);
end;

{ TFptrTables }

constructor TFptrTables.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TFptrTables.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFptrTables.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TFptrTables.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFptrTables.GetItem(Index: Integer): TFptrTable;
begin
  Result := FList[Index];
end;

procedure TFptrTables.InsertItem(AItem: TFptrTable);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TFptrTables.RemoveItem(AItem: TFptrTable);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TFptrTables.Add(const AData: TFptrTableRec): TFptrTable;
begin
  Result := TFptrTable.Create(Self, AData);
end;

function TFptrTables.ItemByNumber(Number: Integer): TFptrTable;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.Number = Number then Exit;
  end;
  Result := nil;
end;

{ TFptrTable }

constructor TFptrTable.Create(AOwner: TFptrTables; const AData: TFptrTableRec);
begin
  inherited Create;
  SetOwner(AOwner);
  FData := AData;
end;

destructor TFptrTable.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

procedure TFptrTable.SetOwner(AOwner: TFptrTables);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

{ TFptrPrintItem }

constructor TFptrPrintItem.Create(AOwner: TFptrPrintItems);
begin
  inherited Create;
  SetOwner(AOwner);
end;

destructor TFptrPrintItem.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

procedure TFptrPrintItem.SetOwner(AOwner: TFptrPrintItems);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

{ TFptrBarcode }

constructor TFptrBarcode.Create2(AOwner: TFptrPrintItems; ABarcode: Int64);
begin
  inherited Create(AOwner);
  FBarcode := ABarcode;
end;

{ TFptrLine }

constructor TFptrLine.Create2(AOwner: TFptrPrintItems; const ALine: AnsiString;
  AFont: Integer);
begin
  inherited Create(AOwner);
  FLine := ALine;
  FFont := AFont;
end;

{ TFptrCut }

constructor TFptrCut.Create2(AOwner: TFptrPrintItems; ACutType: Integer);
begin
  inherited Create(AOwner);
  FCutType := ACutType;
end;

{ TFptrFeed }

constructor TFptrFeed.Create2(AOwner: TFptrPrintItems; ALineCount: Integer);
begin
  inherited Create(AOwner);
  FLineCount := ALineCount;
end;

{ TPrinterEmulator }

constructor TPrinterEmulator.Create;
begin
  inherited Create;
  FTables := TFptrTables.Create;
  FReceipt := TFptrReceipt.Create;
  FSlipLines := TFptrPrintItems.Create;
  FReceiptLines := TFptrPrintItems.Create;
  FJournalLines := TFptrPrintItems.Create;
  FCommands := TFptrCommands.Create;
  FFNState := TEmulFNState.Create;
  TFptrCommand_01h.Create(FCommands);
  TFptrCommand_10h.Create(FCommands);
  TFptrCommand_11h.Create(FCommands);
  TFptrCommand_12h.Create(FCommands);
  TFptrCommand_13h.Create(FCommands);
  TFptrCommand_14h.Create(FCommands);
  TFptrCommand_15h.Create(FCommands);
  TFptrCommand_16h.Create(FCommands);
  TFptrCommand_17h.Create(FCommands);
  TFptrCommand_18h.Create(FCommands);
  TFptrCommand_19h.Create(FCommands);
  TFptrCommand_1Ah.Create(FCommands);
  TFptrCommand_1Bh.Create(FCommands);
  TFptrCommand_1Ch.Create(FCommands);
  TFptrCommand_1Dh.Create(FCommands);
  TFptrCommand_1Eh.Create(FCommands);
  TFptrCommand_1Fh.Create(FCommands);
  TFptrCommand_20h.Create(FCommands);
  TFptrCommand_21h.Create(FCommands);
  TFptrCommand_22h.Create(FCommands);
  TFptrCommand_23h.Create(FCommands);
  TFptrCommand_24h.Create(FCommands);
  TFptrCommand_25h.Create(FCommands);
  TFptrCommand_26h.Create(FCommands);
  TFptrCommand_27h.Create(FCommands);
  TFptrCommand_28h.Create(FCommands);
  TFptrCommand_29h.Create(FCommands);
  TFptrCommand_2Bh.Create(FCommands);
  TFptrCommand_2Ch.Create(FCommands);
  TFptrCommand_2Dh.Create(FCommands);
  TFptrCommand_2Eh.Create(FCommands);
  TFptrCommand_2Fh.Create(FCommands);

  TFptrCommand_40h.Create(FCommands);
  TFptrCommand_41h.Create(FCommands);
  TFptrCommand_42h.Create(FCommands);
  TFptrCommand_43h.Create(FCommands);
  TFptrCommand_50h.Create(FCommands);
  TFptrCommand_51h.Create(FCommands);
  TFptrCommand_52h.Create(FCommands);
  TFptrCommand_53h.Create(FCommands);
  TFptrCommand_54h.Create(FCommands);

  TFptrCommand_60h.Create(FCommands);
  TFptrCommand_62h.Create(FCommands);

  TFptrCommand_F3h.Create(FCommands);
  TFptrCommand_FCh.Create(FCommands);

  TFptrCommand_C2h.Create(FCommands);
  TFptrCommand_02h.Create(FCommands);
  TFptrCommand_63h.Create(FCommands);

  TFptrCommand_8Ch.Create(FCommands);
  TFptrCommand_8Dh.Create(FCommands);
  TFptrCommand_80h.Create(FCommands);
  TFptrCommand_81h.Create(FCommands);
  TFptrCommand_82h.Create(FCommands);
  TFptrCommand_83h.Create(FCommands);
  TFptrCommand_84h.Create(FCommands);
  TFptrCommand_85h.Create(FCommands);
  TFptrCommand_86h.Create(FCommands);
  TFptrCommand_87h.Create(FCommands);
  TFptrCommand_88h.Create(FCommands);
  TFptrCommand_89h.Create(FCommands);
  TFptrCommand_8Ah.Create(FCommands);
  TFptrCommand_8Bh.Create(FCommands);

  RegisterAllProtocolCommands(FCommands);

  Reset;
end;

destructor TPrinterEmulator.Destroy;
begin
  if FTableStorage <> nil then
    TEmulTables(FTableStorage).Free;
  FTables.Free;
  FReceipt.Free;
  FCommands.Free;
  FSlipLines.Free;
  FReceiptLines.Free;
  FJournalLines.Free;
  FFNState.Free;
  inherited Destroy;
end;

procedure TPrinterEmulator.SendCommand(var Data: AnsiString; Timeout: Integer);
begin
  Data := Execute(Data, Timeout);
  Data := TFptrFrame.Encode(Data);
end;

function TPrinterEmulator.Execute(const Data: AnsiString; Timeout: Integer): AnsiString;
var
  CommandCode: Byte;
  LookupCode: Integer;
  CommandData: AnsiString;
  Command: TFptrCommand;
  PrefixLen: Integer;
begin
  if Length(Data) = 0 then
    raise Exception.Create('Invalid command length');

  CommandCode := Ord(Data[1]);
  LookupCode := CommandCode;
  PrefixLen := 1;
  CommandData := Copy(Data, 2, Length(Data));

  if CommandCode in [$FE, $FF] then
  begin
    if Length(Data) < 2 then
      raise Exception.Create('Invalid extended command length');
    LookupCode := (CommandCode shl 8) or Ord(Data[2]);
    CommandData := Copy(Data, 3, Length(Data));
    PrefixLen := 2;
  end;

  Command := FCommands.ItemByCode(LookupCode);
  if Command <> nil then
  begin
    try
      Result := Command.Execute(Self, CommandData);
    except
      on E: EFptrError do
      begin
        Result := AnsiChar(E.ErrorCode);
      end;
    end;
  end else
  begin
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT);
  end;

  if PrefixLen = 2 then
    Result := AnsiChar(CommandCode) + AnsiChar(LookupCode and $FF) + Result
  else
    Result := AnsiChar(CommandCode) + Result;
end;

procedure TPrinterEmulator.LoadFromFile(const FileName: AnsiString);
var
  Tables: TEmulTables;
begin
  if FTableStorage <> nil then
    TEmulTables(FTableStorage).Free;
  Tables := TEmulTables.Create;
  FTableStorage := Tables;
  Tables.LoadFromFile(FileName);
  ApplyTables(Tables);
end;

procedure TPrinterEmulator.ApplyTables(ATables: TObject);
var
  Tables: TEmulTables;
  i: Integer;
  TableDef: TEmulTableDef;
  TableRec: TFptrTableRec;
begin
  FEmulTables := ATables;
  if ATables = nil then
    Exit;
  Tables := TEmulTables(ATables);

  FTables.Clear;
  for i := 0 to Tables.TableCount - 1 do
  begin
    TableDef := Tables.Tables[i];
    TableRec.Number := TableDef.Number;
    TableRec.Name := TableDef.Name;
    TableRec.RowCount := TableDef.RowCount;
    TableRec.FieldCount := TableDef.FieldCount;
    FTables.Add(TableRec);
  end;
  ApplyOperatorPasswords;
  ApplyFiscalFromTables;
end;

procedure TPrinterEmulator.ApplyOperatorPasswords;
var
  Tables: TEmulTables;
  i: Integer;
  Def: TEmulFieldDef;
begin
  if FEmulTables = nil then
    Exit;
  Tables := TEmulTables(FEmulTables);
  for i := 0 to Tables.FieldCount - 1 do
  begin
    Def := Tables.Fields[i];
    if (Def.Table = 2) and (Def.Field = 1) and (Def.Row in [1..30]) then
      FOperators[Def.Row].Password := StrToIntDef(Def.Value, Def.Row);
  end;
end;

function PadRightAnsi(const S: AnsiString; Len: Integer): AnsiString;
begin
  Result := Copy(S, 1, Len);
  if Length(Result) < Len then
    Result := Result + StringOfChar(' ', Len - Length(Result));
end;

procedure TPrinterEmulator.ApplyFiscalFromTables;
var
  Tables: TEmulTables;
  Def: TEmulFieldDef;
  FN: TEmulFNState;
begin
  if FEmulTables = nil then
    Exit;
  Tables := TEmulTables(FEmulTables);
  FN := TEmulFNState(FFNState);
  if Tables.ReadFieldDef(18, 1, 1, Def) then
  begin
    FLongSerial := StrToInt64Def(Trim(Def.Value), FLongSerial);
    FSerial.Valid := True;
    FSerial.Number := FLongSerial mod 1000000000;
  end;
  if Tables.ReadFieldDef(18, 1, 2, Def) then
    FN.INN := PadRightAnsi(Trim(Def.Value), 12);
  if Tables.ReadFieldDef(18, 1, 3, Def) then
    FN.KKTRegNumber := PadRightAnsi(Trim(Def.Value), 20);
  if FN.KKTRegNumber <> '' then
  begin
    FFiscalMemory.FiscalID.Valid := True;
    FFiscalMemory.FiscalID.Number := StrToInt64Def(Trim(FN.KKTRegNumber), 0);
  end;
end;

function TPrinterEmulator.GetSessionNumber: Word;
begin
  if FFNState <> nil then
    Result := TEmulFNState(FFNState).SessionNumber
  else
    Result := 0;
end;

function TPrinterEmulator.GetFNKKTRegNumber: AnsiString;
begin
  if FFNState <> nil then
    Result := TEmulFNState(FFNState).KKTRegNumber
  else
    Result := '';
end;

function TPrinterEmulator.GetFNINN: AnsiString;
begin
  if FFNState <> nil then
    Result := TEmulFNState(FFNState).INN
  else
    Result := '';
end;

procedure TPrinterEmulator.ClearSlipDocument;
begin
  FSlipLines.Clear;
end;

procedure TPrinterEmulator.SaveToFile(const FileName: AnsiString);
begin

end;

procedure TPrinterEmulator.Reset;
begin
  Receipt.Reset;
  if FFNState <> nil then
    TEmulFNState(FFNState).Reset;
  FMode := FPTR_MODE_DAY_CLOSED;
  FSubMode := FPTR_SUBMODE_IDLE;

  SlipLines.Clear;
  ReceiptLines.Clear;
  JournalLines.Clear;
  FPort.Number := 0;
  FPort.BaudRate := 3;
  FPort.Timeout := 100;
  FLicense.Valid := False;
  FLicense.Value := $FFFFFFFFFF;

  InitializeTables;

  FFonts[1] := FptrFont(600, 12, 12, 7);
  FFonts[2] := FptrFont(600, 24, 22, 7);
  FFonts[3] := FptrFont(600, 12, 12, 7);
  FFonts[4] := FptrFont(600, 24, 25, 7);
  FFonts[5] := FptrFont(600, 10, 19, 7);
  FFonts[6] := FptrFont(600, 12, 12, 7);
  FFonts[7] := FptrFont(600, 12, 12, 7);

  //Tables.Add('')

  FDeviceMetrics.DeviceType := 0;
  FDeviceMetrics.DeviceSubtype := 0;
  FDeviceMetrics.ProtocolVersion := 1;
  FDeviceMetrics.ProtocolSubVersion := 4;
  FDeviceMetrics.Model := 1;
  FDeviceMetrics.Language := 0;
  FDeviceMetrics.DeviceName := '?????-??-?';
  FDayOpened := False;
  FLongSerial := 289610204000839;
  FSavedDumpMode := FPTR_MODE_DAY_CLOSED;
  FReportInProgress := False;

  FFirmware.Version := 'A4';
  FFirmware.Build := 1234;
  FFirmware.Date := PrinterDate(26,08, 10);

  FFiscalMemory.Flags := 0;
  FFiscalMemory.ErrorCode := 0;
  FFiscalMemory.Firmware.Version := '12';
  FFiscalMemory.Firmware.Build := 8776;
  FFiscalMemory.Firmware.Date := PrinterDate(15, 04, 08);
  FFiscalMemory.DayNumber := 0;
  FFiscalMemory.FiscNumber := 0;
  FFiscalMemory.FreeRecords := 3000;
  FFiscalMemory.LeftFiscNumber := 16;
  FFiscalMemory.FiscalID.Number := 0;
  FFiscalMemory.FiscalID.Valid := False;
end;

procedure TPrinterEmulator.InitializeTables;
var
  i: Integer;
begin
  // Table 2
  for i := 1 to 28 do
  begin
    FOperators[i].Password := i;
    FOperators[i].Name := '?????? ' + IntToStr(i);
  end;
  FOperators[29].Password := 29;
  FOperators[29].Name := '?????????????';
  FOperators[30].Password := 30;
  FOperators[30].Name := '????.?????????????';
end;

function TPrinterEmulator.FindOperator(Password, MinIndex: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 30 do
  begin
    if i >= MinIndex then
    begin
      if FOperators[i].Password = Password then
      begin
        Result := i;
        Exit;
      end;
    end;
  end;
  RaiseFptrError(FPTR_E_INVALID_PASSWORD);
end;


{ TFptrCommand_10h }

(******************************************************************************

  Get Short FP Status

  Command:	10H. Length: 5 bytes.
  ?	Operator password (4 bytes)

  Answer:		10H. Length: 16 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30
  ?	FP flags (2 bytes)
  ?	FP mode (1 byte)
  ?	FP submode (1 byte)
  ?	Quantity of operations on the current receipt (1 byte) lower byte of a two-byte digit (see below)
  ?	Battery voltage (1 byte)
  ?	Power source voltage (1 byte)
  ?	Fiscal Memory error code (1 byte)
  ?	EKLZ error code (1 byte) EKLZ=Electronic Cryptographic Journal
  ?	Quantity of operations on the current receipt (1 byte) upper byte of a two-byte digit (see below)
  ?	Reserved (3 bytes)

******************************************************************************)

function TFptrCommand_10h.GetCode: Integer;
begin
  Result := $10;
end;

function TFptrCommand_10h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := #0 +
    AnsiChar(Operator) +
    IntToBin(Device.Flags, 2) +
    AnsiChar(Device.Mode) +
    AnsiChar(Device.SubMode) +
    AnsiChar(Lo(Device.Receipt.Operations)) +
    AnsiChar(Device.BatteryVoltage) +
    AnsiChar(Device.PowerVoltage) +
    AnsiChar(Device.FiscalMemory.ErrorCode) +
    AnsiChar(Device.EJournal.ErrorCode) +
    AnsiChar(Hi(Device.Receipt.Operations)) +
    #0#0#0;
end;

{ TFptrCommand_11h }

(******************************************************************************

  Get FP Status
  Command:	11H. Length: 5 bytes.
  ?	Operator password (4 bytes)
  Answer:		11H. Length: 48 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30
  ?	FP firmware version (2 bytes)
  ?	FP firmware build (2 bytes)
  ?	FP firmware date (3 bytes) DD-MM-YY
  ?	Number of FP in checkout line (1 byte)
  ?	Current receipt number (2 bytes)
  ?	FP flags (2 bytes)
  ?	FP mode (1 byte)
  ?	FP submode (1 byte)
  ?	FP port (1 byte)
  ?	FM firmware version (2 bytes)
  ?	FM firmware build (2 bytes)
  ?	FM firmware date (3 bytes) DD-MM-YY
  ?	Current date (3 bytes) DD-MM-YY
  ?	Current time (3 bytes) HH-MM-SS
  ?	FM flags (1 byte)
  ?	Serial number (4 bytes)
  ?	Number of last daily totals record in FM (2 bytes) 0000?2100
  ?	Quantity of free daily totals records left in FM (2 bytes)
  ?	Last fiscalization/refiscalization record number in FM (1 byte) 1?16
  ?	Quantity of free fiscalization/refiscalization records left in FM (1 byte) 0?15
  ?	Taxpayer ID (6 bytes)

******************************************************************************)


function TFptrCommand_11h.GetCode: Integer;
begin
  Result := $11;
end;

function TFptrCommand_11h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := #0 +
    AnsiChar(Operator) +
    Device.Firmware.Version +
    IntToBin(Device.Firmware.Build, 2) +
    DateToBin(Device.Firmware.Date) +
    AnsiChar(Device.StoreID) +
    IntToBin(Device.DocNumber, 2) +
    IntToBin(Device.Flags, 2) +
    AnsiChar(Device.Mode) +
    AnsiChar(Device.SubMode) +
    AnsiChar(Device.PortNumber) +
    Device.FiscalMemory.Firmware.Version +
    IntToBin(Device.FiscalMemory.Firmware.Build, 2) +
    DateToBin(Device.FiscalMemory.Firmware.Date) +
    DateToBin(Device.Date) +
    TimeToBin(Device.Time) +
    AnsiChar(Device.FiscalMemory.Flags) +
    SerialToBin(Device.Serial) +
    IntToBin(Device.FiscalMemory.DayNumber, 2) +
    IntToBin(Device.FiscalMemory.FreeRecords, 2) +
    IntToBin(Device.FiscalMemory.FiscNumber, 2) +
    IntToBin(Device.FiscalMemory.LeftFiscNumber, 2) +
    FiscalIDToBin(Device.FiscalMemory.FiscalID);
end;

function TPrinterEmulator.GetDeviceDump(Index: Integer): AnsiString;
begin
  Result := FDeviceDumps[Index];
end;

procedure TPrinterEmulator.PrintLine(Flags: Byte; const Line: AnsiString; Font: Byte);
begin
  if IsRecStation(Flags) then
    ReceiptLines.AddLine(Line, Font);

  if IsJrnStation(Flags) then
    JournalLines.AddLine(Line, Font);
end;

procedure TPrinterEmulator.PrintBoldLine(Flags: Byte; const Line: AnsiString);
begin
  PrintLine(Flags, Line, FPTR_FONT_BOLD);
end;

procedure TPrinterEmulator.ResetStatus;
begin
  { !!! }
end;

function TPrinterEmulator.GetMode4: Integer;
begin
  Result := Mode and $0F;
end;

procedure TPrinterEmulator.PrintDocHeader(const DocName: AnsiString;
  DocNumber: Integer);
begin
  { !!! }
  Inc(FDocNumber);
end;

function TPrinterEmulator.Beep(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
end;

function TPrinterEmulator.StartTest(Password, Period: Integer): Integer;
begin
  if not (Period in [1..99]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result := FindOperator(Password, 0);
  case Mode4 of
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_POINTPOS,
    FPTR_MODE_TECH: ;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  FMode := FPTR_MODE_TEST;
end;

function TPrinterEmulator.ReadCashReg(Password,
  RegNumber: Integer): TFptrAmountRegRec;
begin
  if not (RegNumber in [0..$FF]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result.Operator := FindOperator(Password, 0);
  Result.RegValue := FAmountRegisters[RegNumber];
end;

function TPrinterEmulator.ReadOperatingReg(Password,
  RegNumber: Integer): TFptrOperatingRegRec;
begin
  if not (RegNumber in [0..$FF]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result.Operator := FindOperator(Password, 0);
  Result.RegValue := FOperatingRegisters[RegNumber];
end;

function TPrinterEmulator.GetAmountRegister(Index: Integer): Int64;
begin
  Result := FAmountRegisters[Index];
end;

function TPrinterEmulator.GetOperatingRegister(Index: Integer): Integer;
begin
  Result := FOperatingRegisters[Index];
end;

procedure TPrinterEmulator.WriteLicense(Password: Integer;
  ALicense: Int64);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  if (ALicense < 0000000000) or (ALicense > 9999999999) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  FLicense.Valid := True;
  FLicense.Value := ALicense;
end;

function TPrinterEmulator.ReadLicense(Password: Integer): Int64;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Result := License.Value;
end;

function TPrinterEmulator.GetOperator(Index: Integer): TFptrOperatorRec;
begin
  Result := FOperators[Index];
end;

procedure TPrinterEmulator.WriteTablePassword(const Field: TFptrFieldRec);
begin
  if not (Field.Row in [1..30]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  case Field.Field of
    1: FOperators[Field.Row].Password := BinToInt(Field.Value, 1, 4);
    2: FOperators[Field.Row].Name := Copy(Field.Value, 1, 21);
  else
    RaiseFptrError(FPTR_E_INVALID_PARAM);
  end;
end;

function TPrinterEmulator.ReadTablePassword(const Field: TFptrFieldRec): TFptrFieldRec;
begin
  Result := Field;
  if not (Field.Row in [1..30]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  case Field.Field of
    1: Result.Value := IntToBin(FOperators[Field.Row].Password, 4);
    2: Result.Value := FOperators[Field.Row].Name;
  else
    RaiseFptrError(FPTR_E_INVALID_PARAM);
  end;
end;

function TPrinterEmulator.ReadFieldStruct(Password, TableNumber,
  FieldNumber: Integer; out Def: TEmulFieldDef): Boolean;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  if FEmulTables = nil then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
  Result := TEmulTables(FEmulTables).ReadFieldDef(TableNumber, 1, FieldNumber, Def);
  if not Result then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
end;

function FieldValueToBin(const Def: TEmulFieldDef): AnsiString;
begin
  if Def.FieldType = 0 then
    Result := IntToBin(StrToInt64Def(Def.Value, 0), Def.Size)
  else
    Result := GetStrLen(Def.Value, Def.Size);
end;

procedure TPrinterEmulator.WriteTable(Password: Integer;
  const Field: TFptrFieldRec);
var
  Tables: TEmulTables;
  Def: TEmulFieldDef;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if Field.Table = 2 then
  begin
    WriteTablePassword(Field);
    Exit;
  end;

  if FEmulTables = nil then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);

  Tables := TEmulTables(FEmulTables);
  if not Tables.ReadFieldDef(Field.Table, Field.Row, Field.Field, Def) then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
  if Def.FieldType = 0 then
    Tables.WriteFieldValue(Field.Table, Field.Row, Field.Field,
      IntToStr(BinToInt(Field.Value, 1, Def.Size)))
  else
    Tables.WriteFieldValue(Field.Table, Field.Row, Field.Field, TrimRight(Field.Value));
end;

function TPrinterEmulator.ReadTable(Password: Integer;
  const Field: TFptrFieldRec): TFptrFieldRec;
var
  Tables: TEmulTables;
  Def: TEmulFieldDef;
begin
  Result := Field;
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if Field.Table = 2 then
  begin
    Result := ReadTablePassword(Field);
    Exit;
  end;

  if FEmulTables = nil then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);

  Tables := TEmulTables(FEmulTables);
  if not Tables.ReadFieldDef(Field.Table, Field.Row, Field.Field, Def) then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
  Result.Value := FieldValueToBin(Def);
end;

procedure TPrinterEmulator.SetOperator(Index: Integer;
  const Value: TFptrOperatorRec);
begin
  FOperators[Index] := Value;
end;

procedure TPrinterEmulator.SetPointPosition(Password,
  APointPosition: Integer);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not(APointPosition in [0..1]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  if Mode4 <> FPTR_MODE_POINTPOS then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FPointPosition := APointPosition;
end;

class function TPrinterEmulator.ValidTime(const Time: TPrinterTime): Boolean;
begin
  Result :=
    (Time.Hour in [0..23])and
    (Time.Min in [0..59]) and
    (Time.Sec in [0..59]);
end;

class function TPrinterEmulator.ValidDate(const Date: TPrinterDate): Boolean;
begin
  Result :=
    (Date.Day in [1..31])and
    (Date.Month in [1..12]) and
    (Date.Year in [0..99]);
end;

procedure TPrinterEmulator.SetTime(Password: Integer;
  const ATime: TPrinterTime);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not ValidTime(ATime) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  FTime := ATime;
end;

procedure TPrinterEmulator.SetDate(Password: Integer;
  const ADate: TPrinterDate);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not ValidDate(ADate) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  FDate := ADate;
  FMode := FPTR_MODE_WAITDATE;
end;

procedure TPrinterEmulator.ConfirmDate(Password: Integer;
  const ADate: TPrinterDate);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not ValidDate(ADate) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  if ComparePrinterDate(Date, ADate) <> 0 then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  if Mode <> FPTR_MODE_WAITDATE then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FMode := FPTR_MODE_DAY_CLOSED;
end;

procedure TPrinterEmulator.InitTables(Password: Integer);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if Mode <> FPTR_MODE_DAY_CLOSED then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  InitializeTables;
end;

function TPrinterEmulator.CutPaper(Password, CutType: Integer): Integer;
begin
  Result := FindOperator(Password, 0);

  if not (CutType in [0..1]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  ReceiptLines.AddCut(CutType);
end;

function TPrinterEmulator.ReadFont(Password,
  FontNumber: Integer): TFptrFontRec;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  if not (FontNumber in [1..7]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result := FFonts[FontNumber];
end;

function TPrinterEmulator.GetFont(Index: Integer): TFptrFontRec;
begin
  Result := FFonts[Index];
end;

procedure TPrinterEmulator.SetFont(Index: Integer;
  const Value: TFptrFontRec);
begin
  FFonts[Index] := Value;
end;

procedure TPrinterEmulator.TotalReset(Password: Integer);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  { !!! }
end;

function TPrinterEmulator.OpenDrawer(Password,
  DrawerNumber: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  FDrawerOpened := True;
end;

procedure TPrinterEmulator.CloseDrawer;
begin
  FDrawerOpened := False;
end;

function TPrinterEmulator.FeedPaper(Password, Flags,
  LineCount: Integer): Integer;
begin
  Result := FindOperator(Password, 0);

  if IsRecStation(Flags) then
    ReceiptLines.AddFeed(LineCount);

  if IsJrnStation(Flags) then
    JournalLines.AddFeed(LineCount);

  if IsSlpStation(Flags) then
    SlipLines.AddFeed(LineCount);
end;

function TPrinterEmulator.StopTest(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);

  if Mode <> FPTR_MODE_TEST then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FMode := FPTR_MODE_DAY_CLOSED;
end;

function TPrinterEmulator.PrintOperatingRegisters(
  Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  { !!! }
end;

function TPrinterEmulator.ReadTableDef(Password,
  TableNumber: Integer): TFptrTableRec;
var
  Table: TFptrTable;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Table := Tables.ItemByNumber(TableNumber);
  if Table = nil then
    RaiseFptrError($93);

  Result := Table.Data;
end;

procedure TPrinterEmulator.WriteServicePassword(OldPassword,
  NewPassword: Integer);
begin
  if ServicePassword.Valid then
  begin
    if OldPassword <> ServicePassword.Password then
      RaiseFptrError(FPTR_E_INVALID_PASSWORD);
  end;

  FServicePassword.Valid := True;
  FServicePassword.Password := NewPassword;
end;

function TPrinterEmulator.PrintBarcode(Password: Integer;
  Barcode: Int64): Integer;
begin
  Result := FindOperator(Password, 0);
  ReceiptLines.AddBarcode(Barcode);
end;

function TPrinterEmulator.OpenReceipt(Password, RecType: Integer): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  case Mode of
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      Receipt.Open(Operator, RecType);
      FMode := FPTR_MODE4_REC + (RecType shl 4);
      TEmulFNState(FFNState).OnLegacyReceiptOpen(RecType);
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.PrintCopy(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  { !!! }
end;

procedure TPrinterEmulator.CheckItem(const Item: TFptrItemRec);
begin

end;

function TPrinterEmulator.Sale(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECSALE,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.Sale(Operator, Item);
      FMode := FPTR_MODE_RECSALE;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.RetSale(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECRETSALE,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.RetSale(Operator, Item);
      FMode := FPTR_MODE_RECRETSALE;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.Buy(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECBUY,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.Buy(Operator, Item);
      FMode := FPTR_MODE_RECBUY;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.RetBuy(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECRETBUY,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.RetBuy(Operator, Item);
      FMode := FPTR_MODE_RECRETBUY;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.Storno(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  if Mode4 <> FPTR_MODE4_REC then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FReceipt.Storno(Operator, Item);
  Result := Operator;
end;

procedure TPrinterEmulator.CheckReceiptOpened;
begin
  if Mode4 <> FPTR_MODE4_REC then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
end;

function TPrinterEmulator.CloseReceipt(Password: Integer;
  const CloseReceipt: TFptrCloseReceipt): TFptrCloseReceiptResult;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Result.Change := Receipt.Close(Operator, CloseReceipt);
  Result.Operator := Operator;

  TEmulFNState(FFNState).OnLegacyReceiptClosed(Receipt.Total);
  FDayOpened := True;
  FMode := FPTR_MODE_DAY_OPENED;
end;

function TPrinterEmulator.Discount(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.MakeDiscount(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.Charge(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.MakeCharge(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.CancelReceipt(Password: Integer): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckReceiptOpened;
  Receipt.Cancel(Operator);
  Result := Operator;

  if FDayOpened then
    FMode := FPTR_MODE_DAY_OPENED
  else
    FMode := FPTR_MODE_DAY_CLOSED;
end;

function TPrinterEmulator.ReadSubtotal(Password: Integer): TFptrSubtotal;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckReceiptOpened;

  Result.Operator := Operator;
  Result.Subtotal := Receipt.Total;
end;

function TPrinterEmulator.StornoCharge(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.StornoCharge(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.StornoDiscount(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.StornoDiscount(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.OpenSession(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  case Mode of
    FPTR_MODE_DAY_CLOSED:
    begin
      FMode := FPTR_MODE_DAY_OPENED;
      FDayOpened := True;
    end;
    FPTR_MODE_DAY_OPENED:
      ;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  TEmulFNState(FFNState).OnLegacySessionOpen;
end;

function TPrinterEmulator.ExecuteFNCommand(Code: Integer;
  const Data: AnsiString): AnsiString;
begin
  Result := TEmulFNState(FFNState).ExecuteCommand(Code, Self, Data);
end;

function TPrinterEmulator.ExecuteFECommand(Code: Integer;
  const Data: AnsiString): AnsiString;
begin
  Result := EmulFEExecute(Self, Code, Data);
end;

function TPrinterEmulator.XReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED: ;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
end;

function TPrinterEmulator.ZReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  TEmulFNState(FFNState).OnLegacySessionClose;
  FDayOpened := False;
  FMode := FPTR_MODE_DAY_CLOSED;
  Inc(FFiscalMemory.DayNumber);
end;

function TPrinterEmulator.DepReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
end;

function TPrinterEmulator.TaxReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
end;

function TPrinterEmulator.CashIn(Password: Integer;
  Amount: Int64): TFptrDocResult;
begin
  Result.Operator := FindOperator(Password, 0);

  case Mode of
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:
    begin
      FCashAmount := FCashAmount + Amount;
      Inc(FDocNumber);
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result.DocNumber := DocNumber;
end;

function TPrinterEmulator.CashOut(Password: Integer;
  Amount: Int64): TFptrDocResult;
begin
  Result.Operator := FindOperator(Password, 0);

  case Mode of
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:
    begin
      if Amount > FCashAmount then
        RaiseFptrError(FPTR_E_SMENA_CASH_MINUS);

      FCashAmount := FCashAmount - Amount;
      Inc(FDocNumber);
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result.DocNumber := DocNumber;
end;

function TPrinterEmulator.PrintHeader(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Inc(FDocNumber);
end;

function TPrinterEmulator.PrintDocEnd(Password,
  Parameter: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  if not (Parameter in [0..1]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);
end;

function TPrinterEmulator.PrintTrailer(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
end;

procedure TPrinterEmulator.WriteSerial(Password, ASerial: Integer);
begin
  FindOperator(Password, 0);
  FSerial.Valid := True;
  FSerial.Number := ASerial;
end;

function TPrinterEmulator.ReadFMTotals(Password,
  RequestType: Integer): TFMTotals;
begin
  Result.Operator := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case RequestType of
    0:
    begin
      Result.SaleTotal := FFiscalMemory.GlobalSaleTotal;
      Result.BuyTotal := FFiscalMemory.GlobalBuyTotal;
      Result.RetSaleTotal := FFiscalMemory.GlobalRetSaleTotal;
      Result.RetBuyTotal := FFiscalMemory.GlobalRetBuyTotal;
    end;
    1:
    begin
      Result.SaleTotal := FFiscalMemory.SaleTotal;
      Result.BuyTotal := FFiscalMemory.BuyTotal;
      Result.RetSaleTotal := FFiscalMemory.RetSaleTotal;
      Result.RetBuyTotal := FFiscalMemory.RetBuyTotal;
    end;
  else
    RaiseFptrError(FPTR_E_INVALID_PARAM);
  end;
end;

function TPrinterEmulator.GetDate: TPrinterDate;
var
  y, m, d: Word;
begin
  DecodeDate(Now, y, m, d);
  Result.Day := d;
  Result.Month := m;
  Result.Year := y - 2000;
end;

function TPrinterEmulator.GetTime: TPrinterTime;
var
  h, m, s, ms: Word;
begin
  DecodeTime(Now, h, m, s, ms);
  Result.Hour := h;
  Result.Min := m;
  Result.Sec := s;
end;

function TPrinterEmulator.GetSerial: TFptrSerialRec;
begin
  Result.Valid := True;
  Result.Number := 12345678;
end;

{ TFptrReceipt }

procedure TFptrReceipt.Reset;
var
  i: Integer;
begin
  FOpened := False;
  FRecType := 0;
  FOperator := 0;
  FOperations := 0;
  for i := 1 to 16 do
    FDepartments[i].Total := 0;
  FCharge := 0;
  FDiscount := 0;
end;

procedure TFptrReceipt.Open(AOperator, ARecType: Integer);
begin
  if not (ARecType in [0..3]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Reset;
  FOpened := True;
  FRecType := ARecType;
  FOperator := AOperator;
end;

function TFptrReceipt.GetDepartment(Value: Integer): Integer;
begin
  Result := Value;
  if Result = 0 then Result := 1;
end;

procedure TFptrReceipt.AddItem(AOperator: Integer; const Item: TFptrItemRec;
  ARecType: Integer);
var
  Amount: Int64;
  Department: Integer;
begin
  if Opened then
  begin
    if RecType <> ARecType then
      RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

    if FOperator <> AOperator then
      RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);
  end else
  begin
    Open(AOperator, ARecType);
  end;
  Department := GetDepartment(Item.Department);
  FOperations := FOperations + 1;
  Amount := Round(Item.Price*Item.Quantity/1000);
  FDepartments[Department].Total :=
    FDepartments[Department].Total + Amount;
end;

procedure TFptrReceipt.Sale(AOperator: Integer; const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_SALE);
end;

procedure TFptrReceipt.Buy(AOperator: Integer; const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_BUY);
end;

procedure TFptrReceipt.RetBuy(AOperator: Integer;
  const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_RETBUY);
end;

procedure TFptrReceipt.RetSale(AOperator: Integer;
  const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_RETSALE);
end;

procedure TFptrReceipt.Storno(AOperator: Integer;
  const Item: TFptrItemRec);
var
  Amount: Int64;
  Department: Integer;
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  FOperations := FOperations + 1;

  Amount := Round(Item.Price*Item.Quantity/1000);
  Department := GetDepartment(Item.Department);
  if Amount > FDepartments[Department].Total then
    RaiseFptrError(FPTR_E_PLACE_CASH_MINUS);

  FDepartments[Department].Total := FDepartments[Department].Total - Amount;
end;

function TFptrReceipt.GetTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 16 do
    Result := Result + FDepartments[i].Total;
  Result := Result + FCharge - FDiscount;
end;

function TFptrReceipt.Close(AOperator: Integer;
  const Params: TFptrCloseReceipt): Int64;
var
  Amount: Int64;
  CashlessAmount: Int64;
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  CashlessAmount := Params.Amount2 + Params.Amount3 + Params.Amount4;
  Amount := Params.Amount1 + Params.Amount2 + Params.Amount3 + Params.Amount4;

  if Amount < Total then
    RaiseFptrError(FPTR_E_ALLSUMM_LESS_ITOG);

  if CashlessAmount > Total then
    RaiseFptrError(FPTR_E_BEZNAL_MORE_CHECK_SUMM);

  Result := Amount - Total;
  Reset;
end;

procedure TFptrReceipt.MakeDiscount(AOperator: Integer; const Discount: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  if Discount.Amount > Total then
    RaiseFptrError(FPTR_E_CHECK_ITOG_MINUS);

  FOperations := FOperations + 1;
  FDiscount := FDiscount + Discount.Amount;
end;

procedure TFptrReceipt.MakeCharge(AOperator: Integer; const Charge: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  FOperations := FOperations + 1;
  FCharge := FCharge + Charge.Amount;
end;

procedure TFptrReceipt.Cancel(AOperator: Integer);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  Reset;
end;

procedure TFptrReceipt.StornoCharge(AOperator: Integer;
  const Charge: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  if Charge.Amount > FCharge then
    RaiseFptrError(FPTR_E_CHECK_ITOG_MINUS);

  FOperations := FOperations + 1;
  FCharge := FCharge - Charge.Amount;
end;

procedure TFptrReceipt.StornoDiscount(AOperator: Integer;
  const Discount: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  if Discount.Amount > FDiscount then
    RaiseFptrError(FPTR_E_CHECK_ITOG_MINUS);

  FOperations := FOperations + 1;
  FDiscount := FDiscount - Discount.Amount;
end;

{ TFptrCommand_01h }

function TFptrCommand_01h.GetCode: Integer;
begin
  Result := $01;
end;

function TFptrCommand_01h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  DeviceCode: Byte;
  BlockCount: Word;
  Password: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  DeviceCode := Ord(Data[5]);
  if not(DeviceCode in [1..7]) then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;

  case Device.Mode and $0F of
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_LOCKED:;
  else
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
    Exit;
  end;

  BlockCount := (Length(Device.DeviceDumps[DeviceCode]) + DUMP_BLOCK_SIZE -1)
    div DUMP_BLOCK_SIZE;
  Result := #$00 + IntToBin(BlockCount, 2);
  Device.SavedDumpMode := Device.Mode;
  Device.Mode := FPTR_MODE_DUMP;
end;

{ TFptrCommand_02h }

function TFptrCommand_02h.GetCode: Integer;
begin
  Result := $02;
end;

function TFptrCommand_02h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  DeviceCode: Byte;
  BlockCount: Word;
  Password: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  DeviceCode := Ord(Data[5]);
  if not(DeviceCode in [1..7]) then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;

  BlockCount := (Length(Device.DeviceDumps[DeviceCode]) + DUMP_BLOCK_SIZE -1)
    div DUMP_BLOCK_SIZE;

  Result := #$00 + IntToBin(BlockCount, 2);
end;

{ TFptrCommand_13h }

function TFptrCommand_13h.GetCode: Integer;
begin
  Result := $13;
end;

function TFptrCommand_13h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.Beep(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_12h }

function TFptrCommand_12h.GetCode: Integer;
begin
  Result := $12;
end;

function TFptrCommand_12h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Flags: Byte;
  Line: AnsiString;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Flags := Ord(Data[5]);
  Line := Copy(Data, 6, Length(Data));
  Device.PrintBoldLine(Flags, Line);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_14h }

function TFptrCommand_14h.GetCode: Integer;
begin
  Result := $14;
end;

function TFptrCommand_14h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Port: TFptrPortRec;
  Password: Integer;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  Port.Number := Ord(Data[5]);
  if Port.Number <> 0 then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;
  Port.BaudRate := Ord(Data[6]);
  if not(Port.BaudRate in [0..6]) then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;
  Port.Timeout := Ord(Data[7]);
  Device.FPort := Port;
  Result := #$00;
end;

{ TFptrCommand_15h }

function TFptrCommand_15h.GetCode: Integer;
begin
  Result := $15;
end;

function TFptrCommand_15h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Port: TFptrPortRec;
  Password: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  Port.Number := Ord(Data[5]);
  if Port.Number <> 0 then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;
  Result := #$00 + AnsiChar(Device.Port.BaudRate) + AnsiChar(Device.Port.Timeout);
end;

{ TFptrCommand_16h }

function TFptrCommand_16h.GetCode: Integer;
begin
  Result := $16;
end;

function TFptrCommand_16h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
begin
  if Device.Mode4 <> FPTR_MODE_TECH then
  begin
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
    Exit;
  end;

  Device.ResetStatus;
  Result := #$00;
end;

{ TFptrCommand_17h }

function TFptrCommand_17h.GetCode: Integer;
begin
  Result := $17;
end;

function TFptrCommand_17h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Flags: Byte;
  Line: AnsiString;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Flags := Ord(Data[5]);
  Line := Copy(Data, 6, Length(Data));
  Device.PrintLine(Flags, Line, FPTR_FONT_DEFAULT);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_18h }

function TFptrCommand_18h.GetCode: Integer;
begin
  Result := $18;
end;

function TFptrCommand_18h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  DocName: AnsiString;
  DocNumber: Integer;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 36);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  DocName := Copy(Data, 5, 30);
  DocNumber := BinToInt(Data, 35, 2);
  Device.PrintDocHeader(DocName, DocNumber);
  Result := #$00 + AnsiChar(Operator) + IntToBin(Device.DocNumber, 2);
end;

{ TFptrCommand_19h }

function TFptrCommand_19h.GetCode: Integer;
begin
  Result := $19;
end;

function TFptrCommand_19h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Period: Integer;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Period := Ord(Data[5]);
  Operator := Device.StartTest(Password, Period);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_1Ah }

function TFptrCommand_1Ah.GetCode: Integer;
begin
  Result := $1A;
end;

function TFptrCommand_1Ah.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  RegNumber: Integer;
  Password: Integer;
  CashReg: TFptrAmountRegRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RegNumber := Ord(Data[5]);
  CashReg := Device.ReadCashReg(Password, RegNumber);
  Result := #$00 + AnsiChar(CashReg.Operator) + IntToBin(CashReg.RegValue, 6);
end;

{ TFptrCommand_1Bh }

function TFptrCommand_1Bh.GetCode: Integer;
begin
  Result := $1B;
end;

function TFptrCommand_1Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  RegNumber: Integer;
  Reg: TFptrOperatingRegRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RegNumber := Ord(Data[5]);
  Reg := Device.ReadOperatingReg(Password, RegNumber);
  Result := #$00 + AnsiChar(Reg.Operator) + IntToBin(Reg.RegValue, 2);
end;

{ TFptrCommand_1Ch }

function TFptrCommand_1Ch.GetCode: Integer;
begin
  Result := $1C;
end;

function TFptrCommand_1Ch.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  License: Int64;
  Password: Integer;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  License := BinToInt(Data, 5, 5);
  Device.WriteLicense(Password, License);
  Result := #$00;
end;

{ TFptrCommand_1Dh }

function TFptrCommand_1Dh.GetCode: Integer;
begin
  Result := $1D;
end;

function TFptrCommand_1Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  License: Int64;
  Password: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  License := Device.ReadLicense(Password);
  Result := #$00 + IntToBin(License, 5);
end;

{ TFptrCommand_1Eh }

function TFptrCommand_1Eh.GetCode: Integer;
begin
  Result := $1E;
end;

function TFptrCommand_1Eh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Field: TFptrFieldRec;
  Password: Integer;
begin
  CheckMinLength(Data, 8);
  Password := BinToInt(Data, 1, 4);
  Field.Table := Ord(Data[5]);
  Field.Row := BinToInt(Data, 6, 2);
  Field.Field := Ord(Data[8]);
  Field.Value := Copy(Data, 9, Length(Data));
  Device.WriteTable(Password, Field);
  Result := #$00;
end;

{ TFptrCommand_1Fh }

function TFptrCommand_1Fh.GetCode: Integer;
begin
  Result := $1F;
end;

function TFptrCommand_1Fh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Field: TFptrFieldRec;
  Password: Integer;
begin
  CheckMinLength(Data, 8);
  Password := BinToInt(Data, 1, 4);
  Field.Table := Ord(Data[5]);
  Field.Row := BinToInt(Data, 6, 2);
  Field.Field := Ord(Data[8]);
  Field.Value := '';
  Field := Device.ReadTable(Password, Field);
  Result := #$00 + Field.Value;
end;

{ TFptrCommand_20h }

function TFptrCommand_20h.GetCode: Integer;
begin
  Result := $20;
end;

function TFptrCommand_20h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  PointPosition: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  PointPosition := Ord(Data[5]);
  Device.SetPointPosition(Password, PointPosition);
  Result := #$00;
end;

{ TFptrCommand_21h }

function TFptrCommand_21h.GetCode: Integer;
begin
  Result := $21;
end;

function TFptrCommand_21h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Time: TPrinterTime;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Time.Hour := Ord(Data[5]);
  Time.Min := Ord(Data[6]);
  Time.Sec := Ord(Data[7]);
  Device.SetTime(Password, Time);
  Result := #$00;
end;

{ TFptrCommand_22h }

function TFptrCommand_22h.GetCode: Integer;
begin
  Result := $22;
end;

function TFptrCommand_22h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Date: TPrinterDate;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Date.Day := Ord(Data[5]);
  Date.Month := Ord(Data[6]);
  Date.Year := Ord(Data[7]);
  Device.SetDate(Password, Date);
  Result := #$00;
end;

{ TFptrCommand_23h }

function TFptrCommand_23h.GetCode: Integer;
begin
  Result := $23;
end;

function TFptrCommand_23h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Date: TPrinterDate;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Date.Day := Ord(Data[5]);
  Date.Month := Ord(Data[6]);
  Date.Year := Ord(Data[7]);
  Device.ConfirmDate(Password, Date);
  Result := #$00;
end;

{ TFptrCommand_24h }

function TFptrCommand_24h.GetCode: Integer;
begin
  Result := $24;
end;

function TFptrCommand_24h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Device.InitTables(Password);
  Result := #$00;
end;

{ TFptrCommand_25h }

function TFptrCommand_25h.GetCode: Integer;
begin
  Result := $25;
end;

function TFptrCommand_25h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  CutType: Byte;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  CutType := Ord(Data[5]);
  Operator := Device.CutPaper(Password, CutType);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_26h }

function TFptrCommand_26h.GetCode: Integer;
begin
  Result := $26;
end;

function TFptrCommand_26h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  FontNumber: Byte;
  Password: Integer;
  Font: TFptrFontRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  FontNumber := Ord(Data[5]);
  Font := Device.ReadFont(Password, FontNumber);

  Result := #$00 + IntToBin(Font.PrintWidth, 2) +
    AnsiChar(Font.CharWidth) +
    AnsiChar(Font.CharHeight) +
    AnsiChar(Font.FontCount);
end;

{ TFptrCommand_27h }

function TFptrCommand_27h.GetCode: Integer;
begin
  Result := $27;
end;

function TFptrCommand_27h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Device.TotalReset(Password);
  Result := #$00;
end;

{ TFptrCommand_28h }

function TFptrCommand_28h.GetCode: Integer;
begin
  Result := $28;
end;

function TFptrCommand_28h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  DrawerNumber: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  DrawerNumber := Ord(Data[5]);
  Operator := Device.OpenDrawer(Password, DrawerNumber);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_29h }

function TFptrCommand_29h.GetCode: Integer;
begin
  Result := $29;
end;

function TFptrCommand_29h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Flags: Integer;
  LineCount: Integer;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 6);
  Password := BinToInt(Data, 1, 4);
  Flags := Ord(Data[5]);
  LineCount := Ord(Data[6]);
  Operator := Device.FeedPaper(Password, Flags, LineCount);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_2Bh }

function TFptrCommand_2Bh.GetCode: Integer;
begin
  Result := $2B;
end;

function TFptrCommand_2Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.StopTest(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_2Ch }

function TFptrCommand_2Ch.GetCode: Integer;
begin
  Result := $2C;
end;

function TFptrCommand_2Ch.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintOperatingRegisters(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_2Dh }

function TFptrCommand_2Dh.GetCode: Integer;
begin
  Result := $2D;
end;

function TFptrCommand_2Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  TableNumber: Byte;
  Table: TFptrTableRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  TableNumber := Ord(Data[5]);
  Table := Device.ReadTableDef(Password, TableNumber);
  Result := #$00 + GetStrLen(Table.Name, 40) +
    IntToBin(Table.RowCount, 2) + AnsiChar(Table.FieldCount);
end;

{ TFptrCommand_2Eh }

function TFptrCommand_2Eh.GetCode: Integer;
begin
  Result := $2E;
end;

function TFptrCommand_2Eh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  TableNumber: Byte;
  FieldNumber: Byte;
  Def: TEmulFieldDef;
begin
  CheckMinLength(Data, 6);
  Password := BinToInt(Data, 1, 4);
  TableNumber := Ord(Data[5]);
  FieldNumber := Ord(Data[6]);
  Device.ReadFieldStruct(Password, TableNumber, FieldNumber, Def);
  Result := #$00 + GetStrLen(Def.Name, 40) + AnsiChar(Def.FieldType);
  if Def.FieldType = 0 then
    Result := Result + AnsiChar(Def.Size) +
      IntToBin(Def.MinValue, Def.Size) + IntToBin(Def.MaxValue, Def.Size)
  else
    Result := Result + AnsiChar(Def.Size);
end;

{ TFptrCommand_2Fh }

(******************************************************************************

  ?????? ?????? ?????? ???????

  ???????:	2FH. ????? ?????????: 47 ????.
  ?????? ????????? (4 ?????)
  ????? (1 ????) ??? 0 - ??????????? ?????, ??? 1 - ??????? ?????.
  ????? ?????? (1 ????) 0?255
  ?????????? ??????? (40 ????)

  ?????:		2FH. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_2Fh.GetCode: Integer;
begin
  Result := $2F;
end;

function TFptrCommand_2Fh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Font: Integer;
  Flags: Integer;
  Password: Integer;
  Operator: Integer;
  Line: AnsiString;
begin
  CheckMinLength(Data, 6);
  Password := BinToInt(Data, 1, 4);
  Flags := Ord(Data[5]);
  Font := Ord(Data[6]);
  Line := Copy(Data, 7, Length(Data));
  Operator := Device.FindOperator(Password, 0);
  Device.PrintLine(Flags, Line, Font);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_F3h }

function TFptrCommand_F3h.GetCode: Integer;
begin
  Result := $F3;
end;

function TFptrCommand_F3h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  OldPassword: Integer;
  NewPassword: Integer;
begin
  CheckMinLength(Data, 8);
  OldPassword := BinToInt(Data, 1, 4);
  NewPassword := BinToInt(Data, 5, 4);
  Device.WriteServicePassword(OldPassword, NewPassword);
  Result := #$00;
end;

{ TFptrCommand_FCh }

function TFptrCommand_FCh.GetCode: Integer;
begin
  Result := $FC;
end;

function TFptrCommand_FCh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
begin
  Result := #$00 +
    AnsiChar(Device.DeviceMetrics.DeviceType) +
    AnsiChar(Device.DeviceMetrics.DeviceSubtype) +
    AnsiChar(Device.DeviceMetrics.ProtocolVersion) +
    AnsiChar(Device.DeviceMetrics.ProtocolSubVersion) +
    AnsiChar(Device.DeviceMetrics.Model) +
    AnsiChar(Device.DeviceMetrics.Language) +
    Device.DeviceMetrics.DeviceName;
end;

{ TFptrCommand_C2h }

function TFptrCommand_C2h.GetCode: Integer;
begin
  Result := $C2;
end;

function TFptrCommand_C2h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Barcode: Int64;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  Barcode := BinToInt(Data, 5, 5);
  Operator := Device.PrintBarcode(Password, Barcode);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_8Dh }

function TFptrCommand_8Dh.GetCode: Integer;
begin
  Result := $8D;
end;

function TFptrCommand_8Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  RecType: Integer;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RecType := Ord(Data[5]);
  Operator := Device.OpenReceipt(Password, RecType);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_8Ch }

function TFptrCommand_8Ch.GetCode: Integer;
begin
  Result := $8C;
end;

function TFptrCommand_8Ch.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintCopy(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_80h }

(*
???????
???????: 80H. ????? ?????????: 60 ????.
?????? ????????? (4 ?????)
?????????? (5 ????) 0000000000?9999999999
???? (5 ????) 0000000000?9999999999
????? ?????? (1 ????) 0?16
????? 1 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? 2 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? 3 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? 4 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? (40 ????)
?????: 80H. ????? ?????????: 3 ?????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30
*)

function TFptrCommand_80h.GetCode: Integer;
begin
  Result := $80;
end;

function TFptrCommand_80h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.Sale(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;


{ TFptrCommand_81h }

function TFptrCommand_81h.GetCode: Integer;
begin
  Result := $81;
end;

function TFptrCommand_81h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.Buy(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_82h }

function TFptrCommand_82h.GetCode: Integer;
begin
  Result := $82;
end;

function TFptrCommand_82h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.RetSale(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_83h }

function TFptrCommand_83h.GetCode: Integer;
begin
  Result := $83;
end;

function TFptrCommand_83h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.RetBuy(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_84h }

function TFptrCommand_84h.GetCode: Integer;
begin
  Result := $84;
end;

function TFptrCommand_84h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.Storno(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_85h }

(******************************************************************************

???????? ????

???????:	85H. ????? ?????????: 71 ????.
?????? ????????? (4 ?????)
????? ???????? (5 ????) 0000000000?9999999999
????? ???? ?????? 2 (5 ????) 0000000000?9999999999
????? ???? ?????? 3 (5 ????) 0000000000?9999999999
????? ???? ?????? 4 (5 ????) 0000000000?9999999999
??????/????????(? ?????? ?????????????? ????????) ? % ?? ??? ?? 0 ?? 99,99 % (2 ????? ?? ??????) -9999?9999
????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? (40 ????)

?????:		85H. ????? ?????????: 8 ????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30
????? (5 ????) 0000000000?9999999999


*******************************************************************************)

function TFptrCommand_85h.GetCode: Integer;
begin
  Result := $85;
end;

function TFptrCommand_85h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  CloseReceipt: TFptrCloseReceipt;
  CloseResult: TFptrCloseReceiptResult;
begin
  CheckMinLength(Data, 30);
  Password := BinToInt(Data, 1, 4);
  CloseReceipt.Amount1 := BinToInt(Data, 5, 5);
  CloseReceipt.Amount2 := BinToInt(Data, 10, 5);
  CloseReceipt.Amount3 := BinToInt(Data, 15, 5);
  CloseReceipt.Amount4 := BinToInt(Data, 20, 5);
  CloseReceipt.Discount := BinToInt(Data, 25, 2);
  CloseReceipt.Tax1 := Ord(Data[27]);
  CloseReceipt.Tax2 := Ord(Data[28]);
  CloseReceipt.Tax3 := Ord(Data[29]);
  CloseReceipt.Tax4 := Ord(Data[30]);
  CloseReceipt.Text := Copy(Data, 31, Length(Data));
  CloseResult := Device.CloseReceipt(Password, CloseReceipt);
  Result := #$00 +
    AnsiChar(CloseResult.Operator) +
    IntToBin(CloseResult.Change, 5);
end;

{ TFptrCommand_86h }

(******************************************************************************

??????
???????:	86H. ????? ?????????: 54 ????.
?????? ????????? (4 ?????)
????? (5 ????) 0000000000?9999999999
????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? (40 ????)
?????:		86H. ????? ?????????: 3 ?????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_86h.GetCode: Integer;
begin
  Result := $86;
end;

function TFptrCommand_86h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Discount: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Discount.Amount := BinToInt(Data, 5, 5);
  Discount.Tax1 := Ord(Data[10]);
  Discount.Tax2 := Ord(Data[11]);
  Discount.Tax3 := Ord(Data[12]);
  Discount.Tax4 := Ord(Data[13]);
  Discount.Text := Copy(Data, 14, Length(Data));
  Operator := Device.Discount(Password, Discount);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_87h }

function TFptrCommand_87h.GetCode: Integer;
begin
  Result := $87;
end;

function TFptrCommand_87h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Charge: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Charge.Amount := BinToInt(Data, 5, 5);
  Charge.Tax1 := Ord(Data[10]);
  Charge.Tax2 := Ord(Data[11]);
  Charge.Tax3 := Ord(Data[12]);
  Charge.Tax4 := Ord(Data[13]);
  Charge.Text := Copy(Data, 14, Length(Data));
  Operator := Device.Charge(Password, Charge);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_88h }

(******************************************************************************

????????????? ????
???????:	88H. ????? ?????????: 5 ????.
?????? ????????? (4 ?????)
?????:		88H. ????? ?????????: 3 ?????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_88h.GetCode: Integer;
begin
  Result := $88;
end;

function TFptrCommand_88h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.CancelReceipt(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_89h }

(******************************************************************************

??????? ????
???????:	89H. ????? ?????????: 5 ????.
?????? ????????? (4 ?????)
?????:		89H. ????? ?????????: 8 ????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30
??????? ???? (5 ????) 0000000000?9999999999

******************************************************************************)

function TFptrCommand_89h.GetCode: Integer;
begin
  Result := $89;
end;

function TFptrCommand_89h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Subtotal: TFptrSubtotal;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Subtotal := Device.ReadSubtotal(Password);
  Result := #$00 + AnsiChar(Subtotal.Operator) +
    IntToBin(Subtotal.Subtotal, 5);
end;

{ TFptrCommand_8Ah }

(******************************************************************************

  ?????? ??????

  ???????:	8AH. ????? ?????????: 54 ?????.
  ?????? ????????? (4 ?????)
  ????? (5 ????) 0000000000?9999999999
  ????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? (40 ????)

  ?????:		8AH. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_8Ah.GetCode: Integer;
begin
  Result := $8A;
end;

function TFptrCommand_8Ah.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Discount: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Discount.Amount := BinToInt(Data, 5, 5);
  Discount.Tax1 := Ord(Data[10]);
  Discount.Tax2 := Ord(Data[11]);
  Discount.Tax3 := Ord(Data[12]);
  Discount.Tax4 := Ord(Data[13]);
  Discount.Text := Copy(Data, 14, Length(Data));
  Operator := Device.StornoDiscount(Password, Discount);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_8Bh }

(******************************************************************************

  ?????? ????????

  ???????:	8BH. ????? ?????????: 54 ?????.
  ?????? ????????? (4 ?????)
  ????? (5 ????) 0000000000?9999999999
  ????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? (40 ????)

  ?????:		8BH. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_8Bh.GetCode: Integer;
begin
  Result := $8B;
end;

function TFptrCommand_8Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Discount: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Discount.Amount := BinToInt(Data, 5, 5);
  Discount.Tax1 := Ord(Data[10]);
  Discount.Tax2 := Ord(Data[11]);
  Discount.Tax3 := Ord(Data[12]);
  Discount.Tax4 := Ord(Data[13]);
  Discount.Text := Copy(Data, 14, Length(Data));
  Operator := Device.StornoCharge(Password, Discount);
  Result := #$00 + AnsiChar(Operator);
end;


{ TFptrCommand_40h }

function TFptrCommand_40h.GetCode: Integer;
begin
  Result := $40;
end;

function TFptrCommand_40h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.XReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_41h }

function TFptrCommand_41h.GetCode: Integer;
begin
  Result := $41;
end;

function TFptrCommand_41h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.ZReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_42h }

(******************************************************************************

  ????? ?? ???????

  ???????:	42H. ????? ?????????: 5 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)

  ?????:		42H. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30

******************************************************************************)

function TFptrCommand_42h.GetCode: Integer;
begin
  Result := $42;
end;

function TFptrCommand_42h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.DepReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_43h }

(******************************************************************************

  ????? ?? ???????

  ???????:	43H. ????? ?????????: 5 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)

  ?????:		43H. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30

******************************************************************************)

function TFptrCommand_43h.GetCode: Integer;
begin
  Result := $43;
end;

function TFptrCommand_43h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.TaxReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_50h }

(******************************************************************************

  ????????

  ???????:	50H. ????? ?????????: 10 ????.
  ?????? ????????? (4 ?????)
  ????? (5 ????)

  ?????:		50H. ????? ?????????: 5 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30
  ???????? ????? ????????? (2 ?????)

******************************************************************************)

function TFptrCommand_50h.GetCode: Integer;
begin
  Result := $50;
end;

function TFptrCommand_50h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Amount: Int64;
  Password: Integer;
  DocResult: TFptrDocResult;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  Amount := BinToInt(Data, 5, 5);
  DocResult := Device.CashIn(Password, Amount);
  Result := #$00 + AnsiChar(DocResult.Operator) + IntToBin(DocResult.DocNumber, 2);
end;

{ TFptrCommand_51h }

(******************************************************************************

  ???????

  ???????:	51H. ????? ?????????: 10 ????.
  ?????? ????????? (4 ?????)
  ????? (5 ????)

  ?????:		51H. ????? ?????????: 5 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30
  ???????? ????? ????????? (2 ?????)

******************************************************************************)

function TFptrCommand_51h.GetCode: Integer;
begin
  Result := $51;
end;

function TFptrCommand_51h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Amount: Int64;
  Password: Integer;
  DocResult: TFptrDocResult;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  Amount := BinToInt(Data, 5, 5);
  DocResult := Device.CashOut(Password, Amount);
  Result := #$00 + AnsiChar(DocResult.Operator) + IntToBin(DocResult.DocNumber, 2);
end;

{ TFptrCommand_52h }

(******************************************************************************

  ?????? ?????

  ???????:	52H. ????? ?????????: 5 ????.
  ?????? ????????? (4 ?????)

  ?????:		52H. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_52h.GetCode: Integer;
begin
  Result := $52;
end;

function TFptrCommand_52h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintHeader(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_53h }

function TFptrCommand_53h.GetCode: Integer;
begin
  Result := $53;
end;

function TFptrCommand_53h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Parameter: Byte;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Parameter := Ord(Data[5]);
  Operator := Device.PrintDocEnd(Password, Parameter);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_54h }

function TFptrCommand_54h.GetCode: Integer;
begin
  Result := $54;
end;

function TFptrCommand_54h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintTrailer(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_60h }

function TFptrCommand_60h.GetCode: Integer;
begin
  Result := $60;
end;

function TFptrCommand_60h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Serial: DWORD;
  Password: Integer;
begin
  CheckMinLength(Data, 8);
  Password := BinToInt(Data, 1, 4);
  Serial := BinToInt(Data, 5, 4);
  Device.WriteSerial(Password, Serial);
  Result := #$00;
end;

{ TFptrCommand_62h }

(******************************************************************************

  ?????? ????? ??????? ? ??

  ???????:	62H. ????? ?????????: 6 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)
  ??? ??????? (1 ????)
    "0" - ????? ???? ???????,
    "1" - ????? ??????? ????? ????????? ???????????????

  ?????:		62H. ????? ?????????: 29 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30
  ????? ??????? ?????? ?????? (8 ????)
  ????? ??????? ???? ??????? (6 ????) ??? ?????????? ?? 2: FFh FFh FFh FFh FFh FFh
  ????? ??????? ????????? ?????? (6 ????) ??? ?????????? ?? 2: FFh FFh FFh FFh FFh FFh
  ????? ??????? ????????? ??????? (6 ????) ??? ?????????? ?? 2: FFh FFh FFh FFh FFh FFh

*******************************************************************************)

function TFptrCommand_62h.GetCode: Integer;
begin
  Result := $62;
end;

function TFptrCommand_62h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  RequestType: Byte;
  FMTotals: TFMTotals;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RequestType := Ord(Data[5]);
  FMTotals := Device.ReadFMTotals(Password, RequestType);
  Result := #$00 +
    AnsiChar(FMTotals.Operator) +
    IntToBin(FMTotals.SaleTotal, 8) +
    IntToBin(FMTotals.BuyTotal, 6) +
    IntToBin(FMTotals.RetSaleTotal, 6) +
    IntToBin(FMTotals.RetBuyTotal, 6);
end;

{ TFptrCommand_63h }

(******************************************************************************

  ?????? ???? ????????? ?????? ? ??

  ???????:	63H. ????? ?????????: 5 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)

  ?????:		63H. ????? ?????????: 7 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30
  ??? ????????? ?????? (1 ????) "0" - ???????????? (???????????????), "1" - ??????? ????
  ???? (3 ?????) ??-??-??

*******************************************************************************)

function TFptrCommand_63h.GetCode: Integer;
begin
  Result := $63;
end;

function TFptrCommand_63h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  FMRecordResult: TFMRecordResult;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  FMRecordResult.Operator := Device.FindOperator(Password,
    TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  FMRecordResult.Data.RecType := 0;
  FMRecordResult.Data.Date := Device.Date;
  Result := #$00 +
    AnsiChar(FMRecordResult.Operator) +
    AnsiChar(FMRecordResult.Data.RecType) +
    AnsiChar(FMRecordResult.Data.Date.Day) +
    AnsiChar(FMRecordResult.Data.Date.Month) +
    AnsiChar(FMRecordResult.Data.Date.Year);
end;




function EmulDevice(Device: TObject): TPrinterEmulator;
begin
  Result := TPrinterEmulator(Device);
end;

constructor TEmulFNState.Create;
begin
  Reset;
end;

procedure TEmulFNState.Reset;
begin
  LifeState := $03;
  CurrentDocument := 0;
  DocumentData := 0;
  SessionState := 0;
  WarningFlags := 0;
  FNSerial := '0289610204000839';
  SoftVersion := 'FN 1.2.0       ';
  SoftType := 1;
  INN := '1234567890  ';
  KKTRegNumber := '00000000000000000000';
  TaxType := 1;
  WorkMode := 0;
  WorkModeEx := 0;
  SessionNumber := 1;
  ReceiptNumber := 0;
  DocumentNumber := 1;
  FiscalSign := $12345678;
  ExpirationDay := 31;
  ExpirationMonth := 12;
  ExpirationYear := 30;
  FreeRegistration := 16;
  RegNumber := 1;
  UnconfirmedDocCount := 0;
  InfoExchangeStatus := 0;
  MessageState := 0;
  MessageCount := 0;
  FN5YearResource := 3000;
  FN30DayResource := 256;
  FNImplementation := 'FN-1.2';
  FReceiptTotal := 0;
  FReceiptOpened := False;
  FCheckType := 0;
  FTLVBuffer := '';
  FDataBuffer := '';
  FDataBlockSize := 64;
  FRandomSequence := #0#1#2#3#4#5#6#7#8#9#10#11#12#13#14#15;
  FDocCount := 0;
  SetLength(FDocuments, 0);
  FNotificationCount := 0;
  FNotificationNumber := 0;
  FNotificationSize := 0;
  FNotificationOffset := 0;
end;

procedure TEmulFNState.SyncFromDevice(Device: TObject);
var
  Dev: TPrinterEmulator;
begin
  Dev := EmulDevice(Device);
  if Dev.Serial.Valid then
    FNSerial := PadRight(IntToStr(Dev.Serial.Number), 16);
end;

procedure TEmulFNState.OnLegacySessionOpen;
begin
  SessionState := 1;
  LifeState := LifeState or $02;
end;

procedure TEmulFNState.OnLegacySessionClose;
begin
  SessionState := 0;
  Inc(SessionNumber);
  ReceiptNumber := 0;
end;

procedure TEmulFNState.OnLegacyReceiptOpen(RecType: Integer);
begin
  FReceiptOpened := True;
  FReceiptTotal := 0;
  FCheckType := RecType;
  CurrentDocument := 1;
end;

procedure TEmulFNState.OnLegacyReceiptClosed(Total: Int64);
begin
  FReceiptOpened := False;
  Inc(ReceiptNumber);
  SaveDocument(FCheckType + 1, SessionNumber, ReceiptNumber);
  FReceiptTotal := 0;
  CurrentDocument := 0;
end;

function TEmulFNState.NextDocNumber: Cardinal;
begin
  Result := DocumentNumber;
  Inc(DocumentNumber);
end;

function TEmulFNState.NextFiscalSign: Cardinal;
begin
  Result := FiscalSign;
  Inc(FiscalSign);
end;

function TEmulFNState.PadRight(const S: AnsiString; Len: Integer): AnsiString;
begin
  Result := Copy(S, 1, Len);
  if Length(Result) < Len then
    Result := Result + StringOfChar(' ', Len - Length(Result));
end;

function TEmulFNState.BuildDateTime5(Device: TObject): AnsiString;
var
  Dev: TPrinterEmulator;
begin
  Dev := EmulDevice(Device);
  Result := AnsiChar(Dev.Date.Year) +
    AnsiChar(Dev.Date.Month) +
    AnsiChar(Dev.Date.Day) +
    AnsiChar(Dev.Time.Hour) +
    AnsiChar(Dev.Time.Min);
end;

function TEmulFNState.RequireOperator(Device: TObject;
  const Data: AnsiString; out Operator: Integer): AnsiString;
var
  Dev: TPrinterEmulator;
begin
  Dev := EmulDevice(Device);
  if Length(Data) < 4 then
  begin
    Result := AnsiChar(FPTR_E_INVALID_CMD_LEN);
    Operator := 0;
    Exit;
  end;
  Operator := Dev.FindOperator(BinToInt(Data, 1, 4), 0);
  Result := '';
end;

function TEmulFNState.OkOnly: AnsiString;
begin
  Result := #$00;
end;

function TEmulFNState.OkOperator(Operator: Integer): AnsiString;
begin
  Result := #$00 + AnsiChar(Operator);
end;

function TEmulFNState.CloseCheckResult(Total, CashPay: Int64): AnsiString;
var
  Change: Int64;
  DocNum: Cardinal;
  Sign: Cardinal;
begin
  if CashPay >= Total then
    Change := CashPay - Total
  else
    Change := 0;
  DocNum := NextDocNumber;
  Sign := NextFiscalSign;
  SaveDocument(FCheckType + 1, SessionNumber, ReceiptNumber + 1);
  Inc(ReceiptNumber);
  FReceiptOpened := False;
  FReceiptTotal := 0;
  CurrentDocument := 0;
  Result := #$00 +
    IntToBin(Change, 5) +
    IntToBin(DocNum, 4) +
    IntToBin(Sign, 4);
end;

procedure TEmulFNState.SaveDocument(DocType: Byte; SessionNum: Word;
  ReceiptNum: Word);
begin
  if FDocCount >= Length(FDocuments) then
    SetLength(FDocuments, FDocCount + 16);
  FDocuments[FDocCount].DocNumber := DocumentNumber - 1;
  FDocuments[FDocCount].FiscalSign := FiscalSign - 1;
  FDocuments[FDocCount].DocType := DocType;
  FDocuments[FDocCount].SessionNumber := SessionNum;
  FDocuments[FDocCount].ReceiptNumber := ReceiptNum;
  FDocuments[FDocCount].Data := FTLVBuffer;
  Inc(FDocCount);
end;

function TEmulFNState.FindDocument(DocNum: Cardinal;
  out Doc: TEmulFNDocument): Boolean;
var
  i: Integer;
begin
  for i := 0 to FDocCount - 1 do
  begin
    if FDocuments[i].DocNumber = DocNum then
    begin
      Doc := FDocuments[i];
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TEmulFNState.ExecuteCommand(Code: Integer; Device: TObject;
  const Data: AnsiString): AnsiString;
var
  Dev: TPrinterEmulator;
  Operator: Integer;
  Doc: TEmulFNDocument;
  DocNum: Cardinal;
  CashPay: Int64;
  ItemAmount: Int64;
  TagNum: Word;
begin
  Dev := EmulDevice(Device);
  SyncFromDevice(Device);
  case Code of
    $FF01:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      SessionState := 1;
      Result := #$00 +
        AnsiChar(LifeState) +
        AnsiChar(CurrentDocument) +
        AnsiChar(DocumentData) +
        AnsiChar(SessionState) +
        AnsiChar(WarningFlags) +
        BuildDateTime5(Device) +
        PadRight(FNSerial, 16) +
        IntToBin(DocumentNumber, 4);
    end;

    $FF02:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + PadRight(FNSerial, 16);
    end;

    $FF03:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(ExpirationYear) +
        AnsiChar(ExpirationMonth) +
        AnsiChar(ExpirationDay) +
        AnsiChar(FreeRegistration) +
        AnsiChar(RegNumber);
    end;

    $FF04:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + Copy(PadRight(SoftVersion, 16), 1, 16) + AnsiChar(SoftType);
    end;

    $FF05, $FF07, $FF08, $FF35, $FF37, $FF3D, $FF41, $FF42, $FF4D, $FF4E,
    $FF62, $FF64, $FF66, $FF73:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOnly;
    end;

    $FF06, $FF34, $FF3E:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF09, $FF4C:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        BuildDateTime5(Device) +
        PadRight(INN, 12) +
        PadRight(KKTRegNumber, 20) +
        AnsiChar(TaxType) +
        AnsiChar(WorkMode) +
        AnsiChar(WorkModeEx) +
        PadRight('', 12) +
        IntToBin(0, 4) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF0A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) < 8 then
      begin
        Result := AnsiChar(FPTR_E_INVALID_CMD_LEN);
        Exit;
      end;
      DocNum := BinToInt(Data, 5, 4);
      if FindDocument(DocNum, Doc) then
        Result := #$00 + AnsiChar(Doc.DocType) + #1 + Doc.Data
      else
        Result := #$00 + #1#0;
    end;

    $FF0B:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Dev.OpenSession(BinToInt(Data, 1, 4));
      SessionState := 1;
      Result := #$00 +
        IntToBin(SessionNumber, 2) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF0C:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) > 4 then
        FTLVBuffer := FTLVBuffer + Copy(Data, 5, Length(Data));
      Result := OkOnly;
    end;

    $FF0D, $FF44, $FF46:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      FReceiptOpened := True;
      if Length(Data) >= 1 then
        FCheckType := Ord(Data[5]);
      if Length(Data) >= 22 then
        ItemAmount := BinToInt(Data, 17, 5)
      else
        ItemAmount := 0;
      if ItemAmount = 0 then
        ItemAmount := 100;
      Inc(FReceiptTotal, ItemAmount);
      CurrentDocument := 1;
      Result := OkOperator(Operator);
    end;

    $FF0E:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 7 then
      begin
        TagNum := BinToInt(Data, 5, 2);
        if TagNum = $FFFF then
          Result := OkOnly
        else
          Result := #$00 + FTLVBuffer;
      end else
        Result := OkOnly;
    end;

    $FF16:
      Result := OkOnly;

    $FF1A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + AnsiChar(Operator) + StringOfChar(#0, 48);
    end;

    $FF30:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(Length(FDataBuffer), 2) + AnsiChar(FDataBlockSize);
    end;

    $FF31:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 7 then
        Result := #$00 + Copy(FDataBuffer, BinToInt(Data, 5, 2) + 1,
          BinToInt(Data, 7, 1))
      else
        Result := #$00 + FDataBuffer;
    end;

    $FF32:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 6 then
        SetLength(FDataBuffer, BinToInt(Data, 5, 2));
      Result := #$00 + AnsiChar(FDataBlockSize);
    end;

    $FF33:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 7 then
        FDataBuffer := Copy(FDataBuffer, 1, BinToInt(Data, 5, 2)) +
          Copy(Data, 8, BinToInt(Data, 7, 1));
      Result := OkOnly;
    end;

    $FF36, $FF4A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Inc(ReceiptNumber);
      Result := #$00 +
        IntToBin(ReceiptNumber, 2) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF38:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(DocumentNumber, 4) +
        IntToBin(FiscalSign, 4) +
        IntToBin(UnconfirmedDocCount, 4) +
        AnsiChar(Dev.Date.Year) +
        AnsiChar(Dev.Date.Month) +
        AnsiChar(Dev.Date.Day);
    end;

    $FF39:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(InfoExchangeStatus) +
        AnsiChar(MessageState) +
        IntToBin(MessageCount, 2) +
        IntToBin(DocumentNumber, 4) +
        BuildDateTime5(Device);
    end;

    $FF3A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(1, 2) + IntToBin(Length(FTLVBuffer), 2);
    end;

    $FF3B:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + FTLVBuffer;
    end;

    $FF3C:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + BuildDateTime5(Device) +
        PadRight('OFD-TICKET-DATA', 18) +
        IntToBin(DocumentNumber, 4);
    end;

    $FF3F:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(UnconfirmedDocCount, 2);
    end;

    $FF40:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(SessionState) +
        IntToBin(SessionNumber, 2) +
        IntToBin(ReceiptNumber, 2);
    end;

    $FF43:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      OnLegacySessionClose;
      Result := #$00 +
        IntToBin(SessionNumber, 2) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF45, $FF76:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      CashPay := 0;
      if Length(Data) >= 9 then
        CashPay := BinToInt(Data, 5, 5);
      if FReceiptTotal <= 0 then
        FReceiptTotal := CashPay;
      Result := CloseCheckResult(FReceiptTotal, CashPay);
    end;

    $FF4B:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOperator(Operator);
    end;

    $FF50:
    begin
      if Length(Data) < 4 then
        Result := OkOnly
      else
        Result := OkOnly;
    end;

    $FF51:
      Result := #$00 + #0#0 + IntToBin(0, 5) + #0;

    $FF52:
      Result := #$00;

    $FF53:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOnly;
    end;

    $FF61, $FF67:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + #0#1#0#0;
    end;

    $FF63:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(FN5YearResource, 4) +
        IntToBin(FN30DayResource, 4);
    end;

    $FF65:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + FRandomSequence;
    end;

    $FF68:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(MessageState) +
        IntToBin(MessageCount, 2) +
        IntToBin(FNotificationNumber, 4) +
        BuildDateTime5(Device) +
        #0;
    end;

    $FF69:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 5 then
        Result := OkOnly
      else
        Result := #$00 + #0;
    end;

    $FF70:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + #1#0#$FF#0#0#0 + IntToBin(MessageCount, 2);
    end;

    $FF71:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(FNotificationCount, 2) +
        IntToBin(FNotificationNumber, 4) +
        IntToBin(FNotificationSize, 2);
    end;

    $FF72:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(FNotificationNumber, 4) +
        IntToBin(FNotificationSize, 2) +
        IntToBin(FNotificationOffset, 2) +
        IntToBin(0, 2);
    end;

    $FF74:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + PadRight(FNImplementation, 48);
    end;

    $FF75:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(Length(FTLVBuffer), 4) + IntToBin(0, 4);
    end;

    $FF77, $FF78, $FF79, $FFF0, $FFF1:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOnly;
    end;

    $FF47, $FF48, $FF49, $FF4F, $FF54, $FF55, $FF56, $FF57, $FF58, $FF59,
    $FF5A, $FF5B, $FF5C, $FF5D, $FF5E, $FF5F, $FF60, $FF6A, $FF6B, $FF6C,
    $FF6D, $FF6E, $FF6F:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOperator(Operator);
    end;
  else
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT);
  end;
end;





function OkOnly: AnsiString;
begin
  Result := #$00;
end;

function EmulFEExecute(Device: TPrinterEmulator; Code: Integer;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  case Code of
    $FE03:
    begin
      CheckMinLength(Data, 4);
      Password := BinToInt(Data, 1, 4);
      Operator := Device.FindOperator(Password, 0);
      Result := OkOnly + AnsiChar(Operator);
    end;
    $FE05, $FE06, $FE0B, $FEF3, $FEED, $FEEE, $FEE8, $FEE9, $FEE6, $FEF1,
    $FEF5:
      Result := OkOnly;
    $FE09:
      Result := OkOnly + StringOfChar(#0, 32);
    $FE0C:
      Result := OkOnly + #0;
    $FE0F:
      Result := OkOnly + #2;
    $FEF2:
      Result := OkOnly + #0 + IntToBin(10, 4);
    $FEF4:
      Result := OkOnly +
        IntToBin(0, 8) + IntToBin(0, 8) + IntToBin(0, 8) + IntToBin(0, 8);
    $FEEC:
      Result := OkOnly + IntToBin(153, 4);
    $FEEF:
      Result := OkOnly + StringOfChar(#0, 60);
    $FEE7:
      Result := OkOnly + StringOfChar(#0, 64);
    $FEFB:
      Result := '';
    else
      Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT);
  end;
end;

procedure RegisterFECommands(Commands: TFptrCommands);

  procedure Reg(Code: Integer);
  begin
    if Commands.ItemByCode(Code) = nil then
      TFptrFECommand.Create(Commands, Code);
  end;

begin
  Reg($FE03); Reg($FE05); Reg($FE06); Reg($FE09); Reg($FE0B); Reg($FE0C);
  Reg($FE0F); Reg($FEE6); Reg($FEE7); Reg($FEE8); Reg($FEE9); Reg($FEEC);
  Reg($FEED); Reg($FEEE); Reg($FEEF); Reg($FEF1); Reg($FEF2); Reg($FEF3);
  Reg($FEF4); Reg($FEF5); Reg($FEFB);
end;

{ TFptrFECommand }

constructor TFptrFECommand.Create(AOwner: TFptrCommands; ACode: Integer);
begin
  inherited Create(AOwner);
  FCode := ACode;
end;

function TFptrFECommand.GetCode: Integer;
begin
  Result := FCode;
end;

function TFptrFECommand.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
begin
  Result := Device.ExecuteFECommand(FCode, Data);
end;



procedure RegisterFNCommands(Commands: TFptrCommands);

  procedure Reg(Code: Integer);
  begin
    if Commands.ItemByCode(Code) = nil then
      TFptrFNCommand.Create(Commands, Code);
  end;

begin
  Reg($FF01); Reg($FF02); Reg($FF03); Reg($FF04); Reg($FF05); Reg($FF06);
  Reg($FF07); Reg($FF08); Reg($FF09); Reg($FF0A); Reg($FF0B); Reg($FF0C);
  Reg($FF0D); Reg($FF0E); Reg($FF16); Reg($FF1A); Reg($FF30); Reg($FF31);
  Reg($FF32); Reg($FF33); Reg($FF34); Reg($FF35); Reg($FF36); Reg($FF37);
  Reg($FF38); Reg($FF39); Reg($FF3A); Reg($FF3B); Reg($FF3C); Reg($FF3D);
  Reg($FF3E); Reg($FF3F); Reg($FF40); Reg($FF41); Reg($FF42); Reg($FF43);
  Reg($FF44); Reg($FF45); Reg($FF46); Reg($FF47); Reg($FF48); Reg($FF49);
  Reg($FF4A); Reg($FF4B); Reg($FF4C); Reg($FF4D); Reg($FF4E); Reg($FF50);
  Reg($FF51); Reg($FF52); Reg($FF53); Reg($FF60); Reg($FF61); Reg($FF62);
  Reg($FF63); Reg($FF64); Reg($FF65); Reg($FF66); Reg($FF67); Reg($FF68);
  Reg($FF69); Reg($FF70); Reg($FF71); Reg($FF72); Reg($FF73); Reg($FF74);
  Reg($FF75); Reg($FF76); Reg($FF77); Reg($FF78); Reg($FF79);
  Reg($FFF0); Reg($FFF1);
end;

{ TFptrFNCommand }

constructor TFptrFNCommand.Create(AOwner: TFptrCommands; ACode: Integer);
begin
  inherited Create(AOwner);
  FCode := ACode;
end;

function TFptrFNCommand.GetCode: Integer;
begin
  Result := FCode;
end;

function TFptrFNCommand.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
begin
  Result := Device.ExecuteFNCommand(FCode, Data);
end;





function BinDate(const D: TPrinterDate): AnsiString;
begin
  Result := AnsiChar(D.Day) + AnsiChar(D.Month) + AnsiChar(D.Year);
end;

function BinTime(const T: TPrinterTime): AnsiString;
begin
  Result := AnsiChar(T.Hour) + AnsiChar(T.Min) + AnsiChar(T.Sec);
end;

function OkOperator(Operator: Integer): AnsiString;
begin
  Result := #$00 + AnsiChar(Operator);
end;

procedure RegisterAllProtocolCommands(Commands: TFptrCommands);

  procedure RegSlip(Code: Integer);
  begin
    if Commands.ItemByCode(Code) = nil then
      TFptrCommand_Slip.Create(Commands, Code);
  end;

  procedure RegFuel(Code: Integer);
  begin
    if Commands.ItemByCode(Code) = nil then
      TFptrCommand_Fuel.Create(Commands, Code);
  end;

  procedure RegGraph(Code: Integer);
  begin
    if Commands.ItemByCode(Code) = nil then
      TFptrCommand_Graphics.Create(Commands, Code);
  end;

begin
  if Commands.ItemByCode($E0) = nil then TFptrCommand_E0h.Create(Commands);
  if Commands.ItemByCode($03) = nil then TFptrCommand_03h.Create(Commands);
  if Commands.ItemByCode($0D) = nil then TFptrCommand_0Dh.Create(Commands);
  if Commands.ItemByCode($0E) = nil then TFptrCommand_0Eh.Create(Commands);
  if Commands.ItemByCode($0F) = nil then TFptrCommand_0Fh.Create(Commands);
  if Commands.ItemByCode($2A) = nil then TFptrCommand_2Ah.Create(Commands);
  if Commands.ItemByCode($57) = nil then TFptrCommand_57h.Create(Commands);
  if Commands.ItemByCode($61) = nil then TFptrCommand_61h.Create(Commands);
  if Commands.ItemByCode($64) = nil then TFptrCommand_64h.Create(Commands);
  if Commands.ItemByCode($65) = nil then TFptrCommand_65h.Create(Commands);
  if Commands.ItemByCode($66) = nil then TFptrCommand_66h.Create(Commands);
  if Commands.ItemByCode($67) = nil then TFptrCommand_67h.Create(Commands);
  if Commands.ItemByCode($68) = nil then TFptrCommand_68h.Create(Commands);
  if Commands.ItemByCode($69) = nil then TFptrCommand_69h.Create(Commands);
  if Commands.ItemByCode($6A) = nil then TFptrCommand_6Ah.Create(Commands);
  if Commands.ItemByCode($6B) = nil then TFptrCommand_6Bh.Create(Commands);
  if Commands.ItemByCode($D0) = nil then TFptrCommand_D0h.Create(Commands);
  if Commands.ItemByCode($D1) = nil then TFptrCommand_D1h.Create(Commands);
  if Commands.ItemByCode($F0) = nil then TFptrCommand_F0h.Create(Commands);
  if Commands.ItemByCode($F1) = nil then TFptrCommand_F1h.Create(Commands);
  if Commands.ItemByCode($F7) = nil then TFptrCommand_F7h.Create(Commands);
  if Commands.ItemByCode($FD) = nil then TFptrCommand_FDh.Create(Commands);

  RegSlip($70); RegSlip($71); RegSlip($72); RegSlip($73); RegSlip($74);
  RegSlip($75); RegSlip($76); RegSlip($77); RegSlip($78); RegSlip($79);
  RegSlip($7A); RegSlip($7B); RegSlip($7C); RegSlip($7D); RegSlip($7E);

  RegFuel($90); RegFuel($91); RegFuel($92); RegFuel($93); RegFuel($94);
  RegFuel($95); RegFuel($96); RegFuel($97); RegFuel($98); RegFuel($99);
  RegFuel($9A); RegFuel($9B); RegFuel($9E); RegFuel($9F);

  RegGraph($C0); RegGraph($C1); RegGraph($C3); RegGraph($C4);

  RegisterFNCommands(Commands);
  RegisterFECommands(Commands);
end;

{ TFptrCommand_E0h }

function TFptrCommand_E0h.GetCode: Integer;
begin
  Result := $E0;
end;

function TFptrCommand_E0h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.OpenSession(Password);
  Result := OkOperator(Operator);
end;

{ TFptrCommand_03h }

function TFptrCommand_03h.GetCode: Integer;
begin
  Result := $03;
end;

function TFptrCommand_03h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  if Device.Mode = FPTR_MODE_DUMP then
    Device.Mode := Device.SavedDumpMode;
  Result := OkOperator(Operator);
end;

{ TFptrCommand_0Dh }

function TFptrCommand_0Dh.GetCode: Integer;
begin
  Result := $0D;
end;

function TFptrCommand_0Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  FM: TFptrFiscalMemoryRec;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  FM := Device.FiscalMemory;
  if not FM.FiscalID.Valid then
  begin
    FM.FiscalID.Valid := True;
    Inc(FM.FiscNumber);
    Dec(FM.LeftFiscNumber);
    Device.FiscalMemory := FM;
  end;
  Result := #$00 + AnsiChar(FM.FiscNumber) +
    AnsiChar(FM.LeftFiscNumber) +
    IntToBin(Device.GetSessionNumber, 2) + BinDate(Device.Date);
end;

{ TFptrCommand_0Eh }

function TFptrCommand_0Eh.GetCode: Integer;
begin
  Result := $0E;
end;

function TFptrCommand_0Eh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
begin
  CheckMinLength(Data, 11);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Device.LongSerial := BinToInt(Data, 5, 7);
  Device.WriteSerial(Password, Device.LongSerial mod 1000000000);
  Result := #$00;
end;

{ TFptrCommand_0Fh }

function TFptrCommand_0Fh.GetCode: Integer;
begin
  Result := $0F;
end;

function TFptrCommand_0Fh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator) + IntToBin(Device.LongSerial, 7) +
    IntToBin(StrToInt64Def(Trim(Device.GetFNKKTRegNumber), 0), 7);
end;

{ TFptrCommand_2Ah }

function TFptrCommand_2Ah.GetCode: Integer;
begin
  Result := $2A;
end;

function TFptrCommand_2Ah.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Device.ClearSlipDocument;
  Result := OkOperator(Operator);
end;

{ TFptrCommand_57h }

function TFptrCommand_57h.GetCode: Integer;
begin
  Result := $57;
end;

function TFptrCommand_57h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  CloseRec: TFptrCloseReceipt;
  CloseRes: TFptrCloseReceiptResult;
  Password: Integer;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  CloseRec.Amount1 := BinToInt(Data, 5, 5);
  CloseRec.Amount2 := 0;
  CloseRec.Amount3 := 0;
  CloseRec.Amount4 := 0;
  CloseRec.Discount := 0;
  CloseRec.Tax1 := 0;
  CloseRec.Tax2 := 0;
  CloseRec.Tax3 := 0;
  CloseRec.Tax4 := 0;
  CloseRec.Text := '';
  CloseRes := Device.CloseReceipt(Password, CloseRec);
  Result := #$00 + AnsiChar(CloseRes.Operator) + IntToBin(CloseRes.Change, 5);
end;

{ TFptrCommand_61h }

function TFptrCommand_61h.GetCode: Integer;
begin
  Result := $61;
end;

function TFptrCommand_61h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  FM: TFptrFiscalMemoryRec;
begin
  FM := Device.FiscalMemory;
  FM.FreeRecords := 3000;
  FM.ErrorCode := 0;
  FM.Flags := 0;
  Device.FiscalMemory := FM;
  Result := #$00;
end;

{ TFptrCommand_64h }

function TFptrCommand_64h.GetCode: Integer;
begin
  Result := $64;
end;

function TFptrCommand_64h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Result := OkOperator(Operator) + BinDate(Device.Date) + BinDate(Device.Date) +
    IntToBin(1, 2) + IntToBin(Device.GetSessionNumber, 2);
end;

{ TFptrCommand_65h }

function TFptrCommand_65h.GetCode: Integer;
begin
  Result := $65;
end;

function TFptrCommand_65h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  FM: TFptrFiscalMemoryRec;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  FM := Device.FiscalMemory;
  if not FM.FiscalID.Valid then
  begin
    FM.FiscalID.Valid := True;
    Inc(FM.FiscNumber);
    Dec(FM.LeftFiscNumber);
    Device.FiscalMemory := FM;
  end;
  Result := #$00 + AnsiChar(FM.FiscNumber) +
    AnsiChar(FM.LeftFiscNumber) +
    IntToBin(Device.GetSessionNumber, 2) + BinDate(Device.Date);
end;

{ TFptrCommand_66h }

function TFptrCommand_66h.GetCode: Integer;
begin
  Result := $66;
end;

function TFptrCommand_66h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Device.ReportInProgress := True;
  Result := OkOperator(Operator) + BinDate(Device.Date) + BinDate(Device.Date) +
    IntToBin(1, 2) + IntToBin(Device.GetSessionNumber, 2);
end;

{ TFptrCommand_67h }

function TFptrCommand_67h.GetCode: Integer;
begin
  Result := $67;
end;

function TFptrCommand_67h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Device.ReportInProgress := True;
  Result := OkOperator(Operator) + BinDate(Device.Date) + BinDate(Device.Date) +
    IntToBin(1, 2) + IntToBin(Device.GetSessionNumber, 2);
end;

{ TFptrCommand_68h }

function TFptrCommand_68h.GetCode: Integer;
begin
  Result := $68;
end;

function TFptrCommand_68h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Device.ReportInProgress := False;
  Result := OkOperator(Operator);
end;

{ TFptrCommand_69h }

function TFptrCommand_69h.GetCode: Integer;
begin
  Result := $69;
end;

function TFptrCommand_69h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Result := OkOperator(Operator) + IntToBin(Password, 4) +
    IntToBin(StrToInt64Def(Trim(Device.GetFNKKTRegNumber), 0), 5) +
    IntToBin(StrToInt64Def(Trim(Device.GetFNINN), 0), 6) +
    IntToBin(Device.GetSessionNumber, 2) + BinDate(Device.Date);
end;

{ TFptrCommand_6Ah }

function TFptrCommand_6Ah.GetCode: Integer;
begin
  Result := $6A;
end;

function TFptrCommand_6Ah.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Result := OkOperator(Operator) + IntToBin(Device.FiscalMemory.FreeRecords, 2);
end;

{ TFptrCommand_6Bh }

function TFptrCommand_6Bh.GetCode: Integer;
begin
  Result := $6B;
end;

function TFptrCommand_6Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  ErrCode: Byte;
begin
  if Length(Data) >= 1 then
    ErrCode := Ord(Data[1])
  else
    ErrCode := 0;
  Result := AnsiString(GetErrorText(ErrCode));
end;

{ TFptrCommand_Slip }

constructor TFptrCommand_Slip.Create(AOwner: TFptrCommands; ACode: Integer);
begin
  inherited Create(AOwner);
  FCode := ACode;
end;

function TFptrCommand_Slip.GetCode: Integer;
begin
  Result := FCode;
end;

function TFptrCommand_Slip.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  if Length(Data) >= 4 then
  begin
    Password := BinToInt(Data, 1, 4);
    Operator := Device.FindOperator(Password, 0);
    Result := OkOperator(Operator);
  end else
    Result := #$00;
end;

{ TFptrCommand_Fuel }

constructor TFptrCommand_Fuel.Create(AOwner: TFptrCommands; ACode: Integer);
begin
  inherited Create(AOwner);
  FCode := ACode;
end;

function TFptrCommand_Fuel.GetCode: Integer;
begin
  Result := FCode;
end;

function TFptrCommand_Fuel.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  if Length(Data) >= 4 then
  begin
    Password := BinToInt(Data, 1, 4);
    Operator := Device.FindOperator(Password, 0);
    Result := OkOperator(Operator);
  end else
    Result := #$00;
  if FCode in [$9E, $9F] then
    Result := Result + IntToBin(0, 4);
end;

{ TFptrCommand_Graphics }

constructor TFptrCommand_Graphics.Create(AOwner: TFptrCommands; ACode: Integer);
begin
  inherited Create(AOwner);
  FCode := ACode;
end;

function TFptrCommand_Graphics.GetCode: Integer;
begin
  Result := FCode;
end;

function TFptrCommand_Graphics.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  if Length(Data) >= 4 then
  begin
    Password := BinToInt(Data, 1, 4);
    Operator := Device.FindOperator(Password, 0);
    Result := OkOperator(Operator);
  end else
    Result := #$00;
end;

{ TFptrCommand_D0h }

function TFptrCommand_D0h.GetCode: Integer;
begin
  Result := $D0;
end;

function TFptrCommand_D0h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator) + BinDate(Device.Date) + BinTime(Device.Time) +
    IntToBin(Device.GetSessionNumber, 2) + IntToBin(Device.DocNumber, 4) +
    IntToBin(0, 2) + IntToBin(0, 2) + IntToBin(0, 2) + IntToBin(0, 2) +
    #0#0#0#0#0 + IntToBin(Device.CashAmount, 6) +
    StringOfChar(#0, 8) + #0;
end;

{ TFptrCommand_D1h }

function TFptrCommand_D1h.GetCode: Integer;
begin
  Result := $D1;
end;

function TFptrCommand_D1h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator) + StringOfChar(#0, 8) + #0;
end;

{ TFptrCommand_F0h }

function TFptrCommand_F0h.GetCode: Integer;
begin
  Result := $F0;
end;

function TFptrCommand_F0h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator);
end;

{ TFptrCommand_F1h }

function TFptrCommand_F1h.GetCode: Integer;
begin
  Result := $F1;
end;

function TFptrCommand_F1h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator);
end;

{ TFptrCommand_F7h }

function TFptrCommand_F7h.GetCode: Integer;
begin
  Result := $F7;
end;

function TFptrCommand_F7h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator) + #0;
end;

{ TFptrCommand_FDh }

function TFptrCommand_FDh.GetCode: Integer;
begin
  Result := $FD;
end;

function TFptrCommand_FDh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := OkOperator(Operator) + #0;
end;



{ TEmulProtocolServer }

constructor TEmulProtocolServer.Create(ADevice: TPrinterEmulator; APort: TEmulSerialPort);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDevice := ADevice;
  FPort := APort;
  FActive := False;
  FHasResponse := False;
  Priority := tpHigher;
end;

procedure TEmulProtocolServer.StopServer;
begin
  FActive := False;
  Terminate;
  WaitFor;
end;

function TEmulProtocolServer.GetCRC(const Data: AnsiString): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Data) do
    Result := Result xor Ord(Data[i]);
end;

function TEmulProtocolServer.EncodeFrame(const Data: AnsiString): AnsiString;
var
  Payload: AnsiString;
begin
  Payload := AnsiChar(Length(Data)) + Data;
  Result := STX + Payload + AnsiChar(GetCRC(Payload));
end;

function TEmulProtocolServer.ReadExact(Count: Integer): AnsiString;
begin
  Result := FPort.ReadExact(Count, FPort.Timeout);
end;

procedure TEmulProtocolServer.WriteByte(B: AnsiChar);
begin
  FPort.WriteData(B);
end;

procedure TEmulProtocolServer.ProcessCommand(const Command: AnsiString);
begin
  FResponse := FDevice.Execute(Command, 3000);
  FHasResponse := NeedsResponse(Command, FResponse);
end;

function TEmulProtocolServer.NeedsResponse(const Command,
  Response: AnsiString): Boolean;
begin
  Result := Length(Response) > 0;
  if Result and (Length(Command) >= 2) and (Ord(Command[1]) = $FE) and
    (Ord(Command[2]) = $FB) then
    Result := False;
end;

procedure TEmulProtocolServer.SendResponse;
var
  C: AnsiChar;
begin
  if not FHasResponse then
    Exit;
  FPort.WriteData(EncodeFrame(FResponse));
  if FPort.ReadCharTimeout(C, 5000) and (C = ACK) then
    FHasResponse := False;
end;

procedure TEmulProtocolServer.Execute;
var
  C: AnsiChar;
  Command: AnsiString;
  DataLen: Integer;
  Payload: AnsiString;
begin
  FActive := True;
  while not Terminated do
  begin
    if not FPort.ReadCharTimeout(C, 500) then
      Continue;

    if C = ENQ then
    begin
      if FHasResponse then
      begin
        WriteByte(ACK);
        SendResponse;
      end
      else
        WriteByte(NAK);
      Continue;
    end;

    if C <> STX then
      Continue;

    if not FPort.ReadChar(C) then
      Continue;
    DataLen := Ord(C);
    Payload := ReadExact(DataLen + 1);
    Command := Copy(Payload, 1, DataLen);
    if GetCRC(AnsiChar(DataLen) + Command) <> Ord(Payload[DataLen + 1]) then
    begin
      WriteByte(NAK);
      Continue;
    end;
    WriteByte(ACK);
    ProcessCommand(Command);
    if FHasResponse then
      SendResponse;
  end;
  FActive := False;
end;



{ TFREmulator }

constructor TFREmulator.Create;
begin
  inherited Create;
  FDevice := TPrinterEmulator.Create;
  FTables := TEmulTables.Create;
  FPort := TEmulSerialPort.Create;
  FPortName := DEF_EMUL_PORT;
  FBaudRate := DEF_BAUD_RATE;
end;

destructor TFREmulator.Destroy;
begin
  Stop;
  FPort.Free;
  FTables.Free;
  FDevice.Free;
  inherited Destroy;
end;

procedure TFREmulator.LoadTables(const FileName: string);
begin
  FTables.LoadFromFile(FileName);
  FDevice.ApplyTables(FTables);
end;

procedure TFREmulator.Start(const APortName: string; ABaudRate: Integer);
begin
  Stop;
  FPortName := APortName;
  FBaudRate := ABaudRate;
  FPort.Open(APortName, ABaudRate);
  FServer := TEmulProtocolServer.Create(FDevice, FPort);
  FServer.Resume;
end;

procedure TFREmulator.Stop;
begin
  if FServer <> nil then
  begin
    FServer.StopServer;
    FServer.Free;
    FServer := nil;
  end;
  FPort.Close;
end;

function TFREmulator.Running: Boolean;
begin
  Result := (FServer <> nil) and FServer.Active;
end;


end.
