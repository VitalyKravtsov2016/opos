unit PrinterTypes;

interface

uses
  // VCL
  Windows, SysUtils,
  // Opos
  OposException, OposFptr,
  // 3'd
  TntSysUtils, gnugettext;

const
  SStatusWaitTimeout = 'Printer status wait timeout';

const
  ///////////////////////////////////////////////////////////////////////////
  // KTN constants

  // �� ��� ��������������� �������������� ������ 00h 00h
  KTN_UNKNOWN = 0;
  // EAN-8, UPC-E (E8) ������������� ������ �� ������� EAN-8 45h 08h
  KTN_EAN8 = $4508;
  // EAN-13, UPC-A (E13) ������������� ������ �� ������� EAN-13 45h 0Dh
  KTN_EAN13 = $450D;
  // ITF-14 (I14) ������������� ������ �� ������� ITF-14 49h 0Eh
  KTN_ITF14 = $490E;
  // GS1 Data Matrix (DM) ������������� ������ �� ������� GS1 Data Matrix ���
  // Data Matrix ���������� ������� 44h 4Dh
  KTN_DM = $444D;
  // ������� �� ������������ ���� (RF)
  // ������������� ������ �� ������� �������������
  // ��������� ������� �� ������������ ���� 52h 46h
  KTN_RF = $5246;
  // ����� 2.0 (�20) ������������� ������ �� ������� 2 ������ �������������
  // ����������� ��������� � ������� PDF417 C5h 14h
  KTN_EGAIS2 = $C514;
  // ����� 3.0 (�30) ������������� ������ �� ������� 3 ������ �������������
  // ����������� ��������� � ������� Data Matrix C5h 1Eh
  KTN_EGAIS3 = $C51E;
  // ��� ������ � ������� �� ��� ������������� ������ �� ������� �������������� ��
  // ��� ��� ����� ������� ��������� ������� (�������������� �������). 45h 41h
  KTN_FUEL = $4541;

  /////////////////////////////////////////////////////////////////////////////
  //

  FPTR_ERROR_BASE = 300;

  /////////////////////////////////////////////////////////////////////////////
  // Error code constants

  ERROR_COMMAND_NOT_SUPPORTED = $37;

  /////////////////////////////////////////////////////////////////////////////
  // Device model ID constants

  MODEL_ID_AUTOSELECT       = -1;
  MODEL_ID_DEFAULT          = 0;
  MODEL_ID_SHTRIH_FRF       = 1;
  MODEL_ID_SHTRIH_FRK       = 2;
  MODEL_ID_SHTRIH_MINI_FRK  = 3;
  MODEL_ID_SHTRIH_M_FRK     = 4;
  MODEL_ID_SHTRIH_950K      = 5;
  MODEL_ID_SHTRIH_950PTK    = 6;
  MODEL_ID_SHTRIH_950PTK2   = 11;
  MODEL_ID_RETAIL_01K       = 22;
  MODEL_ID_WEB_CASSA        = 26;

  MODEL_ID_PAYONLINE        = 255;

(*
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
*)





  PrinterDiscountText   = '������';
  PrinterChargeText     = '��������';
  PrinterItemVoidText   = '������';

  /////////////////////////////////////////////////////////////////////////////
  // Command codes

  SMFP_COMMAND_START_DUMP               = $01;
  SMFP_COMMAND_GETDUMPBLOCK             = $02;
  SMFP_COMMAND_STOP_DUMP                = $03;
  SMFP_COMMAND_LONG_FISCALIZATION       = $0D;
  SMFP_COMMAND_SET_LONG_SERIAL          = $0E;
  SMFP_COMMAND_GET_LONG_SERIAL          = $0F;
  SMFP_COMMAND_GET_SHORT_STATUS         = $10;
  SMFP_COMMAND_GET_STATUS               = $11;
  SMFP_COMMAND_PRINT_BOLD_LINE          = $12;
  SMFP_COMMAND_BEEP                     = $13;
  SMFP_COMMAND_SET_PORT_PARAMS          = $14;
  SMFP_COMMAND_GET_PORT_PARAMS          = $15;
  SMFP_COMMAND_RESETFM                  = $16;
  SMFP_COMMAND_PRINT_LINE               = $17;
  SMFP_COMMAND_PRINT_DOC_HEADER         = $18;
  SMFP_COMMAND_START_TEST               = $19;
  SMFP_COMMAND_READ_CASH_TOTALIZER      = $1A;
  SMFP_COMMAND_READ_OPER_TOTALIZER      = $1B;
  SMFP_COMMAND_WRITE_LICENSE            = $1C;
  SMFP_COMMAND_READ_LICENSE             = $1D;
  SMFP_COMMAND_WRITE_TABLE              = $1E;
  SMFP_COMMAND_READ_TABLE               = $1F;
  SMFP_COMMAND_WRITE_DECIMAL            = $20;
  SMFP_COMMAND_WRITE_TIME               = $21;
  SMFP_COMMAND_WRITE_DATE               = $22;
  SMFP_COMMAND_CONFIRM_DATE             = $23;
  SMFP_COMMAND_INIT_TABLES              = $24;
  SMFP_COMMAND_CUT_PAPER                = $25;
  SMFP_COMMAND_READ_FONT                = $26;
  SMFP_COMMAND_CLEAR_FM                 = $27;
  SMFP_COMMAND_OPEN_DRAWER              = $28;
  SMFP_COMMAND_FEED_PAPER               = $29;
  SMFP_COMMAND_SLIP_EJECT               = $2A;
  SMFP_COMMAND_STOP_TEST                = $2B;
  SMFP_COMMAND_PRINT_OPREG              = $2C;
  SMFP_COMMAND_READ_TABLE_INFO          = $2D;
  SMFP_COMMAND_READ_FIELD_INFO          = $2E;
  SMFP_COMMAND_PRINT_STRING_FONT        = $2F;
  SMFP_COMMAND_PRINT_X_REPORT           = $40;
  SMFP_COMMAND_PRINT_Z_REPORT           = $41;
  SMFP_COMMAND_PRINT_DEPARTMENT_REPORT  = $42;
  SMFP_COMMAND_PRINT_TAX_REPORT         = $43;
  SMFP_COMMAND_CASH_IN                  = $50;
  SMFP_COMMAND_CASH_OUT                 = $51;
  SMFP_COMMAND_PRINT_HEADER             = $52;
  SMFP_COMMAND_PRINT_DOCEND             = $53;
  SMFP_COMMAND_PRINT_TRAILER            = $54;
  SMFP_COMMAND_WRITE_SERIAL             = $60;
  SMFP_COMMAND_INIT_FM                  = $61;
  SMFP_COMMAND_READ_FM_TOTAL            = $62;
  SMFP_COMMAND_READ_LAST_FM_DATE        = $63;
  SMFP_COMMAND_READ_FM_RANGE            = $64;
  SMFP_COMMAND_FISCALIZE                = $65;
  SMFP_COMMAND_PRINT_DATES_REPORT       = $66;
  SMFP_COMMAND_PRINT_DAYS_REPORT        = $67;
  SMFP_COMMAND_STOP_REPORT              = $68;
  SMFP_COMMAND_READ_FISCALIZATION       = $69;
  SMFP_COMMAND_OPEN_FISCAL_SLIP         = $70;
  SMFP_COMMAND_OPEN_STD_SLIP            = $71;
  SMFP_COMMAND_SLIP_OPERATION           = $72;
  SMFP_COMMAND_SLIP_STD_OPERATION       = $73;
  SMFP_COMMAND_SLIP_DISCOUNT            = $74;
  SMFP_COMMAND_SLIP_STD_DISCOUNT        = $75;
  SMFP_COMMAND_SLIP_CLOSE               = $76;
  SMFP_COMMAND_SLIP_STD_CLOSE           = $77;
  SMFP_COMMAND_SET_SLIP_CONFIG          = $78;
  SMFP_COMMAND_SET_STD_SLIP_CONFIG      = $79;
  SMFP_COMMAND_SET_SLIP_LINE            = $7A;
  SMFP_COMMAND_CLEAR_SLIP_LINE          = $7B;
  SMFP_COMMAND_CLEAR_SLIP_LINES         = $7C;
  SMFP_COMMAND_PRINT_SLIP               = $7D;
  SMFP_COMMAND_SLIP_CONFIG              = $7E;
  SMFP_COMMAND_SALE                     = $80;
  SMFP_COMMAND_BUY                      = $81;
  SMFP_COMMAND_RETSALE                  = $82;
  SMFP_COMMAND_RETBUY                   = $83;
  SMFP_COMMAND_STORNO                   = $84;
  SMFP_COMMAND_RECCLOSE                 = $85;
  SMFP_COMMAND_DISCOUNT                 = $86;
  SMFP_COMMAND_CHARGE                   = $87;
  SMFP_COMMAND_CANCEL_RECEIPT           = $88;
  SMFP_COMMAND_READ_SUBTOTAL            = $89;
  SMFP_COMMAND_STORNO_DISCOUNT          = $8A;
  SMFP_COMMAND_STORNO_CHARGE            = $8B;
  SMFP_COMMAND_PRINT_COPY               = $8C;
  SMFP_COMMAND_OPEN_RECEIPT             = $8D;
  SMFP_COMMAND_EJ_PRINT_DEP_DATES_REPORT  = $A0;
  SMFP_COMMAND_EJ_PRINT_DEP_DAYS_REPORT   = $A1;
  SMFP_COMMAND_EJ_PRINT_DATES_REPORT      = $A2;
  SMFP_COMMAND_EJ_PRINT_DAYS_REPORT       = $A3;
  SMFP_COMMAND_EJ_PRINT_DAY_RESULT        = $A4;
  SMFP_COMMAND_EJ_PRINT_DOCUMENT          = $A5;
  SMFP_COMMAND_EJ_PRINT_DAY_DOCUMENTS     = $A6;
  SMFP_COMMAND_EJ_STOP_REPORT             = $A7;
  SMFP_COMMAND_EJ_PRINT_ACTIVATION        = $A8;
  SMFP_COMMAND_EJ_ACTIVATION              = $A9;
  SMFP_COMMAND_EJ_CLOSE_ARCHIVE           = $AA;
  SMFP_COMMAND_EJ_READ_SERIAL             = $AB;
  SMFP_COMMAND_EJ_STOP                    = $AC;
  SMFP_COMMAND_EJ_READ_STATUS_CODE1       = $AD;
  SMFP_COMMAND_EJ_READ_STATUS_CODE2       = $AE;
  SMFP_COMMAND_EJ_TEST_ARCHIVE            = $AF;
  SMFP_COMMAND_CONTINUE_PRINT             = $B0;
  SMFP_COMMAND_EJ_READ_VERSION            = $B1;
  SMFP_COMMAND_EJ_INIT_ARCHIVE            = $B2;
  SMFP_COMMAND_EJ_READ_LINE               = $B3;
  SMFP_COMMAND_EJ_READ_REPORT             = $B4;
  SMFP_COMMAND_EJ_READ_DOCUMENT           = $B5;
  SMFP_COMMAND_EJ_READ_DEP_DATES_REPORT   = $B6;
  SMFP_COMMAND_EJ_READ_DEP_DAYS_REPORT    = $B7;
  SMFP_COMMAND_EJ_READ_DATES_REPORT       = $B8;
  SMFP_COMMAND_EJ_READ_DAYS_REPORT        = $B9;
  SMFP_COMMAND_EJ_READ_DAY_RESULT         = $BA;
  SMFP_COMMAND_EJ_READ_ACTIVATION         = $BB;
  SMFP_COMMAND_EJ_SET_ERROR               = $BC;
  SMFP_COMMAND_LOAD_GRAPHICS              = $C0;
  SMFP_COMMAND_PRINT_GRAPHICS             = $C1;
  SMFP_COMMAND_PRINT_BARCODE              = $C2;
  SMFP_COMMAND_PRINT_GRAPHICS_EX          = $C3;
  SMFP_COMMAND_LOAD_GRAPHICS_EX           = $C4;
  SMFP_COMMAND_PRINT_GRAPHICS_LINE        = $C5;
  SMFP_COMMAND_READ_BUFFER_LINE_COUNT     = $C8;
  SMFP_COMMAND_READ_BUFFER_LINE           = $C9;
  SMFP_COMMAND_CLEAR_BUFFER               = $CA;

  /////////////////////////////////////////////////////////////////////////////
  // Device code for Start Dump command

  SMFP_DEVICE_CODE_FM1    = 1; // Fiscal Memory 1
  SMFP_DEVICE_CODE_FM2    = 2; // Fiscal Memory 2
  SMFP_DEVICE_CODE_CLOCK  = 3; // Clock
  SMFP_DEVICE_CODE_NVRAM  = 4; // Nonvolatile memory
  SMFP_DEVICE_CODE_FMPROC = 5; // Fiscal Memory processor
  SMFP_DEVICE_CODE_ROM    = 6; // Fiscal Printer ROM
  SMFP_DEVICE_CODE_RAM    = 7; // Fiscal Printer RAM

  /////////////////////////////////////////////////////////////////////////////
  // Font numbers

  FONT_NUMBER_DEFAULT = 1;

  /////////////////////////////////////////////////////////////////////////////
  // ReceiptType constants

  RecTypeSale           = 0; // Sale
  RecTypeBuy            = 1; // Buy
  RecTypeRetSale        = 2; // Sale refund
  RecTypeRetBuy         = 3; // Buy refund

  CRLF = #13#10;
  BoolToInt: array [Boolean] of Integer = (0, 1);

  // printer stations
  PRINTER_STATION_JRN       = 1;    // Bit 0 - Journal
  PRINTER_STATION_REC       = 2;    // Bit 1 - Receipt
  PRINTER_STATION_SLP       = 4;    // Bit 2 - Slip
  PRINTER_STATION_RECJRN    = 3;
  PRINTER_FLAG_FOOTER       = $80;

  // Report type
  PRINTER_REPORT_TYPE_SHORT     = 0;    // Short
  PRINTER_REPORT_TYPE_FULL      = 1;    // Full

  // Field types
  PRINTER_FIELD_TYPE_INT        = 0;    // Integer
  PRINTER_FIELD_TYPE_STR        = 1;    // String

  // Decimal point position
  PRINTER_POINT_POSITION_0      = 0;    // 0 digits
  PRINTER_POINT_POSITION_2      = 1;    // 2 digits

  // Tables
  PRINTER_TABLE_SETUP           = 1;    // ECR type and mode
  PRINTER_TABLE_CASHIER         = 2;    // Cashier and admin's passwords
  PRINTER_TABLE_TIME            = 3;    // Time conversion table
  PRINTER_TABLE_TEXT            = 4;    // Text in receipt
  PRINTER_TABLE_PAYTYPE         = 5;    // Payment type names
  PRINTER_TABLE_TAX             = 6;    // Taxes
  PRINTER_TABLE_DEPARTMENT      = 7;    // Department names
  PRINTER_TABLE_FONTS           = 8;    // Font settings
  PRINTER_TABLE_RECFORMAT       = 9;    // Receipt format table

  // Cut type
  PRINTER_CUTTYPE_FULL          = 0;    // Full
  PRINTER_CUTTYPE_PARTIAL       = 1;    // Partial

  // Mode
  ECRMODE_DUMPMODE		  = $01; // Dump mode
  ECRMODE_24NOTOVER		  = $02; // Opened day, 24 hours not left
  ECRMODE_24OVER		    = $03; // Opened day, 24 hours is over
  ECRMODE_CLOSED		    = $04; // Closed day
  ECRMODE_LOCKED		    = $05; // ECR is bloced because of incorrect tax offecer password
  ECRMODE_WAITDATE	  	= $06; // Waiting for date confirm
  ECRMODE_POINTPOS		  = $07; // Change decimal point position permission
  ECRMODE_RECSELL		    = $08; // Opened document: sale
  ECRMODE_RECBUY		    = $18; // Opened document: buy
  ECRMODE_RECRETSELL		= $28; // Opened document: sale refund
  ECRMODE_RECRETBUY		  = $38; // Opened document: buy refund
  ECRMODE_TECH			    = $09; // Technological reset permission
  ECRMODE_TEST			    = $0A; // Test run
  ECRMODE_FULLREPORT		= $0B; // Full fiscal report printing
  ECRMODE_EKLZREPORT		= $0C; // EJ report printing
  ECRMODE_SLPSELL	     	= $0D; // Opened fiscal slip: sale
  ECRMODE_SLPBUY		    = $1D; // Opened fiscal slip: buy
  ECRMODE_SLPRETSELL		= $2D; // Opened fiscal slip: sale refund
  ECRMODE_SLPRETBUY		  = $3D; // Opened fiscal slip: buy refund
  ECRMODE_SLPWAITLOAD		= $0E; // Waiting for slip load
  ECRMODE_SLPLOAD		    = $1E; // Slip loading and positioning
  ECRMODE_SLPPOSITION		= $2E; // Slip positioning
  ECRMODE_SLPPRINTING		= $3E; // Slip printing
  ECRMODE_SLPPRINTED		= $4E; // Slip is printed
  ECRMODE_SLPEJECT	  	= $5E; // Eject slip
  ECRMODE_SLPWAITEJECT  = $6E; // Waiting for slip eject
  ECRMODE_SLPREADY		  = $0F; // Fiscal slip is ready

  // MODE constants
  MODE_DUMPMODE			= $01; // Dump mode
  MODE_24NOTOVER		= $02; // Opened day, 24 hours not left
  MODE_24OVER			  = $03; // Opened day, 24 hours is over
  MODE_CLOSED			  = $04; // Closed day
  MODE_LOCKED			  = $05; // ECR is bloced because of incorrect tax offecer password
  MODE_WAITDATE			= $06; // Waiting for date confirm
  MODE_POINTPOS			= $07; // Change decimal point position permission
  MODE_REC		     	= $08; // Opened document
  MODE_TECH		     	= $09; // Technological reset permission
  MODE_TEST			    = $0A; // Test run
  MODE_FULLREPORT		= $0B; // Full fiscal report printing
  MODE_EKLZREPORT		= $0C; // EJ report printing
  MODE_SLP		     	= $0D; // Opened fiscal slip
  MODE_SLPPRINT			= $0E; // Slip printing
  MODE_SLPREADY			= $0F; // Fiscal slip is ready

  // ECR submode AdvancedModeFR
  AMODE_IDLE		    = 0;	// 0.	Paper present
  AMODE_PASSIVE	    = 1;	// 1.	Passive paper absense
  AMODE_ACTIVE		  = 2;	// 2.	Active paper absense
  AMODE_AFTER		    = 3;	// 3.	After active paper absense
  AMODE_REPORT		  = 4;	// 4.	Report printing stage
  AMODE_PRINT		    = 5;	// 5.	Operation printing stage

  // Models
  PRINTER_MODEL_DEFAULT                 = -1;   // Default model
  PRINTER_MODEL_SHTRIH_FRF              = 0;    // SHTRIH-FR-F (ver. 03 & 04)
  PRINTER_MODEL_SHTRIH_FRFKAZ           = 1;    // SHTRIH-FR-F (Kazakhstan)
  PRINTER_MODEL_ELVES_MINI_FRF          = 2;    // ELVES-MINI-FR-F
  PRINTER_MODEL_FELIX                   = 3;    // FELIX-R F
  PRINTER_MODEL_SHTRIH_FRK              = 4;    // SHTRIH-FR-K
  PRINTER_MODEL_SHTRIH_950K             = 5;    // SHTRIH-950K
  PRINTER_MODEL_ELVES_FRK               = 6;    // ELVES-FR-K
  PRINTER_MODEL_SHTRIH_MINI_FRK         = 7;    // SHTRIH-MINI-FR-K
  PRINTER_MODEL_SHTRIH_FRF_BEL          = 8;    // SHTRIH-FR-F (Belorussia)
  PRINTER_MODEL_COMBO_FRK               = 9;    // SHTRIH-COMBO-FR-K
  PRINTER_MODEL_SHTRIH_POSF             = 10;   // Fiscal module Shtrih-POS-F
  PRINTER_MODEL_SHTRIH_950K_02          = 11;   // SHTRIH-950K
  PRINTER_MODEL_COMBO_FRK_02            = 12;   // SHTRIH-COMBO-FR-K (ver. 02)
  PRINTER_MODEL_SHTRIH_MINI_FRK_02      = 14;   // SHTRIH-MINI-FR-K (ver 02, 57 mm)
  PRINTER_MODEL_SHTRIH_KIOSK_FRK        = 15;   // SHTRIH-KIOSK-FR-K
  PRINTER_MODEL_SHTRIH_M_FRK            = 250;  // SHTRIH-M-FR-K
  PRINTER_MODEL_SHTRIH_LIGHT_FRK        = 251;  // SHTRIH-LIGHT-FR-K

  // Cash registers
  REG_REC_SELL1			        = 0;   // Accumulation of sales in 1-st department in receipt
  REG_REC_BUY1			        = 1;   // Accumulation of buys in 1-st department in receipt
  REG_REC_RETSELL1		      = 2;   // Accumulation of sale refunds in 1-st department in receipt
  REG_REC_RETBUY1			      = 3;   // Accumulation of buy refunds in 1-st department in receipt
  REG_REC_DISC_SELL		      = 64;  // Accumulation of discounts from sales in receipt
  REG_REC_DISC_BUY		      = 65;  // Accumulation of discounts from buys in receipt
  REG_REC_DISC_RETSELL	    = 66;  // Accumulation of discounts from sale refunds in receipt
  REG_REC_DISC_RETBUY		    = 67;  // Accumulation of discounts from buy refunds in receipt
  REG_REC_CHRG_SELL		      = 68;  // Accumulation of charges from sales in receipt
  REG_REC_CHRG_BUY		      = 69;  // Accumulation of charges from buys in receipt
  REG_REC_CHRG_RETSELL	    = 70;  // Accumulation of charges from sale refunds in receipt
  REG_REC_CHRG_RETBUY		    = 71;  // Accumulation of charges from buy refunds in receipt
  REG_DAY_DISC_SELL		      = 185; // Accumulation of discounts from sales in day
  REG_DAY_DISC_BUY		      = 186; // Accumulation of discounts from buys in day
  REG_DAY_DISC_RETSELL	    = 187; // Accumulation of discounts froum sale refunds in day
  REG_DAY_DISC_RETBUY		    = 188; // Accumulation of discounts from buy refunds in day
  REG_DAY_CHRG_SELL		      = 189; // Accumulation of charges from sales in day
  REG_DAY_CHRG_BUY		      = 190; // Accumulation of charges from buys in day
  REG_DAY_CHRG_RETSELL	    = 191; // Accumulation of charges from sale refunds in day
  REG_DAY_CHRG_RETBUY		    = 192; // Accumulation of charges from buy refunds in day
  REG_DAY_SELL			        = 245; // Sales total in day from EJ
  REG_DAY_BUY		        		= 246; // Buys total in day from EJ
  REG_DAY_RETSELL			      = 247; // Sale refunds total in day from EJ
  REG_DAY_RETBUY			      = 248; // Buy refunds totall in day from EJ
  EJ_NO_MORE_DATA           = $A9; // EJ: No requested data available

const
  // Models parameters file name
  ModelsFileName = 'Models.xml';

  // Fiscal printer device description
  FPTR_DEVICE_DESCRIPTION = 'SHTRIH-M Fiscal Printer';

type
  TProgressEvent = procedure (Value: Integer) of object;

  { TCashRegisterRec }

  TCashRegisterRec = record
    Operator: Byte;
    Value: Int64;
  end;

  { TOperRegisterRec }

  TOperRegisterRec = record
    Operator: Byte;
    Value: Word;
  end;

  TBaudrate =(br110, br300, br600, br1200, br2400, br4800, br9600, br14400,
    br19200, br38400, br56000, br57600, br115200, br128000, br256000);
  TBaudrates = set of TBaudrate;


  { TDumpBlock }

  TDumpBlock = packed record
    DeviceCode: Byte;
    BlockNumber: Word;
    BlockData: AnsiString;
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

  { TPrinterDateTime }

  TPrinterDateTime = packed record
    Day: Byte;
    Month: Byte;
    Year: Byte;
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
    FiscNumber: Byte;       // Fiscalization/Refiscalization number(1 byte) 1�16
    LeftNumber: Byte;       // Quantity of refiscalizations left in FM (1 byte) 0�15
    DayNumber: Word;      // Last daily totals record number in FM (2 bytes) 0000�2100
    Date: TPrinterDate;     // Fiscalization/Refiscalization date (3 bytes) DD-MM-YY
  end;

  { TShortPrinterStatus }

  TShortPrinterStatus = packed record
    OperatorNumber: Byte;
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
    OperatorNumber: Byte;
    FirmwareVersionHi: Char;
    FirmwareVersionLo: Char;
    FirmwareBuild: Word;
    FirmwareDate: TPrinterDate;
    LogicalNumber: Byte;
    DocumentNumber: Word;
    Flags: Word;
    Mode: Byte;
    AdvancedMode: Byte;
    PortNumber: Byte;
    FMVersionHi: Char;
    FMVersionLo: Char;
    FMBuild: Word;
    FMFirmwareDate: TPrinterDate;
    Date: TPrinterDate;
    Time: TPrinterTime;
    FMFlags: Byte;
    SerialNumber: WideString;
    DayNumber: Word;
    RemainingFiscalMemory: Word;
    RegistrationNumber: Byte;
    FreeRegistration: Byte;
    FiscalID: WideString;
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
    Value: Word;
  end;

  { TFMFlags }

  TFMFlags = packed record
    FM1Present: Boolean;          // 0 - FM 1 (0 - not present, 1 - present)
    FM2Present: Boolean;          // 1 - FM 2 (0 - not present, 1 - present)
    LicenseEntered: Boolean;      // 2 - License (0 - not assigned, 1 - assigned)
    Overflow: Boolean;            // 3 - FM overflow (0 - no, 1 - yes)
    LowBattery: Boolean;          // 4 - FM battery (0 - >80%, 1 - <80%)
    LastRecordCorrupted: Boolean; // 5 - Last FM record (0 - corrupted, 1 - correct)
    DayOpened: Boolean;           // 6 - Day in FM (0 - closed, 1 - opened)
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

  { TFontInfo }

  TFontInfo = packed record
    PrintWidth: Word;   // Paper width in dots
    CharWidth: Byte;    // Character width in dots
    CharHeight: Byte; 	// Character heigth in dots
    FontCount: Byte; 	  // Font count
  end;
  TFontInfoList = array of TFontInfo;

  { TTaxInfo }

  TTaxInfo = record
    Name: WideString;
    Rate: Integer;
  end;
  TTaxInfoList = array of TTaxInfo;

  { TPrinterTableRec }

  TPrinterTableRec = packed record
    Number: Integer;            // Table number
    Name: WideString;           // Table name (40 byts)
    RowCount: Integer;          // Row count (2 bytes)
    FieldCount: Integer;        // Field count (1 byte)
  end;

  { TPrinterFieldRec }

  TPrinterFieldRec = packed record
    Table: Integer;                     // Table number
    Row: Integer;                       // Row number
    Field: Integer;                     // Field number
    Size: Integer;                      // Field size
    FieldType: Integer;                 // Field type
    MinValue: Integer;                  // Min value
    MaxValue: Integer;                  // Max value
    Name: WideString;                   // Name
  end;

  { TFMTotals }

  TFMTotals = packed record
    OperatorNumber: Byte; // Operator number (1 byte) 29, 30
    SaleTotal: Int64;     // Day sales totals sum (8 bytes)
    BuyTotal: Int64;      // Day buys totals sum (6 bytes) in case of FM 2 absense: FFh FFh FFh FFh FFh FFh
    RetSale: Int64;       // Day sale refunds totals sum (6 bytes) in case of FM 2 absense: FFh FFh FFh FFh FFh FFh
    RetBuy: Int64;        // Day buy refunds totals sum (6 bytes) in case of FM 2 absense: FFh FFh FFh FFh FFh FFh
  end;

  { TFSTotalsByPayType }

  TFSTotalsByPayType = packed record
    Totals: array [0..15] of Int64; // Totals amount (8 bytes) by payment types
  end;

  { TFMRecordDate }

  TFMRecordDate = packed record
    OperatorNumber: Byte;       // Operator number (1 byte) 29, 30
    RecordType: Byte;           // Last record type (1 byte) '0' - fiscalilzation (fefiscalization), '1' - Day total
    Date: TPrinterDate;         // Date (3 bytes) DD-MM-YY
  end;

  { TDayRange }

  TDayRange = packed record
    Date1: TPrinterDate;        // First day date (3 bytes) DD-MM-YY
    Date2: TPrinterDate;        // Last day date (3 bytes) DD-MM-YY
    Number1: Word;              // First day number (2 bytes) 0000�2100
    Number2: Word;              // Last day number (2 bytes) 0000�2100
  end;

  { TFiscalizationResult }

  TFiscalizationResult = packed record
    FiscNumber: Byte;           // Fiscalization (refiscalization) number  (1 byte) 1�16
    LeftFiscCount: Byte;        // Refiscalizations left count (1 byte) 0�15
    LastDayNumber: Word;      // Last closed day number(2 bytes) 0000�2100
    Date: TPrinterDate;         // Fiscalilzation (refiscalization) date (3 bytes) DD-MM-YY
  end;

  { TDayDateRange }

  TDayDateRange = packed record
    Date1: TPrinterDate;
    Date2: TPrinterDate;
  end;

  { TDayNumberRange }

  TDayNumberRange = packed record
    Number1: Word;
    Number2: Word;
  end;

  { TFiscInfo }

  TFiscInfo = packed record
    Password: DWORD;    // Password (4 bytes)
    PrinterID: Int64;   // ECRRN (5 bytes) 0000000000�9999999999
    FiscalID: Int64;    // Taxpayer ID (6 byte) 000000000000�999999999999
    DayNumber: Word;  // Day number before fiscalization (refiscalization) (2 bytes) 0000�2100
    Date: TPrinterDate; // Fiscalization (refiscalization) date (3 bytes) DD-MM-YY
  end;

  { TDocResult }

  TDocResult = packed record
    OperatorNumber: Byte; // Operator number (1 byte) 1�30
    DocumentNumber: WORD; // Transparent document number (2 bytes)
  end;

  { TSlipParams }

  TSlipParams = packed record
    DocType: Byte;              // Document type (1 byte) '0' - sale, '1' - buy, '2' - sale refund, '3' - buy refund
    DupType: Byte;              // Duplicate type (1 byte) '0' - columns, '1' - line blocks
    DupCount: Byte;             // Duplicate count (1 byte) 0�5
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
    DocType: Byte;              // Document type (1 byte) '0' - sale, '1' - buy, '2' - sale refund, '3' - buy refund
    DupType: Byte;              // Duplicate type (1 byte) '0' - columns, '1' - WideString blocks
    DupCount: Byte;             // Duplicate count (1 byte) 0�5
    DupOffset1: Byte;           // Spacing between original and 1-st duplicate (1 byte) *
    DupOffset2: Byte;           // Spacing between 1-st and 2-nd duplicate (1 byte) *
    DupOffset3: Byte;           // Spacing between 2-nd and 3-d duplicate (1 byte) *
    DupOffset4: Byte;           // Spacing between 3-d and 4-th duplicate (1 byte) *
    DupOffset5: Byte;           // Spacing between 4-th and 5-th duplicate (1 byte) *
  end;

  { TSlipOperation }

  TSlipOperation = packed record
    QuantityFormat: Byte;       // Quantitiy format (1 byte) '0' - without digits after delimeter, '1' - with digits after delimeter
    LineCount: Byte;            // Operation line count (1 byte) 1�3
    TextLine: Byte;             // Text line number (1 byte) 0�3, '0' - do not print
    QuantityLine: Byte;         // Quantity times price line number (1 byte) 0�3, '0' - do not print
    SummLine: Byte;             // Sum line number (1 byte) 1�3
    DepartmentLine: Byte;       // Department line number (1 byte) 1�3
    TextFont: Byte;             // Text WideString font number (1 byte)
    QuantityFont: Byte;         // Quantity font numter (1 byte)
    MultSignFont: Byte;         // Multiplication sign font number (1 byte)
    PriceFont: Byte;            // Price font number (1 byte)
    SumFont: Byte;              // Sum font number (1 byte)
    DepartmentFont: Byte;       // Department font number (1 byte)
    TextWidth: Byte;            // Text WideString field character count (1 byte)
    QuantityWidth: Byte;        // Quantity field character count (1 byte)
    PriceWidth: Byte;           // Price field character count (1 byte)
    SumWidth: Byte;             // Sum field character count (1 byte)
    DepartmentWidth: Byte;      // Department field character count (1 byte)
    TextOffset: Byte;           // Text WideString field horizontal spacing (1 byte)
    QuantityOffset: Byte;       // Quantity times price field horizontal spacing (1 byte)
    SumOffset: Byte;            // Sum field horizontal spacing (1 byte)
    DepartmentOffset: Byte;     // Department field horizontal spacing (1 byte)
    LineNumber: Byte;           // Vertical position of first transaction WideString (1 byte)
  end;

const
  /////////////////////////////////////////////////////////////////////////////
  // Custom fields range

  MinReceiptField = 1;
  MaxReceiptField = 10;

type
  { TFSSale }

  TFSSale = record
    RecType: Integer;
    Quantity: Double;           // Quantity (5 bytes)
    Price: Int64;               // Price (5 bytes)
    Amount: Int64;              // Amount (5 bytes)
    Department: Byte;           // Department (1 byte) 0�16
    Tax: Byte;                  // Tax 1 (1 byte) '0' - no tax, '1'�'4' - tax group
    Charge: Int64;
    Discount: Int64;
    Barcode: Int64;
    Text: WideString;               // �������� ������
    AdjText: WideString;            // �������� ������ ��� ��������
    Parameter1: WideString;
    Parameter2: WideString;
    Parameter3: WideString;
    Parameter4: WideString;
    UnitName: WideString;
    MarkType: Integer;
    ReceiptField: array [MinReceiptField..MaxReceiptField] of string;
    Tag1162IsSet: Boolean;
  end;
  PFSSale = ^TFSSale;

  { TFSSale }

  TFSSale2 = record
    RecType: Integer;
    Quantity: Double;    // Quantity (5 bytes)
    Price: Int64;       // Price (5 bytes)
    Total: Int64;
    TaxAmount: Int64;
    Department: Byte;   // Department (1 byte) 0�16
    Tax: Byte;          // Tax 1 (1 byte) '0' - no tax, '1'�'4' - tax group
    Text: WideString;         // �������� ������
    UnitName: WideString;
    PaymentType: Byte;
    PaymentItem: Byte;
    MarkType: Integer;
  end;

  { TFSSale2Object }

  TFSSale2Object = class
    Data: TFSSale2;
  end;

  { TPriceReg }

  TPriceReg = packed record
    Quantity: Int64;    // Quantity (5 bytes)
    Price: Int64;       // Price (5 bytes)
    Department: Byte;   // Department (1 byte) 0�16
    Tax1: Byte;         // Tax 1 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax2: Byte;         // Tax 2 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax3: Byte;         // Tax 3 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax4: Byte;         // Tax 4 (1 byte) '0' - no tax, '1'�'4' - tax group
    Text: WideString;   // Text (40 byte)
  end;

  { TSlipDiscountParams }

  TSlipDiscountParams = packed record
    LineCount: Byte;    // Transaction line count (1 byte) 1�2
    TextLine: Byte;     // Text WideString line number (1 byte) 0�2, '0' - do not print
    NameLine: Byte;     // Transaction name line number (1 byte) 1�2
    AmountLine: Byte;   // Sum line number (1 byte) 1�2
    TextFont: Byte;     // Text WideString font number (1 byte)
    NameFont: Byte;     // Transaction name font number (1 byte)
    AmountFont: Byte;   // Sum font number (1 byte)
    TextWidth: Byte;    // Text WideString field character count (1 byte)
    AmountWidth: Byte;  // Sum field character count (1 byte)
    TextOffset: Byte;   // Text WideString field horizontal spacing (1 byte)
    NameOffset: Byte;   // Transaction name field horizontal spacing (1 byte)
    AmountOffset: Byte; // Sum field horizontal spacing (1 byte)
  end;

  { TSlipDiscount }

  TSlipDiscount = packed record
    OperationType: Byte; // Operation type (1 byte) '0' - discount, '1' - charge
    LineNumber: Byte;    // First discount/charge element vertical position (1 byte)
    Amount: Int64;       // Sum (5 bytes)
    Department: Byte;    // Department (1 byte) 0�16
    Tax1: Byte;          // Tax 1 (1 byte) '0' - not, '1'�'4' - tax group
    Tax2: Byte;          // Tax 2 (1 byte) '0' - not, '1'�'4' - tax group
    Tax3: Byte;          // Tax 3 (1 byte) '0' - not, '1'�'4' - tax group
    Tax4: Byte;          // Tax 4 (1 byte) '0' - not, '1'�'4' - tax group
    Text: WideString;        // Text (40 byte)
  end;

  { TCloseReceiptParams }

  TCloseReceiptParams = packed record
    CashAmount: Int64;  // Cash payment sum (5 bytes)
    Amount2: Int64;     // Payment type 2 sum (5 bytes)
    Amount3: Int64;     // payment type 3 sum (5 bytes)
    Amount4: Int64;     // Payment type 4 sum (5 bytes)
    PercentDiscount: WORD;      // Receipt discount in value 0 to 99.99 % (2 bytes) 0000�9999
    Tax1: Byte;         // Tax 1 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax2: Byte;         // Tax 2 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax3: Byte;         // Tax 3 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax4: Byte;         // Tax 4 (1 byte) '0' - no tax, '1'�'4' - tax group
    Text: WideString;       // Text (40 byte)
  end;

  { TCloseReceiptResult }

  TCloseReceiptResult = packed record
    OperatorNumber: Byte;       // Operator number (1 byte) 1�30
    Change: Int64;              // Change (5 bytes) 0000000000�9999999999
  end;

  { TSlipCloseParams }

  TSlipCloseParams = packed record
  
  end;

  { TAmountOperation }

  TAmountOperation = packed record
    Amount: Int64;      // Sum (5 bytes)
    Department: Byte;   // Department (1 byte) 0�16
    Tax1: Byte;         // Tax 1 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax2: Byte;         // Tax 2 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax3: Byte;         // Tax 3 (1 byte) '0' - no tax, '1'�'4' - tax group
    Tax4: Byte;         // Tax 4 (1 byte) '0' - no tax, '1'�'4' - tax group
    Text: WideString;       // Text (40 byte)
  end;

  { TReceiptDiscount2 }

  TReceiptDiscount2 = packed record
    Discount: Int64;      // Discount (5 bytes)
    Charge: Int64;        // Charge (5 bytes)
    Tax: Byte;            // Tax  (1 byte) '0' - no tax, '1'�'4' - tax group
    Text: WideString;         // Text (40 byte)
  end;

  { TDeviceMetrics }

  TDeviceMetrics = packed record
    DeviceType: Byte;           // Device type (1 byte) 0�255
    DeviceSubtype: Byte;        // Device suptype (1 byte) 0�255
    ProtocolVersion: Byte;      // Device protocol version (1 byte) 0�255
    ProtocolSubVersion: Byte;   // Device protocol subversion (1 byte) 0�255
    Model: Byte;                // Device model (1 byte) 0�255
    Language: Byte;             // Device language (1 byte) 0�255 Russian - 0; English - 1;
    DeviceName: WideString;         // Device name - WideString of characters in WIN1251.
  end;

  { TEJFlags }

  TEJFlags = packed record
    DocType: Byte;              // Document type, 0..3, Sale, buy, sale refund, buy refund
    ArcOpened: Boolean;         // Archive is opened
    Activated: Boolean;         // EJ is activated
    ReportMode: Boolean;        // Report mode
    DocOpened: Boolean;         // Document is opened
    DayOpened: Boolean;         // Day is opened
    ErrorFlag: Boolean;         // Device error
  end;

  { TEJStatus1 }

  TEJStatus1 = packed record
    DocAmount: Int64;           // Last KPK document total KPK (5 bytes) 0000000000�9999999999
    DocDate: TPrinterDate;      // Last KPK date (3 bytes) DD-MM-YY
    DocTime: TEJTime;           // Last KPK time (2 bytes) HH-MM
    DocNumber: DWORD;           // Last KPK number (4 bytes) 00000000�99999999
    EJNumber: Int64;            // EJ serial number (5 bytes) 0000000000�9999999999
    Flags: TEJFlags;            // EJ flags (1 byte)
  end;

  { TPrinterStatus }

  TPrinterStatus = packed record
    Mode: Byte;
    AdvancedMode: Byte;
    Flags: TPrinterFlags;
    OperatorNumber: Byte;
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

  { TCommandRec }

  TCommandRec = packed record
    Code: Integer;              // command code
    ResultCode: Byte;           // result code
    RepeatFlag: Boolean;        // repeat command
    Timeout: Integer;           // command timeout
    TxData: AnsiString;         // tx data
    RxData: AnsiString;         // rx data
  end;

  { TCashInResultRec }

  TCashInResultRec = record
    OperatorNumber: Byte;
    DocumentNumber: WORD;
  end;

  { TEJActivation }

  TEJActivation = record
    EJSerial: WideString;
    ActivationDate: WideString;
    ActivationTime: WideString;
  end;

  { TReceiptFormatItem }

  TReceiptFormatItem = record
    Line: Integer;
    Offset: Integer;
    Width: Integer;
    Alignment: Integer;
    Name: WideString;
  end;

  { TReceiptFormat }

  TReceiptFormat = record
    Valid: Boolean;
    Enabled: Boolean;
    TextItem: TReceiptFormatItem;            // ������������ � ��������
    QuantityItem: TReceiptFormatItem;        // ���������� X ���� � ��������
    DepartmentItem: TReceiptFormatItem;      // ������ � ��������
    AmountItem: TReceiptFormatItem;          // ��������� � ��������
    StornoItem: TReceiptFormatItem;          // ������� ������ � ��������
    DscText: TReceiptFormatItem;             // ����� � ������
    DscName: TReceiptFormatItem;             // ������� ������
    DscAmount: TReceiptFormatItem;           // ����� ������
    CrgText: TReceiptFormatItem;             // ����� � ��������
    CrgName: TReceiptFormatItem;             // ������� ��������
    CrgAmount: TReceiptFormatItem;           // ����� ��������
    DscStornoText: TReceiptFormatItem;       // ����� � ������ ������
    DscStornoName: TReceiptFormatItem;       // ������� ������ ������
    DscStornoAmount: TReceiptFormatItem;     // ����� ������ ������
    CrgStornoText: TReceiptFormatItem;       // ����� � ������ ��������
    CrgStornoName: TReceiptFormatItem;       // ������� ������ ��������
    CrgStornoAmount: TReceiptFormatItem;     // ����� ������ ��������
  end;

  TTextAlignment = (taLeft, taCenter, taRight);

  { TTextRec }

  TTextRec = record
    ID: Integer;
    Text: WideString;
    Station: Integer;
    Font: Integer;
    Alignment: TTextAlignment;
    Wrap: Boolean;
  end;

  { TBarcodeRec }

  TBarcodeRec = record
    Data: WideString; // barcode data
    Text: WideString; // barcode text
    Height: Integer;
    BarcodeType: Integer;
    ModuleWidth: Integer;
    Alignment: Integer;
    Parameter1: Byte;
    Parameter2: Byte;
    Parameter3: Byte;
    Parameter4: Byte;
    Parameter5: Byte;
  end;

  { TDrawScale }

  TDrawScale = record
    FirstLine: Byte;
    LastLine: Byte;
    VScale: Byte;
    HScale: Byte;
  end;

  { TBarcode2DData }

  TBarcode2DData = record
    BlockType: Byte;
    BlockNumber: Byte;
    BlockData: WideString;
  end;

  { TBarcode2D }

  TBarcode2D = record
    BarcodeType: Byte;
    DataLength: Word;
    BlockNumber: Byte;
    Parameter1: Byte;
    Parameter2: Byte;
    Parameter3: Byte;
    Parameter4: Byte;
    Parameter5: Byte;
    Alignment: Byte;
  end;

  { TFSCalcReport }

  TFSCalcReport = record
    DocNumber: Integer;             // ����� ��: 4 �����
    FiscalSign: Integer;            // ���������� �������: 4 �����
    OutstandDocCount: Integer;      // ���������� ��������������� ����������: 4 �����
    OutstandDocDate: TPrinterDate;  // ���� ������� ���������������� ���������: 3 ����� ��,��,��
  end;

  { TFSWriteStatus }

  TFSWriteStatus = record
    IsConnected: Boolean;       // ��� 0 � ������������ ���������� �����������
    HasMessageToSend: Boolean;  // ��� 1 � ���� ��������� ��� �������� � ���
    IsWaitForTicket: Boolean;   // ��� 2 � �������� ��������� ��������� (���������) �� ���
    IsServerCommand: Boolean;   // ��� 3 � ���� ������� �� ���
    ConnParamsChanged: Boolean; // ��� 4 � ���������� ��������� ���������� � ���
    IsWaitForAnswer: Boolean;   // ��� 5 � �������� ������ �� ������� �� ���
  end;

  { TFSCommStatus }

  TFSCommStatus = record
    WriteStatus: Byte;
    ReadStatus: Byte;
    DocumentCount: Word;
    DocumentNumber: Integer;
    DocumentDate: TPrinterDateTime;
    FSWriteStatus: TFSWriteStatus;
   end;

  TPayments = array [0..15] of Int64;
  TTaxTotals = array of Int64;
  TVatRates = array of Int64;

  { TFSCorrectionReceipt }

  TFSCorrectionReceipt = record
    RecType: Byte;
    Total: Int64;
    ResultCode: Integer;      // ��� ������: 1 ����
    ReceiptNumber: Integer;   // ����� ����: 2 �����
    DocumentNumber: Integer;  // ����� ��: 4 �����
    DocumentMac: Integer;     // ���������� �������: 4 ����
  end;

  { TFSCorrectionReceipt2 }

  TFSCorrectionReceipt2 = record
    CorrectionType: Byte; // ��� ��������� :1 ����
    CalculationSign: Int64; // ������� �������:1����
    Amount1: Int64; // ����� ������� :5 ����
    Amount2: Int64; // ����� �� ���� ���������:5 ����
    Amount3: Int64; // ����� �� ���� ������������:5 ����
    Amount4: Int64; // ����� �� ���� �����������:5 ����
    Amount5: Int64; // ����� �� ���� �����������:5 ����
    Amount6: Int64; // ����� �� ���� ��������� ��������������:5 ����
    Amount7: Int64; // ����� ��� 20%:5 ����
    Amount8: Int64; // ����� ��� 10%:5 ����
    Amount9: Int64; // ����� ������� �� ������ 0%:5 ����
    Amount10: Int64; // ����� ������� �� ���� ��� ���:5 ����
    Amount11: Int64; // ����� ������� �� ����. ������ 20/120:5 ����
    Amount12: Int64; // ����� ������� �� ����. ������ 10/110:5 ����
    TaxType: Byte; // ����������� ������� ���������������:1����

    ResultCode: Integer;      // ��� ������: 1 ����
    ReceiptNumber: Integer;   // ����� ����: 2 �����
    DocumentNumber: Integer;  // ����� ��: 4 �����
    DocumentMac: Integer;     // ���������� �������: 4 ����
  end;

  { TFSTicket }

  TFSTicket = record
    Number: Integer;
    Data: WideString;
    Date: TPrinterDateTime;   // ���� � �����             DATE_TIME      5
    DocumentMac: WideString;      // ���������� ������� ���   DATA           18
    DocumentNum: Integer;     // ����� ��                 Uint32, LE     4
  end;

  { TFSCloseReceiptParams2 }

  TFSCloseReceiptParams2 = record
    Payments: TPayments;
    Discount: Byte;
    // 1..10 � ��� FF76/FNCloseCheckEx3; 11..12 � ��� 22% / 22/122 (FNCloseCheckEx4)
    TaxAmount: array [1..12] of Int64;
    TaxSystem: Byte;
    Text: WideString;
  end;

  { TFSCloseReceiptResult2 }

  TFSCloseReceiptResult2 = record
    Change: Int64;
    DocNumber: Int64;
    MacValue: Int64;
    DocDate: TPrinterDate;
    DocTime: TPrinterTime;
  end;

  { TPrinterParameters2Flags }

  TPrinterParameters2Flags = record
    CapJrnNearEndSensor: Boolean;   // 0 � ������� ������ ����������� �����
    CapRecNearEndSensor: Boolean;   // 1 � ������� ������ ������� �����
    CapJrnEmptySensor: Boolean;     // 2 � ���������� ������ ����������� �����
    CapRecEmptySensor: Boolean;     // 3 � ���������� ������ ������� �����
    CapCoverSensor: Boolean;        // 4 � ������ ������
    CapJrnLeverSensor: Boolean;     // 5 � ����� ������������ ����������� �����
    CapRecLeverSensor: Boolean;     // 6 � ����� ������������ ������� �����
    CapSlpNearEndSensor: Boolean;   // 7 � ������� ������ ����������� ���������
    CapSlpEmptySensor: Boolean;     // 8 � ������ ������ ����������� ���������
    CapPresenter: Boolean;          // 9 � ��������� ��������������
    CapPresenterCommands: Boolean;  // 10 � ��������� ������ ������ � �����������
    CapEJNearFull: Boolean;         // 11 � ���� ���������� ����
    CapEJ: Boolean;                 // 12 � ���� ��������������
    CapCutter: Boolean;             // 13 � �������� ��������������
    CapDrawerStateAsPaper: Boolean; // 14 � ��������� �� ��� ������ ������ � ����������
    CapDrawerSensor: Boolean;       // 15 � ������ ��������� �����
    CapPrsInSensor: Boolean;        // 16 � ������ ������ �� ����� � ���������
    CapPrsOutSensor: Boolean;       // 17 � ������ ������ �� ������ �� ����������
    CapBillAcceptor: Boolean;       // 18 � �������������� ��������������
    CapTaxKeyPad: Boolean;          // 19 � ���������� �� ��������������
    CapJrnPresent: Boolean;         // 20 � ����������� ����� ��������������
    CapSlpPresent: Boolean;         // 21 � ���������� �������� ��������������
    CapNonfiscalDoc: Boolean;       // 22 � ��������� ������ ������������� ���������
    CapCashCore: Boolean;           // 23 � ��������� ��������� ��������� ���� (cashcore)
    CapInnLeadingZero: Boolean;     // 24 � ������� ���� � ���
    CapRnmLeadingZero: Boolean;     // 25 � ������� ���� � ���
    SwapGraphicsLine: Boolean;      // 26 � �������������� ����� ��� ������ �����
    CapTaxPasswordLock: Boolean;    // 27 � ���������� ��� �� ��������� ������ ���������� ����������
    CapProtocol2: Boolean;          // 28 � ��������� ��������������� ������� ������ ��������� ���
    CapLFInPrintText: Boolean;      // 29 � ��������� �������� ����� �������� '\n' (��� 10) � �������� ������ ����� 12H, 17H, 2FH
    CapFontInPrintText: Boolean;  // 30 � ��������� �������� ����� ������� ������ (���� 1�9) � ������� ������ ����� 2FH
    CapLFInFiscalCommands: Boolean; // 31 � ��������� �������� ����� �������� '\n' (��� 10) � ���������� �������� 80H�87H, 8AH, 8BH
    CapFontInFiscalCommands: Boolean; // 32 � ��������� �������� ����� ������� ������ (���� 1�9) � ���������� �������� 80H�87H, 8AH, 8BH
    CapTopCashierReports: Boolean;   // 33 � ����� "������� ������" (28) �� ������ �������: X, ������������ ���������, �� �������, �� �������, �� ��������, ����������, �� �������
    CapSlpInPrintCommands: Boolean;      // 34 � ��������� ��� 3 "���� ���" � �������� ������: ����� 12H, 17H, 2FH,����������� ������� 4DH, C3H, ����������� ����� C5H; ���������
    CapGraphicsC4: Boolean;           // 35 � ��������� ������� �������� ������� � ������� C4H
    CapCommand6B: Boolean;            // 36 � ��������� ������� 6BH "������� �������� �������"
    CapFlagsGraphicsEx: Boolean;      // 37 � ��������� ������ ������ ��� ������ ������ ����������� ������� C3H � ������ ����������� ����� C5H
    CapMFP: Boolean;                  // 39 � ��������� ���
    CapEJ5: Boolean;                  // 40 � ��������� ����5
    CapScaleGraphics: Boolean;        // 41 � ������ ������� � ���������������� (������� 4FH)
    CapGraphics512: Boolean;          // 42 � �������� � ������ �������-512 (������� 4DH, 4EH)
  end;

  { TPrinterParameters2 }

  TPrinterParameters2 = packed record
    FlagsValue: Int64;
    Font1Width: Byte;
    Font2Width: Byte;
    GraphicsStartLine: Byte;
    InnDigits: Byte;
    RnmDigits: Byte;
    LongRnmDigits: Byte;
    LongSerialDigits: Byte;
    DefTaxPassword: DWORD;
    DefSysPassword: DWORD;
    BluetoothTable: Byte;
    TaxFieldNumber: Byte;
    MaxCommandLength: WORD;
    GraphicsWidthInBytes: Byte;
    Graphics512WidthInBytes: Byte;
    Graphics512MaxHeight: WORD;
    Flags: TPrinterParameters2Flags;
  end;

  { TFSFiscalization }

  TFSFiscalization = record
    TaxID: WideString;
    RegID: WideString;
    TaxCode: Byte;
    WorkMode: Byte;
  end;

  { TFSReFiscalization }

  TFSReFiscalization = record
    TaxID: WideString;
    RegID: WideString;
    TaxCode: Byte;
    WorkMode: Byte;
    ReasonCode: Byte;
  end;

  { TFDDocument }

  TFDDocument = record
    DocNumber: DWORD;
    DocMac: DWORD;
  end;

  { TFSReadDocument }

  TFSReadDocument = record
    Password: Integer;
    Number: Integer;
    DocType: Word;
    DocLength: Word;
  end;

  { TFSReadDocData }

  TFSReadDocData = record
    Password: Integer;
    TLVData: WideString;
  end;

  { TFSCheckItemCode }

  TFSCheckItemCode = record
    ItemStatus: Byte; // ����������� ������	��� 2003
    ProcessMode: Byte; // ����� ���������	��� 2102 (������ ������ "0")
    CMData: AnsiString; // ��� ��, ��� �� ��� �������� ��������
    TLVData: AnsiString; // ������ TLV
  end;

  { TFSCheckItemResult }

  TFSCheckItemResult = record
    LocalCheckResult: Byte; // ������ ��������� ��������	��� 2004
    LocalCheckError: Byte; // �������, �� ������� �� ���� ��������� ��������� ��������
    SymbolicType: Byte; // ������������ ��� ��	��� 2100
    DataLength: Byte; // ����� �������������� ����������
    FSResultCode: Byte; // ��� ������ �� �� ������� ������-��������
    ServerCheckStatus: Byte; // ��������� �������� ��	��� 2106
    ServerTLVData: AnsiString; // ������ ���������� ������ �������
  end;

  { TFSReadMemoryResult }

  TFSReadMemoryResult = record
    FreeDocCount: DWORD; // ������ ������ 5 ������� �������� 1 (4 �����)
    FreeMemorySizeInKB: DWORD; // ������ ������ 30 �������� �������� 2 (4 �����)
    UsedMCTicketStorageInPercents: Byte; // ������ ��� �������� ����������� � ���������� �������������� ������3 (1 ����)
  end;

  { TFSBindItemCode }

  TFSBindItemCode = record
    Code: AnsiString; // ������ ����������
    IsAccounted: Boolean; // �������-�������� ���� (���)
  end;

  { TFSBindItemCodeResult }

  TFSBindItemCodeResult = record
    ItemCode: Word;
    CodeType: Byte;
    CheckResult: TFSCheckItemResult;
  end;

  { TFSTicketStatus }

  TFSTicketStatus = record
    TicketStatus: Byte; // ��������� �� �������� �����������
    TicketCount: Integer; // ���������� ����������� � �������
    TicketNumber: Integer; // ����� �������� �����������
    TicketDate: TPrinterDateTime; // ���� � ����� �������� �����������
    TicketStorageUsageInPercents: Byte; // ������� ���������� ������� �������� �����������
  end;

  { TFSMarkStatus }

  TFSMarkStatus = record
    MarkCheckStatus: Byte; // ��������� �� �������� ��
    TicketStatus: Byte; // ��������� �� ������������ ����������� � ���������� �������������� ������
    CommandFlags: Byte; // ����� ���������� ������ ������ � ��
    MCSavedCount: Byte; // ���������� ����������� ����������� �������� ��
    MCTicketCount: Byte; // ���������� ��, ���������� � ����������� � ���������� �������������� ������
    TicketStorageStatus: Byte; // �������������� � ���������� ������� �������� �����������
    TicketCount: Integer; // ���������� ����������� � �������
  end;

  { TFSTicketParams }

  TFSTicketParams = record
    TicketCount: Integer; // ����� ����� ����������� (2 �����)
    FirstTicketNumber: Integer; // ����� ������� ����������� (4 �����)
    FirstTicketSize: Integer; // ������ ������� ����������� (2 �����)
  end;

  { TFSTicketData }

  TFSTicketData = record
    Number: Integer; // ����� �������� ����������� (4 �����)
    Size: Integer; // ������ ������ �������� ����������� (2 �����)
    Offset: Integer; // �������� �� ������ �������� ����������� (2 �����)
    Data: AnsiString; // ���� ������ (N ����)
  end;

  { TFSTicketNumber }

  TFSTicketNumber = record
    Number: Integer; // ����� ����������� (4 �����) ���������� �� ������ �� ������� FF72h
    Crc16: Integer; // CRC16 (4 �����) ����������� ����� �����������
  end;

  { TFSDocSize }

  TFSDocSize = record
    DocSize: Integer; // ������ � ������ �������� ��������� ��� ��� ( 4 �����)
    TicketSize: Integer; // ������ � ������ �������� ����������� � ���������� ������������� ������� ��� ���� ( 4 �����)
  end;


  { TCommandFF03 }

  TCommandFF03 = record
    ExpDate: TPrinterDate;
    RegLeft: Byte;
    RegNumber: Byte;
  end;

const
  ///////////////////////////////////////////////////////////////////////////////
  // ItemStatus constants

  SMFP_ITEM_STATUS_FORMED      = 1; // 1 - "�����������".�� ����� ������������.
  SMFP_ITEM_STATUS_READY       = 2; // 2 - "�����". ����� ������������, �� �� ��������.
  SMFP_ITEM_STATUS_ISSUED      = 3; // 3 - "�����". �� ����� �� ��� ���������. ���������� �� ������������.
  SMFP_ITEM_STATUS_RELEASED    = 4; // 4 - "�������". �� ������� �� ����� ��� ��������, ������������ ��������� ���� ������������, ������������� ����� ����������.
  SMFP_ITEM_STATUS_NOTUSED     = 5; // 5 - "�� �����������". �� �� ��� ����� �� � ������� �������� ������.
  SMFP_ITEM_STATUS_PACKED      = 6; // 6 - "��������". ����� ��� �������� � ������ �� ��������� � ������� ������������� �������.
  SMFP_ITEM_STATUS_UNPACKED    = 7; // 7 - "����������". ������������� ������ ��������� � ������� ��� � ������������ � ���� �������� �������.
  SMFP_ITEM_STATUS_DROPPED_OUT = 8; // 8 - ����� �� ������������, ��������� ���������� ��������� ������, �������� �� ����� ������������ (��������, �������, ��� ������� ������� ��� ���������), �������� ��� ���������� ������� (��������� ������������ � ������� ������������� �������, ����������, ����������� � ������������ �� ���� ���������� � �.�.).
  SMFP_ITEM_STATUS_RETAILED    = 9; // 9 - "����� ����� ��������� ����".
  SMFP_ITEM_STATUS_RETAILING   = 10; // 10 - "� ��������� �������" (������ �����).
  SMFP_ITEM_STATUS_LOST        = 11; // 11 - "������".
  SMFP_ITEM_STATUS_STOPPED     = 12; // 12 - "������ �������������".
  SMFP_ITEM_STATUS_DISABLED    = 13; // 13 - "������ ��������".
  SMFP_ITEM_STATUS_SOLD        = 14; // 14 - "���������".
  SMFP_ITEM_STATUS_DUPLICATED  = 15; // 15 - "����������".

  ///////////////////////////////////////////////////////////////////////////////
  // CheckMode constants

  SMFP_CHECK_MODE_FULL    = 0; // 0 - ������ ��������.
  SMFP_CHECK_MODE_ONLINE  = 1; // 1 - ������ ������ ��������.
  SMFP_CHECK_MODE_LOCAL   = 2; // 2 - ������ ��������� ��������.

  ///////////////////////////////////////////////////////////////////////////////
  // LocalCheckResult constants
  // ��������� ��������� �������� ���� ����������: 1 ����

  SMFP_LOCAL_CHECK_SCS      = 0; // 0 - �������� �� �����������, (��� ������������ ����������������� �������).
  SMFP_LOCAL_CHECK_OK       = 1; // 1 - ��� ���������� ��������, �����������.
  SMFP_LOCAL_CHECK_FAILED   = 2; // 2 - ��� ���������� ��������, �������������.
  SMFP_LOCAL_CHECK_ACS      = 3; // 3 - �������� �� �����������, (����������������� ������� �������������, �� � ��-� ��� ����� � ��������������� �����.��)

  ///////////////////////////////////////////////////////////////////////////////
  // SellPermission constants
  // ���������� �� ������� ������ �� ���: 1 ����.

  SMFP_SELL_PERMISSION_OK      = 0; // 0 - ����� �������� � �������
  SMFP_SELL_PERMISSION_DENIED  = 1; // 1 - ����� �������� � �������

  ///////////////////////////////////////////////////////////////////////////////
  // ServerResult constants
  // ��� ������ �� ������� ��: 1 ����

  SMFP_SERVER_RESULT_OK         = 0; // 0 - ������ ������� �������
  SMFP_SERVER_RESULT_NODATA     = 1; // 1 - ��� ����������� � ���� ������� ����� ��� ��� ����������� � ���� ���
  SMFP_SERVER_RESULT_BADFORMAT  = 2; // 2 - �� ��������� ������ ���
  SMFP_SERVER_RESULT_FAILED     = 3; // 3 - ����������������� �������� ����� ���� ������������� ���������
  SMFP_SERVER_RESULT_STATUS     = 4; // 4 - ��� ����� � ���� ������� ����� ������ �� ����������� � ������������� ����������. ��������, ��������� ��������� ������� "����� � ��������� ����" � �� �����, ��� ����� ��� ��� ������. ����� �������, ������������� ����������� ��������� ������� ���� ����������
  SMFP_SERVER_RESULT_ATTACHMENT = 5; // 5 - � ������ �������� ���������� ������

  ///////////////////////////////////////////////////////////////////////////////
  // SymbolicType constants
  // ��� ���������: 1 ����
  SMFP_SYMBOLIC_ASYMMETRIC  = 0; // 0 - �������������
  SMFP_SYMBOLIC_SYMMETRIC   = 1; // 1 - ������������
  SMFP_SYMBOLIC_TOBACCO     = 2; // 2 - ��������

  /////////////////////////////////////////////////////////////////////////////
  // ������� ������� ������� (��� 1214)

  PaymentTypeDeposit          = 1;  // 1 ���������� 100%
  PaymentTypePartialDeposit   = 2;  // 2 ��������� ����������
  PaymentTypeAdvance          = 3;  // 3 �����
  PaymentTypeCash             = 4;  // 4 ������ ������
  PaymentTypeCashCredit       = 5;  // 5. ��������� ������ � ������
  PaymentTypeCredit           = 6;  // 6. �������� � ������
  PaymentTypePayCredit        = 7;  // 7. ������ �������

  /////////////////////////////////////////////////////////////////////////////
  // ������� �������� ������� (��� 1212)

  PaymentItemNormal           = 1; // 1. �����
  PaymentItemExcise           = 2; // 2. ����������� �����
  PaymentItemJob              = 3; // 3. ������
  PaymentItemService          = 4; // 4. ������
  PaymentItemBet              = 5; // 5. ������ �������� ����
  PaymentItemGamePrize        = 6; // 6. ������� �������� ����
  PaymentItemLotteryBill      = 7; // 7. ���������� �����
  PaymentItemLotteryPrize     = 8; // 8. ������� �������
  PaymentItemIntellect        = 9; // 9. �������������� ���
  PaymentItemPayment          = 10; // 10. ������
  PaymentItemComposite        = 11; // 11. ��������� ������� �������
  PaymentItemOther            = 12; // 12. ���� ������� �������


function GetCommandName(Command: Integer): WideString;
function GetModeDescription(Value: Integer): WideString;
function GetDeviceCodeDescription(Value: Integer): WideString;
function GetErrorText(Code: Integer; IsFSInstalled: Boolean): WideString;
function GetFullErrorText(Code: Integer; IsFSEnabled: Boolean): WideString;
function GetAdvancedModeDescription(Value: Integer): WideString;
function GetCashRegisterName(Value: Integer): WideString;
function BaudRateToCBR(Value: TBaudRate): Integer;
function CBRToBaudRate(Value: Integer): TBaudRate;
function IsRecStation(Stations: Byte): Boolean;
function IsJrnStation(Stations: Byte): Boolean;
function IsSlpStation(Stations: Byte): Boolean;
function IsFieldStr(FieldType: Integer): Boolean;
function IsFieldInt(FieldType: Integer): Boolean;
function IntToBool(Value: Integer): Boolean;
function ComparePrinterDate(const Date1, Date2: TPrinterDate): Integer;

function EncodePrinterFlags(Flags: TPrinterFlags): Word;
function DecodePrinterFlags(Flags: Word): TPrinterFlags;
function GetModeText(Mode: Integer): WideString;
function GetOperRegisterName(Value: Integer): WideString;
function PrinterDateToDate(Date: TPrinterDate): TDateTime;
function PrinterTimeToTime(Time: TPrinterTime): TDateTime;
function BinToPrinterDate(const P: WideString): TPrinterDate;
function BinToPrinterTime2(const P: WideString): TPrinterTime;
function BinToPrinterDateTime2(const P: WideString): TPrinterDateTime;
function PrinterDateTimeToStr2(Date: TPrinterDateTime): WideString;
function PrinterDateTimeToStr3(Date: TPrinterDateTime): WideString;
function PrinterTimeToStr(Time: TPrinterTime): WideString;
function PrinterTimeToStr2(Time: TPrinterTime): WideString;
function PrinterDateToStr(Date: TPrinterDate): WideString;
function IsEqual(const I1, I2: TPrinterStatus): Boolean;
function getServerResultCodeText(ServerCode: Integer): WideString;
function GetCurrentPrinterDate: TPrinterDate;
function GetCurrentPrinterTime: TPrinterTime;
function EncodeOposDate(const Date: TPrinterDate): WideString; overload;
function EncodeOposDate(const Date: TPrinterDateTime): WideString; overload;
function EncodeOposDate(const Date: TPrinterDate; const Time: TPrinterTime): WideString; overload;

function DecodeOposDate(const Date: WideString): TPrinterDate; overload;
function DecodeOposDateTime(const Date: WideString): TPrinterDateTime; overload;

implementation

function EncodeOposDate(const Date: TPrinterDate): WideString;
begin
  Result := Tnt_WideFormat('%.2d%.2d%.4d%.2d%.2d',[
    Date.Day, Date.Month, 2000 + Date.Year, 0, 0]);
end;

function EncodeOposDate(const Date: TPrinterDateTime): WideString;
begin
  Result := Tnt_WideFormat('%.2d%.2d%.4d%.2d%.2d',[
    Date.Day, Date.Month, 2000 + Date.Year, Date.Hour, Date.Min]);
end;

function EncodeOposDate(const Date: TPrinterDate; const Time: TPrinterTime): WideString; overload;
begin
  Result := Tnt_WideFormat('%.2d%.2d%.4d%.2d%.2d',[
    Date.Day, Date.Month, 2000 + Date.Year, Time.Hour, Time.Min]);
end;

// ddmmyyyyhhmm

// dd day of the month (1 - 31)
// mm month (1 - 12)
// yyyy year (1997-)
// hh hour (0-23)
// mm minutes (0-59)

function DecodeOposDateTime(const Date: WideString): TPrinterDateTime;
begin
  Result.Day := StrToInt(Copy(Date, 1, 2));
  Result.Month := StrToInt(Copy(Date, 3, 2));
  Result.Year := StrToInt(Copy(Date, 5, 4)) mod 100;
  Result.Hour := StrToInt(Copy(Date, 9, 2));
  Result.Min := StrToInt(Copy(Date, 11, 2));

  if not(Result.Day in [1..31]) then
    raiseExtendedError(OPOS_EFPTR_BAD_DATE, _('Invalid day'));

  if not(Result.Month in [1..12]) then
    raiseExtendedError(OPOS_EFPTR_BAD_DATE, _('Invalid month'));

  if not(Result.Hour in [0..23]) then
    raiseExtendedError(OPOS_EFPTR_BAD_DATE, _('Invalid hour'));

  if not(Result.Min in [0..59]) then
    raiseExtendedError(OPOS_EFPTR_BAD_DATE, _('Invalid minutes'));
end;

function DecodeOposDate(const Date: WideString): TPrinterDate;
begin
  Result.Day := StrToInt(Copy(Date, 1, 2));
  Result.Month := StrToInt(Copy(Date, 3, 2));
  Result.Year := StrToInt(Copy(Date, 5, 4)) mod 100;

  if not(Result.Day in [1..31]) then
    raiseExtendedError(OPOS_EFPTR_BAD_DATE, _('Invalid day'));

  if not(Result.Month in [1..12]) then
    raiseExtendedError(OPOS_EFPTR_BAD_DATE, _('Invalid month'));
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
  Result.EJPresent := TestBit(Flags, 5);
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
  Result.Value := Flags;
end;


function IntToBool(Value: Integer): Boolean;
begin
  Result := Value <> 0;
end;

function GetFullErrorText(Code: Integer; IsFSEnabled: Boolean): WideString;
begin
  Result := Tnt_WideFormat('(%d), %s', [Code, GetErrorText(Code, IsFSEnabled)]);
end;


function FSGetErrorText(Code: Integer; const Text: WideString): WideString;
begin
  case Code of
    $01: Result := _('FS: Unknown command or invalid format');
    $02: Result := _('FS: Incorrect status');
    $03: Result := _('FS: Error, read extended error code');
    $04: Result := _('FS: CRC error, read extended error code');
    $05: Result := _('FS: Device expired');
    $06: Result := _('FS: Archive overflow error');
    $07: Result := _('FS: Invalid date/time value');
    $08: Result := _('FS: No data available');
    $09: Result := _('FS: Invalid parameter value');
    $10: Result := _('FS: TLV size too large');
    $11: Result := _('FS: No transport connection ');
    $12: Result := _('FS: Cryptographic coprocessor resource exhausted');
    $14: Result := _('FS: Documents resource exhausted');
    $15: Result := _('FS: Maximum send time limit reached');
    $16: Result := _('FS: Fiscal day last for 24 hours');
    $17: Result := _('FS: Invalid time range betseen two operations');
    $20: Result := _('FS: Server message can not be received');

    $30: Result := _('FS: No connection to fiscal storage');
    $31: Result := _('FS: format error');
    $32: Result := _('FS: CRC error');
  else
    Result := Text;
  end;
end;

function FSGetErrorTextRus(Code: Integer; const Text: WideString): WideString;
begin
  case Code of
    $01: Result := _('��: ����������� �������, �������� ������ ������� ��� ����������� ���������');
    $02: Result := _('��: ������ ��������� ��');
    $03: Result := _('��: ����� ��');
    $04: Result := _('��: ����� ��');
    $05: Result := _('��: ��������� ������� �� ������������� ����� ����� ��');
    $06: Result := _('��: ����� �� ����������');
    $07: Result := _('��: �������� ���� �/��� �����');
    $08: Result := _('��: ��� ����������� ������');
    $09: Result := _('��: ������������ �������� ���������� �������');
    $0A: Result := _('��: ������������ �������');
    $0B: Result := _('��: ������������� ���������');
    $0C: Result := _('��: ������������ ������');
    $0D: Result := _('��: ����������� ������, ����������� ��� ����������� ����� � ��');
    $0E: Result := _('��: ���������� ������� � ��������� ��������� ���������� ������');
    $10: Result := _('��: ���������� �������� TLV ������');
    $11: Result := _('��: ��� ������������� ����������');
    $12: Result := _('��: �������� ������ ��');
    $14: Result := _('��: ����������� ������� ��');
    $16: Result := _('��: ����������������� ����� ����� 24 �����');
    $17: Result := _('��: �������� ������� �� ������� ����� ����� ���������');
    $18: Result := _('��: ������������ ��������, ���������� ��� � ��');
    $19: Result := _('��: �������� �� ������������� ���������� ��� �����������');
    $20: Result := _('��: ������ ��� ��������� ������ � ��');
    $21: Result := _('��� ����� � ��. ��������� ������ !!!');
    $23: Result := _('��: ������������� ����� ������� ���������� ������ �������� ��');
    $24: Result := _('��: ����������� ����� ������� ���������� ������ ��������');
    $30: Result := _('��: �� �� ��������');
    $77: Result := _('��: ������ ��������');
    $79: Result := _('��: ������ �����');
    $A0: Result := _('��: ��������� ������ � ������������� ��������');
    $A1: Result := _('��: �������� ������������������ ������ ������ Bxh');
    $A2: Result := _('��: ������ � �������������� �������� �������� �������������');
    $A3: Result := _('��: ����������� ������� �������� ��');
    $AA: Result := _('��: � ����� TLV ����������� ����������� ���������');
    $AC: Result := _('��: � ��������� 2007 ���������� ��, ������� ����� �� ���������� � ��');
  else
    Result := Text;
  end;
end;

function GetErrorText2Rus(Code: Integer): WideString;
begin
  case Code of
    $00: Result := _('������ ���');
    $01: Result := _('���������� ���������� �� 1, �� 2 ��� ����');
    $02: Result := _('����������� �� 1');
    $03: Result := _('����������� �� 2');
    $04: Result := _('������������ ��������� � ������� ��������� � ��');
    $05: Result := _('��� ����������� ������');
    $06: Result := _('�� � ������ ������ ������');
    $07: Result := _('������������ ��������� � ������� ��� ������ ���������� ��');
    $08: Result := _('������� �� �������������� � ������ ���������� ��');
    $09: Result := _('������������ ����� �������');
    $0A: Result := _('������ ������ �� BCD');
    $0B: Result := _('���������� ������ ������ �� ��� ������ �����');
    $11: Result := _('�� ������� ��������');
    $12: Result := _('��������� ����� ��� ������');
    $13: Result := _('������� ���� ������ ���� ��������� ������ � ��');
    $14: Result := _('������� ������� ������ �� �����������');
    $15: Result := _('����� ��� �������');
    $16: Result := _('����� �� �������');
    $17: Result := _('����� ������ ����� ������ ������ ��������� �����');
    $18: Result := _('���� ������ ����� ������ ���� ��������� �����');
    $19: Result := _('��� ������ � ��');
    $1A: Result := _('������� ��������������� � �� �����������');
    $1B: Result := _('��������� ����� �� ������');
    $1C: Result := _('� �������� ��������� ���� ������������ ������');
    $1D: Result := _('���������� ��������� ������ ������� ������');
    $1E: Result := _('������� ��������������� �� �����������');
    $1F: Result := _('����������� ������ ���������');
    $20: Result := _('������������ ��������� �������� ��� ����������');
    $21: Result := _('���������� ����� ������ ����������� ��������� ��������');
    $22: Result := _('�������� ����');
    $23: Result := _('��� ������ �����������');
    $24: Result := _('������� ����������� �����������');
    $25: Result := _('��� ����������� � ������������� �������');
    $26: Result := _('� �� ������ 3 ������������ �������');
    $27: Result := _('����������� ����������� ���� ��');
    $28: Result := _('������������ �� �� ���������� ������������ ��');
    $29: Result := _('������������������� ������ ��');
    $2F: Result := _('���� �� ��������');
    $30: Result := _('���� �������� NAK');
    $31: Result := _('����: ������ �������');
    $32: Result := _('����: ������ ����������� �����');
    $33: Result := _('������������ ��������� � �������');
    $34: Result := _('��� ������');
    $35: Result := _('������������ �������� ��� ������ ����������');
    $36: Result := _('������������ ��������� � ������� ��� ������ ����������');
    $37: Result := _('������� �� �������������� � ������ ����������');
    $38: Result := _('������ � ���');
    $39: Result := _('���������� ������ ��');
    $3A: Result := _('������������ ���������� �� ��������� � �����');
    $3B: Result := _('������������ ���������� � �����');
    $3C: Result := _('����: �������� ��������������� �����');
    $3D: Result := _('����� �� ������� - �������� ����������');
    $3E: Result := _('������������ ���������� �� ������� � �����');
    $3F: Result := _('������������ ���������� �� ������� � �����');
    $40: Result := _('������������ ��������� ������');
    $41: Result := _('������������ ��������� ������ ���������');
    $42: Result := _('������������ ��������� ������ ����� 2');
    $43: Result := _('������������ ��������� ������ ����� 3');
    $44: Result := _('������������ ��������� ������ ����� 4');
    $45: Result := _('C���� ���� ����� ������ ������ ����� ����');
    $46: Result := _('�� ������� ���������� � �����');
    $47: Result := _('������������ ���������� �� ������� � �����');
    $48: Result := _('������������ ����� ����');
    $49: Result := _('�������� ���������� � �������� ���� ������� ����');
    $4A: Result := _('������ ��� - �������� ����������');
    $4B: Result := _('����� ���� ����������');
    $4C: Result := _('������������ ���������� �� ������� ������� � �����');
    $4D: Result := _('�������� ����������� ������� ����� ������ ����� ����');
    $4E: Result := _('����� ��������� 24 ����');
    $4F: Result := _('�������� ������');
    $50: Result := _('���� ������ ���������� �������');
    $51: Result := _('������������ ���������� ��������� � �����');
    $52: Result := _('������������ ���������� �� ���� ������ 2 � �����');
    $53: Result := _('������������ ���������� �� ���� ������ 3 � �����');
    $54: Result := _('������������ ���������� �� ���� ������ 4 � �����');
    $55: Result := _('��� ������ - �������� ����������');
    $56: Result := _('��� ��������� ��� �������');
    $57: Result := _('����: ���������� �������� ���� �� ��������� � ��');
    $58: Result := _('�������� ������� ����������� ������');
    $59: Result := _('�������� ������ ������ ����������');
    $5A: Result := _('������ ��������� ���������� � ����');
    $5B: Result := _('������������ ��������� ��������');
    $5C: Result := _('�������� ���������� 24�');
    $5D: Result := _('������� �� ����������');
    $5E: Result := _('������������ ��������');
    $5F: Result := _('������������� ���� ����');
    $60: Result := _('������������ ��� ���������');
    $61: Result := _('������������ ��������� ����');
    $62: Result := _('������������ ��������� ����������');
    $63: Result := _('������������ ��������� ������');
    $64: Result := _('�� �����������');
    $65: Result := _('�� ������� ����� � ������');
    $66: Result := _('������������ ����� � ������');
    $67: Result := _('������ ����� � ��');
    $68: Result := _('�� ������� ����� �� ������� �������');
    $69: Result := _('������������ ����� �� ������� �������');
    $6A: Result := _('������ ������� � ������ ������ �� I2C');
    $6B: Result := _('��� ������� �����');
    $6C: Result := _('��� ����������� �����');
    $6D: Result := _('�� ������� ����� �� ������');
    $6E: Result := _('������������ ����� �� ������');
    $6F: Result := _('������������ �� ������� � �����');
    $70: Result := _('������������ ��');
    $71: Result := _('������ ���������');
    $72: Result := _('������� �� �������������� � ������ ���������');
    $73: Result := _('������� �� �������������� � ������ ������');
    $74: Result := _('������ ���');
    $75: Result := _('������ �������');
    $76: Result := _('������ ��������: ��� ��������� � ��������������');
    $77: Result := _('������ ��������: ��� ������� � ��������');
    $78: Result := _('������ ��');
    $79: Result := _('������ ��');
    $7A: Result := _('���� �� �������������');
    $7B: Result := _('������ ������������');
    $7C: Result := _('�� ��������� ����');
    $7D: Result := _('�������� ������ ����');
    $7E: Result := _('�������� �������� � ���� �����');
    $7F: Result := _('������������ ��������� �����');
    $80: Result := _('������ ����� � ��');
    $81: Result := _('������ ����� � ��');
    $82: Result := _('������ ����� � ��');
    $83: Result := _('������ ����� � ��');
    $84: Result := _('������������ ����������');
    $85: Result := _('������������ �� �������� � �����');
    $86: Result := _('������������ �� �������� � �����');
    $87: Result := _('������������ �� ��������� ������ � �����');
    $88: Result := _('������������ �� ��������� ������� � �����');
    $89: Result := _('������������ �� �������� � �����');
    $8A: Result := _('������������ �� ��������� � ����');
    $8B: Result := _('������������ �� ������� � ����');
    $8C: Result := _('������������� ���� �������� � ����');
    $8D: Result := _('������������� ���� ������ � ����');
    $8E: Result := _('������� ���� ����');
    $8F: Result := _('����� �� ���������������');
    $90: Result := _('���� ��������� ������ ������������� � ����������');
    $91: Result := _('����� �� ������� ���� ������ ��� ������ ���������� ������');
    $92: Result := _('��������� �����');
    $93: Result := _('�������������� ��� ������ �������');
    $94: Result := _('�������� ����� �������� � ����');
    $95: Result := _('����������� ������ ����');
    $A0: Result := _('������ ����� � ����');
    $A1: Result := _('���� �����������');
    $A2: Result := _('����: ������������ ������ ��� �������� �������');
    $A3: Result := _('������������ ��������� ����');
    $A4: Result := _('������ ����');
    $A5: Result := _('������ �� � ������� ����');
    $A6: Result := _('�������� ��������� ������ ����');
    $A7: Result := _('���� �����������');
    $A8: Result := _('����: �������� ���� ��� �����');
    $A9: Result := _('����: ��� ����������� ������');
    $AA: Result := _('������������ ���� (������������� ���� ���������)');
    $AB: Result := _('��������� ���������� ������� ���������� ���������� �����������');
    $AC: Result := _('�������� ��� ���������� �����������');
    $AD: Result := _('����������� ������ ��������� ����� ���');
    $AE: Result := _('����������� ������ ���');
    $AF: Result := _('����������� ������ ����� ��������� �����');
    $B0: Result := _('����: ������������ � ��������� ����������');
    $B1: Result := _('����: ������������ � ��������� �����');
    $B2: Result := _('����: ��� ��������������');
    $B3: Result := _('����������� ������� ���� � �����');

    $C0: Result := _('�������� ���� � ������� (����������� ���� � �����)');
    $C1: Result := _('����: �������� ����� � �������� �������� ������');
    $C2: Result := _('���������� ���������� ����� �������');
    $C3: Result := _('������������ ������ ���� � ����');
    $C4: Result := _('������������ ������� ����');
    $C5: Result := _('����� ����������� ��������� ����');
    $C6: Result := _('���������� �������� �����������');
    $C7: Result := _('���� �� ������������� � ������ ������');
    $C8: Result := _('������ ����� � ���������');
    $C9: Result := _('�������� ���������� �������');
    $CA: Result := _('����������� ��� ������� ������������');
    $CB: Result := _('������������ �������� ��������� ������');

    $D0: Result := _('�� ����������� ����������� ����� �� ����� �� ����');
    $D1: Result := _('��� ������ � ������');
    $D2: Result := _('����� �� ��������');
    $D3: Result := _('�� �� ����� ���� �����������, ������ ������� GS1');
    $D4: Result := _('��� ���������� ���������������');
    $D5: Result := _('������ ��������������');

    $E0: Result := _('������ ����� � ����������������');
    $E1: Result := _('�������������� �����');
    $E2: Result := _('���� ���� �� ������������� ����� ���������������');
    $E3: Result := _('������ ���������������');
    $E4: Result := _('���� ��������������� �� �������');

    $F0: Result := _('������ �������� � ��');
    $F1: Result := _('������ ������ �� ��');
    $F2: Result := _('����� ������� ������');
    $F3: Result := _('������������ ������');
    $F4: Result := _('��� ����������� �����');
    $F5: Result := _('������������ ����� ������');
  else
    Result := _('����������� ������');
  end;
end;

function GetErrorTextFM(Code: Integer): WideString;
begin
  Result := GetErrorText2Rus(Code);
end;

function GetErrorTextFS(Code: Integer): WideString;
begin
  Result := GetErrorText2Rus(Code);
  Result := FSGetErrorTextRus(Code, Result);
end;


function GetErrorText(Code: Integer; IsFSInstalled: Boolean): WideString;
begin
  if IsFSInstalled then
    Result := GetErrorTextFS(Code)
  else
    Result := GetErrorTextFM(Code);
end;


function GetAdvancedModeDescription(Value: Integer): WideString;
begin
  case Value of
    0: Result := _('Paper presented');
    1: Result := _('Passive parer absence');
    2: Result := _('Active paper absence');
    3: Result := _('After active paper absence');
    4: Result := _('Long report printing stage');
    5: Result := _('Operation printing stage');
  else
    Result := Tnt_WideFormat(_('Unknown device submode (%d)'), [Value]);
  end;
end;

function GetDeviceCodeDescription(Value: Integer): WideString;
begin
  case Value of
    1: Result := _('FM1 accumulator');
    2: Result := _('FM2 accumulator');
    3: Result := _('Clock');
    4: Result := _('VNRAM');
    5: Result := _('FM processor');
    6: Result := _('ECR software memory');
    7: Result := _('ECR RAM');
  else
    Result := Tnt_WideFormat(_('Unknown device code (%d)'), [Value]);
  end;
end;

function GetModeDescription(Value: Integer): WideString;
begin
  case Value of
    $01: Result := _('Data dumping');
    $02: Result := _('Opened day. 24 hours is not over');
    $03: Result := _('Opeded day. 24 hours is over');
    $04: Result := _('Closed day');
    $05: Result := _('Blocking by wrong tax password');
    $06: Result := _('Waiting for date confirm');
    $07: Result := _('Permission to change decimal point position');
    $08: Result := _('Opened document: Sale');
    $09: Result := _('Technological reset  permission mode');
    $0A: Result := _('Test passing');
    $0B: Result := _('Full report printing');
    $0C: Result := _('EJ report printing');
    $0D: Result := _('Sales slip opened');
    $0E: Result := _('Waiting for slip charge');
    $0F: Result := _('Slip is formed');
    $18: Result := _('Opened document: Buy');
    $1D: Result := _('Opened buy slip');
    $1E: Result := _('Slip loanding and positioning');
    $28: Result := _('Opened document: sale return');
    $2D: Result := _('Opened sale return slip');
    $2E: Result := _('Slip positioning');
    $38: Result := _('Opened document: buy return');
    $3D: Result := _('Opened buy return slip');
    $3E: Result := _('Slip printing');
    $4C: Result := _('Slip printing is finished');
    $5E: Result := _('Slip eject');
    $6E: Result := _('Waiting for slip eject');
  else
    Result := Tnt_WideFormat(_('Unknown mode: %d'), [Value]);
  end;
end;

{ Get command name }

function GetCommandName(Command: Integer): WideString;
begin
  case Command of
    $01: Result := _('Start read dump');
    $02: Result := _('Read dump block');
    $03: Result := _('Stop read dump');
    $0D: Result := _('Fiscalization/refiscalization with long ECRRN');
    $0E: Result := _('Write long serial number');
    $0F: Result := _('Read long serial number and long ECRRN');
    $10: Result := _('Read short ECR status');
    $11: Result := _('Read long ECR status');
    $12: Result := _('Print bold WideString');
    $13: Result := _('Beep');
    $14: Result := _('Write communication parameters');
    $15: Result := _('Read communication parameters');
    $16: Result := _('Technological reset');
    $17: Result := _('Print WideString');
    $18: Result := _('Print document header');
    $19: Result := _('Test run');
    $1A: Result := _('Read cash totalizer value');
    $1B: Result := _('Read operation totalizer value');
    $1C: Result := _('Write license');
    $1D: Result := _('Read license');
    $1E: Result := _('Write table');
    $1F: Result := _('Read table');
    $20: Result := _('Write decimal point position');
    $21: Result := _('Write time');
    $22: Result := _('Write date');
    $23: Result := _('Confirm date');
    $24: Result := _('Initialize tables with default values');
    $25: Result := _('Cut receipt');
    $26: Result := _('Read font parameters');
    $27: Result := _('Common clear');
    $28: Result := _('Open cash drawer');
    $29: Result := _('Feed');
    $2A: Result := _('Eject slip');
    $2B: Result := _('Interrupt test');
    $2C: Result := _('Print operation totalizers report');
    $2D: Result := _('Read table structure');
    $2E: Result := _('Read field structure');
    $2F: Result := _('Print WideString with font');
    $40: Result := _('Daily report without cleaning');
    $41: Result := _('Daily report with cleaning');
    $42: Result := _('Print Department report');
    $43: Result := _('Print tax report');
    $4D: Result := _('Print graphics 512');
    $4E: Result := _('Load graphics 512');
    $4F: Result := _('Print scaled graphics');
    $50: Result := _('Cash in');
    $51: Result := _('Cash out');
    $52: Result := _('Print fixed document header');
    $53: Result := _('Print document footer');
    $54: Result := _('Print trailer');
    $60: Result := _('Write serial number');
    $61: Result := _('Initialize FM');
    $62: Result := _('Read FM totals');
    $63: Result := _('Read last FM record date');
    $64: Result := _('Read dates and sessions range');
    $65: Result := _('Fiscalization/refiscalization');
    $66: Result := _('Fiscal report in dates range');
    $67: Result := _('Fiscal report in days range');
    $68: Result := _('Interrupt full report');
    $69: Result := _('Read fiscalization parameters');
    $70: Result := _('Open fiscal slip');
    $71: Result := _('Open standard fiscal slip');
    $72: Result := _('Transaction on slip');
    $73: Result := _('Standard transaction on slip');
    $74: Result := _('Discount/charge on slip');
    $75: Result := _('Standard discount/charge on slip');
    $76: Result := _('Close fiscal slip');
    $77: Result := _('Close standard fiscal slip');
    $78: Result := _('Slip configuration');
    $79: Result := _('Standard slip configuration');
    $7A: Result := _('Fill slip buffer with nonfiscal information');
    $7B: Result := _('Clear slip buffer line');
    $7C: Result := _('Clear slip buffer');
    $7D: Result := _('Print slip');
    $7E: Result := _('Common slip configuration');
    $80: Result := _('Sale');
    $81: Result := _('Buy');
    $82: Result := _('Sale refund');
    $83: Result := _('Buy refund');
    $84: Result := _('Void transaction');
    $85: Result := _('Close receipt');
    $86: Result := _('Discount');
    $87: Result := _('Charge');
    $88: Result := _('Cancel receipt');
    $89: Result := _('Receipt subtotal');
    $8A: Result := _('Void discount');
    $8B: Result := _('Void charge');
    $8C: Result := _('Print last receipt duplicate');
    $8D: Result := _('Open receipt');
    $90: Result := _('Oil products sale receipt in defined dose pre-payment mode');
    $91: Result := _('Oil products sale receipt in defined sum pre-payment mode');
    $92: Result := _('Correction receipt on incomplete oil-products sale');
    $93: Result := _('Write fuel-dispensing unit dose in milliliters');
    $94: Result := _('Write fuel-dispensing unit dose in cash units');
    $95: Result := _('Oil products sale');
    $96: Result := _('Stop fuel-dispensing unit');
    $97: Result := _('Start fuel-dispensing unit');
    $98: Result := _('Reset fuel-dispensing unit');
    $99: Result := _('Reset all fuel-dispensing units');
    $9A: Result := _('Write fuel-dispensing unit parameters');
    $9B: Result := _('Read liter totals counter');
    $9E: Result := _('Read current fuel-dispensing unit dose');
    $9F: Result := _('Read fuel-dispensing unit status');
    $A0: Result := _('EJ department report in dates range');
    $A1: Result := _('EJ department report in days range');
    $A2: Result := _('EJ day report in dates range');
    $A3: Result := _('EJ day report in days range');
    $A4: Result := _('Print day totals by EJ day number');
    $A5: Result := _('Print pay document from EJ by KPK number');
    $A6: Result := _('Print EJ journal by day number');
    $A7: Result := _('Interrupt full EJ report');
    $A8: Result := _('Print EJ activization result');
    $A9: Result := _('EJ activization');
    $AA: Result := _('Close EJ archive');
    $AB: Result := _('Read EJ serial number');
    $AC: Result := _('Interrupt EJ');
    $AD: Result := _('Read EJ status by code 1');
    $AE: Result := _('Read EJ status by code 2');
    $AF: Result := _('Test EJ integrity');
    $B0: Result := _('Continue printing');
    $B1: Result := _('Read EJ version');
    $B2: Result := _('Initialize EJ');
    $B3: Result := _('Read EJ report data');
    $B4: Result := _('Read EJ journal');
    $B5: Result := _('Read EJ document');
    $B6: Result := _('Read department EJ report in dates range');
    $B7: Result := _('Read EJ department report in days range');
    $B8: Result := _('Read EJ day report in dates range');
    $B9: Result := _('Read EJ day report in days range');
    $BA: Result := _('Read EJ day totals by day number');
    $BB: Result := _('Read EJ activization result');
    $BC: Result := _('Read EJ error');
    $C0: Result := _('Load graphics');
    $C1: Result := _('Print graphics');
    $C2: Result := _('Print barcode');
    $C3: Result := _('Print exteneded graphics');
    $C4: Result := _('Load extended graphics');
    $C5: Result := _('Print line');
    $C8: Result := _('Read line count in printing buffer');
    $C9: Result := _('Read line from printing buffer');
    $CA: Result := _('Clear printing buffer');
    $D0: Result := _('Read ECR IBM status');
    $D1: Result := _('Read short ECR IBM status');
    $DE: Result := _('Print barcode 2D');
    $E0: Result := _('Open fiscal day');
    $F0: Result := _('Change shutter position');
    $F1: Result := _('Discharge receipt from presenter');
    $F3: Result := _('Write service center password');
    $FC: Result := _('Read device type');
    $FD: Result := _('Send commands to external device port');
    $E1: Result := _('Finish slip');
    $E2: Result := _('Close nonfiscal document');
    $E4: Result := _('Print attribute');
    $FF01: Result := _('FS: Read status');
    $FF02: Result := _('FS: Read number');
    $FF03: Result := _('FS: Read expiration time');
    $FF04: Result := _('FS: Read version');
    $FF05: Result := _('FS: Start activation');
    $FF06: Result := _('FS: Do activation');
    $FF07: Result := _('FS: Clear status');
    $FF08: Result := _('FS: Void document');
    $FF09: Result := _('FS: Read activation result');
    $FF0A: Result := _('FS: Find document by number');
    $FF0B: Result := _('FS: Open day');
    $FF0C: Result := _('FS: Send TLV data');
    $FF0D: Result := _('FS: Registration with discount/charge');
    $FF0E: Result := _('FS: Read open parameter');
    $FF30: Result := _('FS: Read data in buffer');
    $FF31: Result := _('FS: Read data block from buffer');
    $FF32: Result := _('FS: Start write buffer');
    $FF33: Result := _('FS: Write data block in buffer');
    $FF34: Result := _('FS: Create fiscalization report');
    $FF35: Result := _('FS: Start correction receipt');
    $FF36: Result := _('FS: Create correction receipt');
    $FF37: Result := _('FS: Start report on calculations');
    $FF38: Result := _('FS: Create report on calculations');
    $FF39: Result := _('FS: Read data transfer status');
    $FF3A: Result := _('FS: Read fiscal document in TLV format');
    $FF3B: Result := _('FS: Read fiscal document TLV');
    $FF3C: Result := _('FS: Read server ticket on document number');
    $FF3D: Result := _('FS: Start close fiscal mode');
    $FF3E: Result := _('FS: Close fiscal mode');
    $FF3F: Result := _('FS: Read fiscal documents count without server ticket');
    $FF40: Result := _('FS: Read fiscal day parameters');
    $FF41: Result := _('FS: Start opening fiscal day');
    $FF42: Result := _('FS: Start closing fiscal day');
    $FF43: Result := _('FS: Close day');
    $FF44: Result := _('FS: Registration with discount/charge 2');
    $FF45: Result := _('FS: Close receipt extended');
    $FF46: Result := _('FS: Operation V2');
    $FF47: Result := _('FS: Extended FFS requisite');
    $FF48: Result := _('FS: Discount and charge');
    $FF49: Result := _('FS: Send item mark code');
    $FF4A: Result := _('FS: Send correction receipt');
    $FF4B: Result := _('FS: Print receipt discount');
    $FF4C: Result := _('FS: Read fiscalization totals');
    $FF4D: Result := _('FS: Send TLV structure');
    $FF4E: Result := _('FS: Write firmware block on SD card');
    $FF50: Result := _('FS: Online payment');
    $FF51: Result := _('FS: Read online payment status');
    $FF52: Result := _('FS: Read online payment parameter');
    $FF60: Result := _('FS: Read fiscalization parameter');
    $FF61: Result := _('FS: Check item marking');
    $FF62: Result := _('FS: Synchronize registers with FS counters');
    $FF63: Result := _('FS: Read FS free memory');
    $FF64: Result := _('FS: Write TLV from buffer');
    $FF65: Result := _('FS: Read random sequence');
    $FF66: Result := _('FS: Authorize');
    $FF67: Result := _('FS: Bind marked item');
    $FF68: Result := _('FS: Read status of AS "SKZM server"');
    $FF69: Result := _('FS: Accept or reject item marking code');
  else
    Result := _('');
  end;
end;

function GetCashRegisterName(Value: Integer): WideString;
begin
  case Value of
    0: Result := _('Sales accumulation in 1 department in receipt');
    1: Result := _('Buys accumulation in 1 department in receipt');
    2: Result := _('Sales refund accumulation in 1 department in receipt');
    3: Result := _('Buys refund accumulation in 1 department in receipt');
    4: Result := _('Sales accumulation in 2 department in receipt');
    5: Result := _('Buys accumulation in 2 department in receipt');
    6: Result := _('Sales refund accumulation in 2 department in receipt');
    7: Result := _('Buys refund accumulation in 2 department in receipt');
    8: Result := _('Sales accumulation in 3 department in receipt');
    9: Result := _('Buys accumulation in 3 department in receipt');
    10: Result := _('Sales refund accumulation in 3 department in receipt');
    11: Result := _('Buys refund accumulation in 3 department in receipt');
    12: Result := _('Sales accumulation in 4 department in receipt');
    13: Result := _('Buys accumulation in 4 department in receipt');
    14: Result := _('Sales refund accumulation in 4 department in receipt');
    15: Result := _('Buys refund accumulation in 4 department in receipt');
    16: Result := _('Sales accumulation in 5 department in receipt');
    17: Result := _('Buys accumulation in 5 department in receipt');
    18: Result := _('Sales refund accumulation in 5 department in receipt');
    19: Result := _('Buys refund accumulation in 5 department in receipt');
    20: Result := _('Sales accumulation in 6 department in receipt');
    21: Result := _('Buys accumulation in 6 department in receipt');
    22: Result := _('Sales refund accumulation in 6 department in receipt');
    23: Result := _('Buys refund accumulation in 6 department in receipt');
    24: Result := _('Sales accumulation in 7 department in receipt');
    25: Result := _('Buys accumulation in 7 department in receipt');
    26: Result := _('Sales refund accumulation in 7 department in receipt');
    27: Result := _('Buys refund accumulation in 7 department in receipt');
    28: Result := _('Sales accumulation in 8 department in receipt');
    29: Result := _('Buys accumulation in 8 department in receipt');
    30: Result := _('Sales refund accumulation in 8 department in receipt');
    31: Result := _('Buys refund accumulation in 8 department in receipt');
    32: Result := _('Sales accumulation in 9 department in receipt');
    33: Result := _('Buys accumulation in 9 department in receipt');
    34: Result := _('Sales refund accumulation in 9 department in receipt');
    35: Result := _('Buys refund accumulation in 9 department in receipt');
    36: Result := _('Sales accumulation in 10 department in receipt');
    37: Result := _('Buys accumulation in 10 department in receipt');
    38: Result := _('Sales refund accumulation in 10 department in receipt');
    39: Result := _('Buys refund accumulation in 10 department in receipt');
    40: Result := _('Sales accumulation in 11 department in receipt');
    41: Result := _('Buys accumulation in 11 department in receipt');
    42: Result := _('Sales refund accumulation in 11 department in receipt');
    43: Result := _('Buys refund accumulation in 11 department in receipt');
    44: Result := _('Sales accumulation in 12 department in receipt');
    45: Result := _('Buys accumulation in 12 department in receipt');
    46: Result := _('Sales refund accumulation in 12 department in receipt');
    47: Result := _('Buys refund accumulation in 12 department in receipt');
    48: Result := _('Sales accumulation in 13 department in receipt');
    49: Result := _('Buys accumulation in 13 department in receipt');
    50: Result := _('Sales refund accumulation in 13 department in receipt');
    51: Result := _('Buys refund accumulation in 13 department in receipt');
    52: Result := _('Sales accumulation in 14 department in receipt');
    53: Result := _('Buys accumulation in 14 department in receipt');
    54: Result := _('Sales refund accumulation in 14 department in receipt');
    55: Result := _('Buys refund accumulation in 14 department in receipt');
    56: Result := _('Sales accumulation in 15 department in receipt');
    57: Result := _('Buys accumulation in 15 department in receipt');
    58: Result := _('Sales refund accumulation in 15 department in receipt');
    59: Result := _('Buys refund accumulation in 15 department in receipt');
    60: Result := _('Sales accumulation in 16 department in receipt');
    61: Result := _('Buys accumulation in 16 department in receipt');
    62: Result := _('Sales refund accumulation in 16 department in receipt');
    63: Result := _('Buys refund accumulation in 16 department in receipt');
    64: Result := _('Discounts accumulation from sales in receipt');
    65: Result := _('Discounts accumulation from buys in receipt');
    66: Result := _('Discounts accumulation from sale refunds in receipt');
    67: Result := _('Discounts accumulation from buy refunds in receipt');
    68: Result := _('Charges accumulation on sales in receipt');
    69: Result := _('Charges accumulation on buys in receipt');
    70: Result := _('Charges accumulation on sale refunds in receipt');
    71: Result := _('Charges accumulation on buy refunds in receipt');
    72: Result := _('Cash payment accumulation of sales in receipt');
    73: Result := _('Cash payment accumulation of buys in receipt');
    74: Result := _('Cash payment accumulation of sale refunds in receipt');
    75: Result := _('Cash payment accumulation of buy refunds in receipt');
    76: Result := _('Payment type 2 accumulation of sales in receipt');
    77: Result := _('Payment type 2 accumulation of buys in receipt');
    78: Result := _('Payment type 2 accumulation of sale refunds in receipt');
    79: Result := _('Payment type 2 accumulation of buy refunds in receipt');
    80: Result := _('Payment type 3 accumulation of sales in receipt');
    81: Result := _('Payment type 3 accumulation of buys in receipt');
    82: Result := _('Payment type 3 accumulation of sale refunds in receipt');
    83: Result := _('Payment type 3 accumulation of buy refunds in receipt');
    84: Result := _('Payment type 4 accumulation of sales in receipt');
    85: Result := _('Payment type 4 accumulation of buys in receipt');
    86: Result := _('Payment type 4 accumulation of sale refunds in receipt');
    87: Result := _('Payment type 4 accumulation of buy refunds in receipt');
    88: Result := _('Tax A turnover of sales in receipt');
    89: Result := _('Tax A turnover of buys in receipt');
    90: Result := _('Tax A turnover of sale refunds in receipt');
    91: Result := _('Tax A turnover of buy refunds in receipt');
    92: Result := _('Tax B turnover of sales in receipt');
    93: Result := _('Tax B turnover of buys in receipt');
    94: Result := _('Tax B turnover of sale refunds in receipt');
    95: Result := _('Tax B turnover of buy refunds in receipt');
    96: Result := _('Tax C turnover of sales in receipt');
    97: Result := _('Tax C turnover of buys in receipt');
    98: Result := _('Tax C turnover of sale refunds in receipt');
    99: Result := _('Tax C turnover of buy refunds in receipt');
    100: Result := _('Tax D turnover of sales in receipt');
    101: Result := _('Tax D turnover of buys in receipt');
    102: Result := _('Tax D turnover of sale refunds in receipt');
    103: Result := _('Tax D turnover of buy refunds in receipt in receipt');
    104: Result := _('Tax A accumulations of sales in receipt');
    105: Result := _('Tax A accumulations of buys in receipt');
    106: Result := _('Tax A accumulations of sale refunds in receipt');
    107: Result := _('Tax A accumulations of buy refunds in receipt');
    108: Result := _('Tax B accumulations of sales in receipt');
    109: Result := _('Tax B accumulations of buys in receipt');
    110: Result := _('Tax B accumulations of sale refunds in receipt');
    111: Result := _('Tax B accumulations of buy refunds in receipt');
    112: Result := _('Tax C accumulations of sales in receipt');
    113: Result := _('Tax C accumulations of buys in receipt');
    114: Result := _('Tax C accumulations of sale refunds in receipt');
    115: Result := _('Tax C accumulations of buy refunds in receipt');
    116: Result := _('Tax D accumulations of sales in receipt');
    117: Result := _('Tax D accumulations of buys in receipt');
    118: Result := _('Tax D accumulations of sale refunds in receipt');
    119: Result := _('Tax D accumulations of buy refunds in receipt');
    120: Result := _('Cash total in ECR at receipt closing moment');
    121: Result := _('Sales accumulation in 1 department in day');
    122: Result := _('Buys accumulation in 1 department in day');
    123: Result := _('Sales refund accumulation in 1 department in day');
    124: Result := _('Buys refund accumulation in 1 department in day');
    125: Result := _('Sales accumulation in 2 department in day');
    126: Result := _('Buys accumulation in 2 department in day');
    127: Result := _('Sales refund accumulation in 2 department in day');
    128: Result := _('Buys refund accumulation in 2 department in day');
    129: Result := _('Sales accumulation in 3 department in day');
    130: Result := _('Buys accumulation in 3 department in day');
    131: Result := _('Sales refund accumulation in 3 department in day');
    132: Result := _('Buys refund accumulation in 3 department in day');
    133: Result := _('Sales accumulation in 4 department in day');
    134: Result := _('Buys accumulation in 4 department in day');
    135: Result := _('Sales refund accumulation in 4 department in day');
    136: Result := _('Buys refund accumulation in 4 department in day');
    137: Result := _('Sales accumulation in 5 department in day');
    138: Result := _('Buys accumulation in 5 department in day');
    139: Result := _('Sales refund accumulation in 5 department in day');
    140: Result := _('Buys refund accumulation in 5 department in day');
    141: Result := _('Sales accumulation in 6 department in day');
    142: Result := _('Buys accumulation in 6 department in day');
    143: Result := _('Sales refund accumulation in 6 department in day');
    144: Result := _('Buys refund accumulation in 6 department in day');
    145: Result := _('Sales accumulation in 7 department in day');
    146: Result := _('Buys accumulation in 7 department in day');
    147: Result := _('Sales refund accumulation in 7 department in day');
    148: Result := _('Buys refund accumulation in 7 department in day');
    149: Result := _('Sales accumulation in 8 department in day');
    150: Result := _('Buys accumulation in 8 department in day');
    151: Result := _('Sales refund accumulation in 8 department in day');
    152: Result := _('Buys refund accumulation in 8 department in day');
    153: Result := _('Sales accumulation in 9 department in day');
    154: Result := _('Buys accumulation in 9 department in day');
    155: Result := _('Sales refund accumulation in 9 department in day');
    156: Result := _('Buys refund accumulation in 9 department in day');
    157: Result := _('Sales accumulation in 10 department in day');
    158: Result := _('Buys accumulation in 10 department in day');
    159: Result := _('Sales refund accumulation in 10 department in day');
    160: Result := _('Buys refund accumulation in 10 department in day');
    161: Result := _('Sales accumulation in 11 department in day');
    162: Result := _('Buys accumulation in 11 department in day');
    163: Result := _('Sales refund accumulation in 11 department in day');
    164: Result := _('Buys refund accumulation in 11 department in day');
    165: Result := _('Sales accumulation in 12 department in day');
    166: Result := _('Buys accumulation in 12 department in day');
    167: Result := _('Sales refund accumulation in 12 department in day');
    168: Result := _('Buys refund accumulation in 12 department in day');
    169: Result := _('Sales accumulation in 13 department in receipt');
    170: Result := _('Buys accumulation in 13 department in receipt');
    171: Result := _('Sales refund accumulation in 13 department in receipt');
    172: Result := _('Buys refund accumulation in 13 department in receipt');
    173: Result := _('Sales accumulation in 14 department in day');
    174: Result := _('Buys accumulation in 14 department in day');
    175: Result := _('Sales refund accumulation in 14 department in day');
    176: Result := _('Buys refund accumulation in 14 department in day');
    177: Result := _('Sales accumulation in 15 department in day');
    178: Result := _('Buys accumulation in 15 department in day');
    179: Result := _('Sales refund accumulation in 15 department in day');
    180: Result := _('Buys refund accumulation in 15 department in day');
    181: Result := _('Sales accumulation in 16 department in day');
    182: Result := _('Buys accumulation in 16 department in day');
    183: Result := _('Sales refund accumulation in 16 department in day');
    184: Result := _('Buys refund accumulation in 16 department in day');
    185: Result := _('Discounts accumulation on sales in day');
    186: Result := _('Discounts accumulation on buys in day');
    187: Result := _('Discounts accumulation on sale refunds in day');
    188: Result := _('Discounts accumulation on buy refunds in day');
    189: Result := _('Charges accumulation on sales in day');
    190: Result := _('Charges accumulation on buys in day');
    191: Result := _('Charges accumulation on sale refunds in day');
    192: Result := _('Charges accumulation on buy refunds in day');
    193: Result := _('Cash payment accumulation of sales in day');
    194: Result := _('Cash payment accumulation of buys in day');
    195: Result := _('Cash payment accumulation of sale refunds day');
    196: Result := _('Cash payment accumulation of buy refunds in day');
    197: Result := _('Payment type 2 accumulation of sales in day');
    198: Result := _('Payment type 2 accumulation of buys in day');
    199: Result := _('Payment type 2 accumulation of sale refunds in day');
    200: Result := _('Payment type 2 accumulation of buy refunds in day');
    201: Result := _('Payment type 3 accumulation of sales in day');
    202: Result := _('Payment type 3 accumulation of buys in day');
    203: Result := _('Payment type 3 accumulation of sale refunds in day');
    204: Result := _('Payment type 3 accumulation of buy refunds in day');
    205: Result := _('Payment type 4 accumulation of sales in day');
    206: Result := _('Payment type 4 accumulation of buys in day');
    207: Result := _('Payment type 4 accumulation of sale refunds in day');
    208: Result := _('Payment type 4 accumulation of buy refunds in day');
    209: Result := _('Tax A turnover of sales in day');
    210: Result := _('Tax A turnover of buys in day');
    211: Result := _('Tax A turnover of sale refunds in day');
    212: Result := _('Tax A turnover of buy refunds in day');
    213: Result := _('Tax B turnover of sales in day');
    214: Result := _('Tax B turnover of buys in day');
    215: Result := _('Tax B turnover of sale refunds in day');
    216: Result := _('Tax B turnover of buy refunds in day');
    217: Result := _('Tax C turnover of sales in day');
    218: Result := _('Tax C turnover of buys in day');
    219: Result := _('Tax C turnover of sale refunds in day');
    220: Result := _('Tax C turnover of buy refunds in day');
    221: Result := _('Tax D turnover of sales in day');
    222: Result := _('Tax D turnover of buys in day');
    223: Result := _('Tax D turnover of sale refunds in day');
    224: Result := _('Tax D turnover of buy refunds in day');
    225: Result := _('Tax A accumulations of sales in day');
    226: Result := _('Tax A accumulations of buys in day');
    227: Result := _('Tax A accumulations of sale refunds in day');
    228: Result := _('Tax A accumulations of buy refunds in day');
    229: Result := _('Tax B accumulations of sales in day');
    230: Result := _('Tax B accumulations of buys in day');
    231: Result := _('Tax B accumulations of sale refunds in day');
    232: Result := _('Tax B accumulations of buy refunds in day');
    233: Result := _('Tax C accumulations of sales in day');
    234: Result := _('Tax C accumulations of buys in day');
    235: Result := _('Tax C accumulations of sale refunds in day');
    236: Result := _('Tax C accumulations of buy refunds in day');
    237: Result := _('Tax D accumulations of sales in day');
    238: Result := _('Tax D accumulations of buys in day');
    239: Result := _('Tax D accumulations of sale refunds in day');
    240: Result := _('Tax D accumulations of buy refunds in day');
    241: Result := _('Cash total in ECR accumulation');
    242: Result := _('Cash in accumulation in day');
    243: Result := _('Cash out accumulation in day');
    244: Result := _('Non-zeroise sum before fiscalization');
    245: Result := _('Sales total in day from EJ');
    246: Result := _('Buys total in day from EJ');
    247: Result := _('Sale refunds total in day from EJ');
    248: Result := _('buy refunds total in day from EJ');
  else
    Result := '';
  end;
end;

const
  EngOperRegNames: array [0..185] of WideString = (
    'Sales quantity in department 1 in receipt',
    'Buy quantity in department 1 in receipt',
    'Sales return quantity in department 1 in receipt',
    'Buy return quantity in department 1 in receipt',
    'Sales quantity in department 2 in receipt',
    'Buy quantity in department 2 in receipt',
    'Sales return quantity in department 2 in receipt',
    'Buy return quantity in department 2 in receipt',
    'Sales quantity in department 3 in receipt',
    'Buy quantity in department 3 in receipt',
    'Sales return quantity in department 3 in receipt',
    'Buy return quantity in department 3 in receipt',
    'Sales quantity in department 4 in receipt',
    'Buy quantity in department 4 in receipt',
    'Sales return quantity in department 4 in receipt',
    'Buy return quantity in department 4 in receipt',
    'Sales quantity in department 5 in receipt',
    'Buy quantity in department 5 in receipt',
    'Sales return quantity in department 5 in receipt',
    'Buy return quantity in department 5 in receipt',
    'Sales quantity in department 6 in receipt',
    'Buy quantity in department 6 in receipt',
    'Sales return quantity in department 6 in receipt',
    'Buy return quantity in department 6 in receipt',
    'Sales quantity in department 7 in receipt',
    'Buy quantity in department 7 in receipt',
    'Sales return quantity in department 7 in receipt',
    'Buy return quantity in department 7 in receipt',
    'Sales quantity in department 8 in receipt',
    'Buy quantity in department 8 in receipt',
    'Sales return quantity in department 8 in receipt',
    'Buy return quantity in department 8 in receipt',
    'Sales quantity in department 9 in receipt',
    'Buy quantity in department 9 in receipt',
    'Sales return quantity in department 9 in receipt',
    'Buy return quantity in department 9 in receipt',
    'Sales quantity in department 10 in receipt',
    'Buy quantity in department 10 in receipt',
    'Sales return quantity in department 10 in receipt',
    'Buy return quantity in department 10 in receipt',
    'Sales quantity in department 11 in receipt',
    'Buy quantity in department 11 in receipt',
    'Sales return quantity in department 11 in receipt',
    'Buy return quantity in department 11 in receipt',
    'Sales quantity in department 12 in receipt',
    'Buy quantity in department 12 in receipt',
    'Sales return quantity in department 12 in receipt',
    'Buy return quantity in department 12 in receipt',
    'Sales quantity in department 13 in receipt',
    'Buy quantity in department 13 in receipt',
    'Sales return quantity in department 13 in receipt',
    'Buy return quantity in department 13 in receipt',
    'Sales quantity in department 14 in receipt',
    'Buy quantity in department 14 in receipt',
    'Sales return quantity in department 14 in receipt',
    'Buy return quantity in department 14 in receipt',
    'Sales quantity in department 15 in receipt',
    'Buy quantity in department 15 in receipt',
    'Sales return quantity in department 15 in receipt',
    'Buy return quantity in department 15 in receipt',
    'Sales quantity in department 16 in receipt',
    'Buy quantity in department 16 in receipt',
    'Sales return quantity in department 16 in receipt',
    'Buy return quantity in department 16 in receipt',
    'Discount quantity on sale in receipt',
    'Discount quantity on buy in receipt',
    'Discount quantity on sale refund in receipt',
    'Discount quantity on buy refund in receipt',
    'Charge quantity on sale in receipt',
    'Charge quantity on buy in receipt',
    'Charge quantity on sale refund in receipt',
    'Charge quantity on buy refund in receipt',
    'Daily sale quantity in department 1',
    'Daily buy quantity in department 1',
    'Daily sales return quantity in department 1',
    'Daily buy return quantity in department 1',
    'Daily sale quantity in department 2',
    'Daily buy quantity in department 2',
    'Daily sales return quantity in department 2',
    'Daily buy return quantity in department 2',
    'Daily sale quantity in department 3',
    'Daily buy quantity in department 3',
    'Daily sales return quantity in department 3',
    'Daily buy return quantity in department 3',
    'Daily sale quantity in department 4',
    'Daily buy quantity in department 4',
    'Daily sales return quantity in department 4',
    'Daily buy return quantity in department 4',
    'Daily sale quantity in department 5',
    'Daily buy quantity in department 5',
    'Daily sales return quantity in department 5',
    'Daily buy return quantity in department 5',
    'Daily sale quantity in department 6',
    'Daily buy quantity in department 6',
    'Daily sales return quantity in department 6',
    'Daily buy return quantity in department 6',
    'Daily sale quantity in department 7',
    'Daily buy quantity in department 7',
    'Daily sales return quantity in department 7',
    'Daily buy return quantity in department 7',
    'Daily sale quantity in department 8',
    'Daily buy quantity in department 8',
    'Daily sales return quantity in department 8',
    'Daily buy return quantity in department 8',
    'Daily sale quantity in department 9',
    'Daily buy quantity in department 9',
    'Daily sales return quantity in department 9',
    'Daily buy return quantity in department 9',
    'Daily sale quantity in department 10',
    'Daily buy quantity in department 10',
    'Daily sales return quantity in department 10',
    'Daily buy return quantity in department 10',
    'Daily sale quantity in department 11',
    'Daily buy quantity in department 11',
    'Daily sales return quantity in department 11',
    'Daily buy return quantity in department 11',
    'Daily sale quantity in department 12',
    'Daily buy quantity in department 12',
    'Daily sales return quantity in department 12',
    'Daily buy return quantity in department 12',
    'Daily sale quantity in department 13',
    'Daily buy quantity in department 13',
    'Daily sales return quantity in department 13',
    'Daily buy return quantity in department 13',
    'Daily sale quantity in department 14',
    'Daily buy quantity in department 14',
    'Daily sales return quantity in department 14',
    'Daily buy return quantity in department 14',
    'Daily sale quantity in department 15',
    'Daily buy quantity in department 15',
    'Daily sales return quantity in department 15',
    'Daily buy return quantity in department 15',
    'Daily sale quantity in department 16',
    'Daily buy quantity in department 16',
    'Daily sales return quantity in department 16',
    'Daily buy return quantity in department 16',
    'Daily discount quantity on sale',
    'Daily discount quantity on buy',
    'Daily discount quantity on sale refund',
    'Daily discount quantity on buy refund',
    'Daily charge quantity on sale',
    'Daily charge quantity on buy',
    'Daily charge quantity on sale refund',
    'Daily charge quantity on buy refund',
    'Daily sale receipts quantity',
    'Daily buy receipts quantity',
    'Daily sales refund receipts quantity',
    'Daily buy refund receipts quantity',
    'Sale receipt number',
    'Buy receipt number',
    'Sale refund receipt number',
    'Buy refund receipt number',
    'Document number',
    'Daily cashin quantity',
    'Daily cashout quantity',
    'Cashin receipt number',
    'Cashout receipt number',
    'Daily voided receipt number',
    'X report number',
    'Z report number before fiscalization',
    'Total reset number',
    'Full fiscal report number',
    'Short fiscal report number',
    'Test report number',
    'Operation report number',
    'Department report number',
    'Voided receipt number',
    'Test report quantity',
    'EJ activation quantity',
    'EJ activation report quantity',
    'EJ CRC report quantity',
    'EJ jourbal report quantity',
    'EJ date report quantity',
    'EJ day report quantity',
    'EJ day totals report quantity',
    'EJ date and department report quantity',
    'EJ day and department report quantity',
    'EJ close quantity',
    'Tax report number',
    'Voided sale receipt quantity',
    'Voided buy receipt quantity',
    'Voided sale refund receipt quantity',
    'Voided buy refund receipt quantity',
    'Daily fiscal document quantity',
    'Daily nonfiscal document quantity',
    'Document number'
  );

function GetOperRegisterName(Value: Integer): WideString;
begin
  Result := '';
  if (Value >= Low(EngOperRegNames))and(Value <= High(EngOperRegNames)) then
  begin
    Result := EngOperRegNames[Value];
  end;
end;

function BaudRateToCBR(Value: TBaudRate): Integer;
begin
  case Value of
    br110: Result := CBR_110;
    br300: Result := CBR_300;
    br600: Result := CBR_600;
    br1200: Result := CBR_1200;
    br2400: Result := CBR_2400;
    br4800: Result := CBR_4800;
    br9600: Result := CBR_9600;
    br14400: Result := CBR_14400;
    br19200: Result := CBR_19200;
    br38400: Result := CBR_38400;
    br56000: Result := CBR_56000;
    br57600: Result := CBR_57600;
    br115200: Result := CBR_115200;
    br128000: Result := CBR_128000;
    br256000: Result := CBR_256000;
  else
    Result := CBR_4800;
  end;
end;

function CBRToBaudRate(Value: Integer): TBaudRate;
begin
  case Value of
    CBR_110: Result := br110;
    CBR_300: Result := br300;
    CBR_600: Result := br600;
    CBR_1200: Result := br1200;
    CBR_2400: Result := br2400;
    CBR_4800: Result := br4800;
    CBR_9600: Result := br9600;
    CBR_14400: Result := br14400;
    CBR_19200: Result := br19200;
    CBR_38400: Result := br38400;
    CBR_56000: Result := br56000;
    CBR_57600: Result := br57600;
    CBR_115200: Result := br115200;
    CBR_128000: Result := br128000;
    CBR_256000: Result := br256000;
  else
    Result := br110;
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

function GetModeText(Mode: Integer): WideString;
begin
  { !!! }
end;

function PrinterDateToDate(Date: TPrinterDate): TDateTime;
begin
  Result := EncodeDate(2000 + (Date.Year mod 100), Date.Month, Date.Day);
end;

function PrinterTimeToTime(Time: TPrinterTime): TDateTime;
begin
  Result := EncodeTime(Time.Hour, Time.Min, Time.Sec, 0);
end;

function BinToPrinterDate(const P: WideString): TPrinterDate;
begin
  Result.Year := Ord(P[1]);
  Result.Month := Ord(P[2]);
  Result.Day := Ord(P[3]);
end;

function BinToPrinterTime2(const P: WideString): TPrinterTime;
begin
  Result.Hour := Ord(P[1]);
  Result.Min := Ord(P[2]);
  Result.Sec := 0;
end;

function BinToPrinterDateTime2(const P: WideString): TPrinterDateTime;
begin
  Result.Year := Ord(P[1]);
  Result.Month := Ord(P[2]);
  Result.Day := Ord(P[3]);
  Result.Hour := Ord(P[4]);
  Result.Min := Ord(P[5]);
  Result.Sec := 0;
end;

function PrinterDateTimeToStr2(Date: TPrinterDateTime): WideString;
begin
  Result := Tnt_WideFormat('%.2d.%.2d.%.4d %.2d:%.2d', [
    Date.Day, Date.Month, Date.Year + 2000, Date.Hour, Date.Min]);
end;

function PrinterDateTimeToStr3(Date: TPrinterDateTime): WideString;
begin
  Result := Tnt_WideFormat('%.2d%.2d%.4d%.2d%.2d', [
    Date.Day, Date.Month, Date.Year + 2000, Date.Hour, Date.Min]);
end;

function PrinterTimeToStr(Time: TPrinterTime): WideString;
begin
  Result := Tnt_WideFormat('%.2d:%.2d:%.2d', [Time.Hour, Time.Min, Time.Sec]);
end;

function PrinterTimeToStr2(Time: TPrinterTime): WideString;
begin
  Result := Tnt_WideFormat('%.2d:%.2d', [Time.Hour, Time.Min]);
end;

function PrinterDateToStr(Date: TPrinterDate): WideString;
begin
  Result := Tnt_WideFormat('%.2d.%.2d.%.4d', [Date.Day, Date.Month, Date.Year + 2000]);
end;

function IsEqual(const I1, I2: TPrinterStatus): Boolean;
begin
  Result :=
    (I1.Mode = I2.Mode) and
    (I1.AdvancedMode = I2.AdvancedMode) and
    (I1.Flags.Value = I2.Flags.Value) and
    (I1.OperatorNumber = I2.OperatorNumber);
end;

function getServerResultCodeText(ServerCode: Integer): WideString;
begin
  case ServerCode of
    SMFP_SERVER_RESULT_NODATA:
      Result := _('��� ����������� � ���� ������� ����� ��� ��� ����������� � ���� ���');

    SMFP_SERVER_RESULT_BADFORMAT:
      Result := _('�� ��������� ������ ���');

    SMFP_SERVER_RESULT_FAILED:
      Result := _('����������������� �������� ����� ���� ������������� ���������');

    SMFP_SERVER_RESULT_STATUS:
      Result := _('��� ����� � ���� ������� ����� ������ �� ����������� � �������������');

    SMFP_SERVER_RESULT_ATTACHMENT:
      Result := _('� ������ �������� ���������� ������');
  else
    Result := _('����������� ��� ������');
  end;
end;

function GetCurrentPrinterDate: TPrinterDate;
var
  Year, Month, Day: Word;
begin
  DecodeDate(Date, Year, Month, Day);
  Result.Day := Day;
  Result.Month := Month;
  Result.Year := Year mod 100;
end;

function GetCurrentPrinterTime: TPrinterTime;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Time, Hour, Min, Sec, MSec);
  Result.Hour := Hour;
  Result.Min := Min;
  Result.Sec := Sec;
end;

end.
