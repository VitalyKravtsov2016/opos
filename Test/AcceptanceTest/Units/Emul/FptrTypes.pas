unit FptrTypes;

interface

uses
  Windows, SysUtils;

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

implementation

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

end.


