unit uZintInterface;

interface

uses
  Windows, SysUtils;

const
  ZINT_DLL = 'zint.dll'; // Имя DLL библиотеки Zint

  // Версия библиотеки
  ZINT_VERSION_MAJOR = 2; // Major version number
  ZINT_VERSION_MINOR = 15; // Minor version number
  ZINT_VERSION_RELEASE = 0; // Release version number

  // Максимальные длины
  ZINT_MAX_DATA_LEN = 17400; // Максимальная длина данных (для Han Xin Code)
  ZINT_MAX_SEG_COUNT = 256;  // Максимальное количество сегментов

type
  // Vector elements - see vector header `zint_vector` below
  PZintVectorRect = ^TZintVectorRect;
  TZintVectorRect = record
    x, y: Single;         // Top left
    height, width: Single; // Размеры прямоугольника
    colour: Integer;      // -1 for foreground, 1-8 for Cyan, Blue, Magenta, Red, Yellow, Green, Black, White
    next: PZintVectorRect; // Pointer to next rectangle
  end;

  PZintVectorHexagon = ^TZintVectorHexagon;
  TZintVectorHexagon = record
    x, y: Single;         // Centre
    diameter: Single;     // Short (minimal) diameter (i.e. diameter of inscribed circle)
    rotation: Integer;    // 0, 90, 180, 270 degrees, where 0 has apex at top, i.e. short diameter is horizontal
    next: PZintVectorHexagon; // Pointer to next hexagon
  end;

  PZintVectorString = ^TZintVectorString;
  TZintVectorString = record
    x, y: Single;         // x is relative to halign (i.e. centre, left, right), y is relative to baseline
    fsize: Single;        // Font size
    width: Single;        // Rendered width estimate
    length: Integer;      // Number of characters (bytes)
    rotation: Integer;    // 0, 90, 180, 270 degrees
    halign: Integer;      // Horizontal alignment: 0 for centre, 1 for left, 2 for right (end)
    text: PByte;          // UTF-8, NUL-terminated
    next: PZintVectorString; // Pointer to next string
  end;

  PZintVectorCircle = ^TZintVectorCircle;
  TZintVectorCircle = record
    x, y: Single;         // Centre
    diameter: Single;     // Circle diameter. Does not include width (if any)
    width: Single;        // Width of circle perimeter (circumference). 0 for fill (disc)
    colour: Integer;      // Zero for draw with foreground colour (else draw with background colour (legacy))
    next: PZintVectorCircle; // Pointer to next circle
  end;

  // Vector header
  PZintVector = ^TZintVector;
  TZintVector = record
    width, height: Single; // Width, height of barcode image (including text, whitespace)
    rectangles: PZintVectorRect; // Pointer to first rectangle
    hexagons: PZintVectorHexagon; // Pointer to first hexagon
    strings: PZintVectorString; // Pointer to first string
    circles: PZintVectorCircle; // Pointer to first circle
  end;

  // Structured Append info (see `symbol->structapp` below) - ignored unless `zint_structapp.count` is non-zero
  TZintStructApp = record
    index: Integer;          // Position in Structured Append sequence, 1-based. Must be <= `count`
    count: Integer;          // Number of symbols in Structured Append sequence. Set >= 2 to add SA Info
    id: array[0..31] of AnsiChar; // Optional ID to distinguish sequence, ASCII, NUL-terminated unless max 32 long
  end;

  // Segment for use with `raw_segs` and API `ZBarcode_Encode_Segs()`
  PZintSeg = ^TZintSeg;
  TZintSeg = record
    source: PByte; // Data to encode, or (`raw_segs`) data encoded
    length: Integer; // Length of `source`. If 0 or negative, `source` must be NUL-terminated
    eci: Integer;    // Extended Channel Interpretation
  end;

  // Main symbol structure
  PZintSymbol = ^TZintSymbol;
  TZintSymbol = record
    symbology: Integer;      // Symbol to use (see BARCODE_XXX below)
    height: Single;          // Barcode height in X-dimensions (ignored for fixed-width barcodes)
    scale: Single;           // Scale factor when printing barcode, i.e. adjusts X-dimension. Default 1
    whitespace_width: Integer; // Width in X-dimensions of whitespace to left & right of barcode
    whitespace_height: Integer; // Height in X-dimensions of whitespace above & below the barcode
    border_width: Integer;   // Size of border in X-dimensions
    output_options: Integer; // Various output parameters (bind, box etc, see below)
    fgcolour: array[0..15] of AnsiChar;  // Foreground as hexadecimal RGB/RGBA or decimal "C,M,Y,K" string, NUL-terminated
    bgcolour: array[0..15] of AnsiChar;  // Background as hexadecimal RGB/RGBA or decimal "C,M,Y,K" string, NUL-terminated
    fgcolor: PAnsiChar;      // Pointer to fgcolour (alternate spelling)
    bgcolor: PAnsiChar;      // Pointer to bgcolour (alternate spelling)
    outfile: array[0..255] of AnsiChar; // Name of file to output to, NUL-terminated. Default "out.png" ("out.gif" if no PNG)
    primary: array[0..127] of AnsiChar; // Primary message data (MaxiCode, Composite), NUL-terminated
    option_1: Integer;       // Symbol-specific options (see "../docs/manual.txt")
    option_2: Integer;       // Symbol-specific options
    option_3: Integer;       // Symbol-specific options
    show_hrt: Integer;       // Show (1) or hide (0) Human Readable Text (HRT). Default 1
    input_mode: Integer;     // Encoding of input data (see DATA_MODE etc below). Default DATA_MODE
    eci: Integer;            // Extended Channel Interpretation. Default 0 (none)
    dpmm: Single;            // Resolution of output in dots per mm (BMP/EMF/PCX/PNG/TIF only). Default 0 (none)
    dot_size: Single;        // Size of dots used in BARCODE_DOTTY_MODE. Default 0.8
    text_gap: Single;        // Gap between barcode and text (HRT) in X-dimensions. Default 1
    guard_descent: Single;   // Height in X-dimensions that EAN/UPC guard bars descend. Default 5
    structapp: TZintStructApp; // Structured Append info. Default structapp.count 0 (none)
    warn_level: Integer;     // Affects error/warning value returned by Zint API (see WARN_XXX below)
    debug: Integer;          // Debugging flags
    text: array[0..255] of Byte; // Human Readable Text (HRT) (if any), UTF-8, NUL-terminated (output only)
    text_length: Integer;    // Length of text in bytes (output only)
    rows: Integer;           // Number of rows used by the symbol (output only)
    width: Integer;          // Width of the generated symbol (output only)
    encoded_data: array[0..199, 0..143] of Byte; // Encoded data (output only). Allows for rows of 1152 modules
    row_height: array[0..199] of Single; // Heights of rows (output only). Allows for 200 row DotCode
    errtxt: array[0..99] of AnsiChar; // Error message if an error or warning occurs, NUL-terminated (output only)
    bitmap: PByte;           // Stored bitmap image (raster output only)
    bitmap_width: Integer;   // Width of bitmap image (raster output only)
    bitmap_height: Integer;  // Height of bitmap image (raster output only)
    alphamap: PByte;         // Array of alpha values used (raster output only)
    vector: PZintVector;     // Pointer to vector header (vector output only)
    memfile: PByte;          // Pointer to in-memory file buffer if BARCODE_MEMORY_FILE (output only)
    memfile_size: Integer;   // Length of in-memory file buffer (output only)
    raw_segs: PZintSeg;      // Pointer to array of raw segs if BARCODE_RAW_TEXT (output only)
    raw_seg_count: Integer;  // Number of `raw_segs` (output only)
  end;

// Symbologies (`symbol->symbology`)
    // Tbarcode 7 codes
const
  BARCODE_CODE11          = 1;   // Code 11
  BARCODE_C25STANDARD     = 2;   // 2 of 5 Standard (Matrix)
  BARCODE_C25MATRIX       = 2;   // Legacy
  BARCODE_C25INTER        = 3;   // 2 of 5 Interleaved
  BARCODE_C25IATA         = 4;   // 2 of 5 IATA
  BARCODE_C25LOGIC        = 6;   // 2 of 5 Data Logic
  BARCODE_C25IND          = 7;   // 2 of 5 Industrial
  BARCODE_CODE39          = 8;   // Code 39
  BARCODE_EXCODE39        = 9;   // Extended Code 39
  BARCODE_EANX            = 13;  // EAN (European Article Number)
  BARCODE_EANX_CHK        = 14;  // EAN + Check Digit
  BARCODE_GS1_128         = 16;  // GS1-128
  BARCODE_EAN128          = 16;  // Legacy
  BARCODE_CODABAR         = 18;  // Codabar
  BARCODE_CODE128         = 20;  // Code 128
  BARCODE_DPLEIT          = 21;  // Deutsche Post Leitcode
  BARCODE_DPIDENT         = 22;  // Deutsche Post Identcode
  BARCODE_CODE16K         = 23;  // Code 16k
  BARCODE_CODE49          = 24;  // Code 49
  BARCODE_CODE93          = 25;  // Code 93
  BARCODE_FLAT            = 28;  // Flattermarken
  BARCODE_DBAR_OMN        = 29;  // GS1 DataBar Omnidirectional
  BARCODE_RSS14           = 29;  // Legacy
  BARCODE_DBAR_LTD        = 30;  // GS1 DataBar Limited
  BARCODE_RSS_LTD         = 30;  // Legacy
  BARCODE_DBAR_EXP        = 31;  // GS1 DataBar Expanded
  BARCODE_RSS_EXP         = 31;  // Legacy
  BARCODE_TELEPEN         = 32;  // Telepen Alpha
  BARCODE_UPCA            = 34;  // UPC-A
  BARCODE_UPCA_CHK        = 35;  // UPC-A + Check Digit
  BARCODE_UPCE            = 37;  // UPC-E
  BARCODE_UPCE_CHK        = 38;  // UPC-E + Check Digit
  BARCODE_POSTNET         = 40;  // USPS (U.S. Postal Service) POSTNET
  BARCODE_MSI_PLESSEY     = 47;  // MSI Plessey
  BARCODE_FIM             = 49;  // Facing Identification Mark
  BARCODE_LOGMARS         = 50;  // LOGMARS
  BARCODE_PHARMA          = 51;  // Pharmacode One-Track
  BARCODE_PZN             = 52;  // Pharmazentralnummer
  BARCODE_PHARMA_TWO      = 53;  // Pharmacode Two-Track
  BARCODE_CEPNET          = 54;  // Brazilian CEPNet Postal Code
  BARCODE_PDF417          = 55;  // PDF417
  BARCODE_PDF417COMP      = 56;  // Compact PDF417 (Truncated PDF417)
  BARCODE_PDF417TRUNC     = 56;  // Legacy
  BARCODE_MAXICODE        = 57;  // MaxiCode
  BARCODE_QRCODE          = 58;  // QR Code
  BARCODE_CODE128AB       = 60;  // Code 128 (Suppress Code Set C)
  BARCODE_CODE128B        = 60;  // Legacy
  BARCODE_AUSPOST         = 63;  // Australia Post Standard Customer
  BARCODE_AUSREPLY        = 66;  // Australia Post Reply Paid
  BARCODE_AUSROUTE        = 67;  // Australia Post Routing
  BARCODE_AUSREDIRECT     = 68;  // Australia Post Redirection
  BARCODE_ISBNX           = 69;  // ISBN
  BARCODE_RM4SCC          = 70;  // Royal Mail 4-State Customer Code
  BARCODE_DATAMATRIX      = 71;  // Data Matrix (ECC200)
  BARCODE_EAN14           = 72;  // EAN-14
  BARCODE_VIN             = 73;  // Vehicle Identification Number
  BARCODE_CODABLOCKF      = 74;  // Codablock-F
  BARCODE_NVE18           = 75;  // NVE-18 (SSCC-18)
  BARCODE_JAPANPOST       = 76;  // Japanese Postal Code
  BARCODE_KOREAPOST       = 77;  // Korea Post
  BARCODE_DBAR_STK        = 79;  // GS1 DataBar Stacked
  BARCODE_RSS14STACK      = 79;  // Legacy
  BARCODE_DBAR_OMNSTK     = 80;  // GS1 DataBar Stacked Omnidirectional
  BARCODE_RSS14STACK_OMNI = 80;  // Legacy
  BARCODE_DBAR_EXPSTK     = 81;  // GS1 DataBar Expanded Stacked
  BARCODE_RSS_EXPSTACK    = 81;  // Legacy
  BARCODE_PLANET          = 82;  // USPS PLANET
  BARCODE_MICROPDF417     = 84;  // MicroPDF417
  BARCODE_USPS_IMAIL      = 85;  // USPS Intelligent Mail (OneCode)
  BARCODE_ONECODE         = 85;  // Legacy
  BARCODE_PLESSEY         = 86;  // UK Plessey

    // Tbarcode 8 codes
  BARCODE_TELEPEN_NUM     = 87;  // Telepen Numeric
  BARCODE_ITF14           = 89;  // ITF-14
  BARCODE_KIX             = 90;  // Dutch Post KIX Code
  BARCODE_AZTEC           = 92;  // Aztec Code
  BARCODE_DAFT            = 93;  // DAFT Code
  BARCODE_DPD             = 96;  // DPD Code
  BARCODE_MICROQR         = 97;  // Micro QR Code

    // Tbarcode 9 codes
  BARCODE_HIBC_128        = 98;  // HIBC (Health Industry Barcode) Code 128
  BARCODE_HIBC_39         = 99;  // HIBC Code 39
  BARCODE_HIBC_DM         = 102; // HIBC Data Matrix
  BARCODE_HIBC_QR         = 104; // HIBC QR Code
  BARCODE_HIBC_PDF        = 106; // HIBC PDF417
  BARCODE_HIBC_MICPDF     = 108; // HIBC MicroPDF417
  BARCODE_HIBC_BLOCKF     = 110; // HIBC Codablock-F
  BARCODE_HIBC_AZTEC      = 112; // HIBC Aztec Code

    // Tbarcode 10 codes
  BARCODE_DOTCODE         = 115; // DotCode
  BARCODE_HANXIN          = 116; // Han Xin (Chinese Sensible) Code

    // Tbarcode 11 codes
  BARCODE_MAILMARK_2D     = 119; // Royal Mail 2D Mailmark (CMDM) (Data Matrix)
  BARCODE_UPU_S10         = 120; // Universal Postal Union S10
  BARCODE_MAILMARK_4S     = 121; // Royal Mail 4-State Mailmark
  BARCODE_MAILMARK        = 121; // Legacy

    // Zint specific
  BARCODE_AZRUNE          = 128; // Aztec Runes
  BARCODE_CODE32          = 129; // Code 32
  BARCODE_EANX_CC         = 130; // EAN Composite
  BARCODE_GS1_128_CC      = 131; // GS1-128 Composite
  BARCODE_EAN128_CC       = 131; // Legacy
  BARCODE_DBAR_OMN_CC     = 132; // GS1 DataBar Omnidirectional Composite
  BARCODE_RSS14_CC        = 132; // Legacy
  BARCODE_DBAR_LTD_CC     = 133; // GS1 DataBar Limited Composite
  BARCODE_RSS_LTD_CC      = 133; // Legacy
  BARCODE_DBAR_EXP_CC     = 134; // GS1 DataBar Expanded Composite
  BARCODE_RSS_EXP_CC      = 134; // Legacy
  BARCODE_UPCA_CC         = 135; // UPC-A Composite
  BARCODE_UPCE_CC         = 136; // UPC-E Composite
  BARCODE_DBAR_STK_CC     = 137; // GS1 DataBar Stacked Composite
  BARCODE_RSS14STACK_CC   = 137; // Legacy
  BARCODE_DBAR_OMNSTK_CC  = 138; // GS1 DataBar Stacked Omnidirectional Composite
  BARCODE_RSS14_OMNI_CC   = 138; // Legacy
  BARCODE_DBAR_EXPSTK_CC  = 139; // GS1 DataBar Expanded Stacked Composite
  BARCODE_RSS_EXPSTACK_CC = 139; // Legacy
  BARCODE_CHANNEL         = 140; // Channel Code
  BARCODE_CODEONE         = 141; // Code One
  BARCODE_GRIDMATRIX      = 142; // Grid Matrix
  BARCODE_UPNQR           = 143; // UPNQR (Univerzalnega Placilnega Naloga QR)
  BARCODE_ULTRA           = 144; // Ultracode
  BARCODE_RMQR            = 145; // Rectangular Micro QR Code (rMQR)
  BARCODE_BC412           = 146; // IBM BC412 (SEMI T1-95)
  BARCODE_DXFILMEDGE      = 147; // DX Film Edge Barcode on 35mm and APS films
  BARCODE_LAST            = 147; // Max barcode number marker, not barcode

// Output options (`symbol->output_options`)
  BARCODE_BIND_TOP        = $00001; // Boundary bar above the symbol only (not below), does not affect stacking
                                    // Note: value was once used by the legacy (never-used) BARCODE_NO_ASCII
  BARCODE_BIND            = $00002; // Boundary bars above & below the symbol and between stacked symbols
  BARCODE_BOX             = $00004; // Box around symbol
  BARCODE_STDOUT          = $00008; // Output to stdout
  READER_INIT             = $00010; // Reader Initialisation (Programming)
  SMALL_TEXT              = $00020; // Use smaller font
  BOLD_TEXT               = $00040; // Use bold font
  CMYK_COLOUR             = $00080; // CMYK colour space (Encapsulated PostScript and TIF)
  BARCODE_DOTTY_MODE      = $00100; // Plot a matrix symbol using dots rather than squares
  GS1_GS_SEPARATOR        = $00200; // Use GS instead of FNC1 as GS1 separator (Data Matrix)
  OUT_BUFFER_INTERMEDIATE = $00400; // Return ASCII values in bitmap buffer (OUT_BUFFER only)
  BARCODE_QUIET_ZONES     = $00800; // Add compliant quiet zones (additional to any specified whitespace)
                                    // Note: CODE16K, CODE49, CODABLOCKF, ITF14, EAN/UPC have default quiet zones
  BARCODE_NO_QUIET_ZONES  = $01000; // Disable quiet zones, notably those with defaults as listed above
  COMPLIANT_HEIGHT        = $02000; // Warn if height not compliant, or use standard height (if any) as default
  EANUPC_GUARD_WHITESPACE = $04000; // Add quiet zone indicators ("<"/">") to HRT whitespace (EAN/UPC)
  EMBED_VECTOR_FONT       = $08000; // Embed font in vector output - currently only for SVG output
  BARCODE_MEMORY_FILE     = $10000; // Write output to in-memory buffer `memfile` instead of to `outfile`
  BARCODE_RAW_TEXT        = $20000; // Write data encoded to raw segment buffers `raw_segs`

// Input data types (`symbol->input_mode`)
  DATA_MODE               = 0;       // Binary
  UNICODE_MODE            = 1;       // UTF-8
  GS1_MODE                = 2;       // GS1
  // The following may be OR-ed with above
  ESCAPE_MODE             = $0008;   // Process escape sequences
  GS1PARENS_MODE          = $0010;   // Process parentheses as GS1 AI delimiters (instead of square brackets)
  GS1NOCHECK_MODE         = $0020;   // Do not check validity of GS1 data (except that printable ASCII only)
  HEIGHTPERROW_MODE       = $0040;   // Interpret `height` as per-row rather than as overall height
  FAST_MODE               = $0080;   // Use faster if less optimal encodation or other shortcuts if available
                                    // Note: affects DATAMATRIX, MICROPDF417, PDF417, QRCODE & UPNQR only
  EXTRA_ESCAPE_MODE       = $0100;   // Process special symbology-specific escape sequences as well as others
                                    // Note: currently Code 128 only
// Data Matrix specific options (`symbol->option_3`)
  DM_SQUARE               = 100;     // Only consider square versions on automatic symbol size selection
  DM_DMRE                 = 101;     // Consider DMRE versions on automatic symbol size selection
  DM_ISO_144              = 128;     // Use ISO instead of "de facto" format for 144x144 (i.e. don't skew ECC)

// QR, Han Xin, Grid Matrix specific options (`symbol->option_3`)
  ZINT_FULL_MULTIBYTE     = 200;     // Enable Kanji/Hanzi compression for Latin-1 & binary data

// Ultracode specific option (`symbol->option_3`)
  ULTRA_COMPRESSION       = 128;     // Enable Ultracode compression (experimental)

// Warning and error conditions (API return values)
  ZINT_WARN_HRT_TRUNCATED     = 1;   // Human Readable Text was truncated (max 199 bytes)
  ZINT_WARN_INVALID_OPTION    = 2;   // Invalid option given but overridden by Zint
  ZINT_WARN_USES_ECI          = 3;   // Automatic ECI inserted by Zint
  ZINT_WARN_NONCOMPLIANT      = 4;   // Symbol created not compliant with standards
  ZINT_ERROR                  = 5;   // Warn/error marker, not returned
  ZINT_ERROR_TOO_LONG         = 5;   // Input data wrong length
  ZINT_ERROR_INVALID_DATA     = 6;   // Input data incorrect
  ZINT_ERROR_INVALID_CHECK    = 7;   // Input check digit incorrect
  ZINT_ERROR_INVALID_OPTION   = 8;   // Incorrect option given
  ZINT_ERROR_ENCODING_PROBLEM = 9;   // Internal error (should not happen)
  ZINT_ERROR_FILE_ACCESS      = 10;  // Error opening output file
  ZINT_ERROR_MEMORY           = 11;  // Memory allocation (malloc) failure
  ZINT_ERROR_FILE_WRITE       = 12;  // Error writing to output file
  ZINT_ERROR_USES_ECI         = 13;  // Error counterpart of warning if WARN_FAIL_ALL set (see below)
  ZINT_ERROR_NONCOMPLIANT     = 14;  // Error counterpart of warning if WARN_FAIL_ALL set
  ZINT_ERROR_HRT_TRUNCATED    = 15;  // Error counterpart of warning if WARN_FAIL_ALL set

// Warning level (`symbol->warn_level`)
  WARN_DEFAULT            = 0;  // Default behaviour
  WARN_FAIL_ALL           = 2;  // Treat warning as error

// Capability flags (ZBarcode_Cap() `cap_flag`)
  ZINT_CAP_HRT            = $0001;  // Prints Human Readable Text?
  ZINT_CAP_STACKABLE      = $0002;  // Is stackable?
  ZINT_CAP_EANUPC         = $0004;  // Is EAN/UPC?
  ZINT_CAP_EXTENDABLE     = $0004;  // Legacy
  ZINT_CAP_COMPOSITE      = $0008;  // Can have composite data?
  ZINT_CAP_ECI            = $0010;  // Supports Extended Channel Interpretations?
  ZINT_CAP_GS1            = $0020;  // Supports GS1 data?
  ZINT_CAP_DOTTY          = $0040;  // Can be output as dots?
  ZINT_CAP_QUIET_ZONES    = $0080;  // Has default quiet zones?
  ZINT_CAP_FIXED_RATIO    = $0100;  // Has fixed width-to-height (aspect) ratio?
  ZINT_CAP_READER_INIT    = $0200;  // Supports Reader Initialisation?
  ZINT_CAP_FULL_MULTIBYTE = $0400;  // Supports full-multibyte option?
  ZINT_CAP_MASK           = $0800;  // Is mask selectable?
  ZINT_CAP_STRUCTAPP      = $1000;  // Supports Structured Append?
  ZINT_CAP_COMPLIANT_HEIGHT = $2000;  // Has compliant height?

// Debug flags (`symbol->debug`)
  ZINT_DEBUG_PRINT        = $0001;  // Print debug info (if any) to stdout
  ZINT_DEBUG_TEST         = $0002;  // For internal test use only

{ API Functions }
function ZBarcode_Create: PZintSymbol; cdecl; external ZINT_DLL;
procedure ZBarcode_Clear(symbol: PZintSymbol); cdecl; external ZINT_DLL;
procedure ZBarcode_Reset(symbol: PZintSymbol); cdecl; external ZINT_DLL;
procedure ZBarcode_Delete(symbol: PZintSymbol); cdecl; external ZINT_DLL;

function ZBarcode_Encode(symbol: PZintSymbol; source: PByte; length: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_Segs(symbol: PZintSymbol; segs: PZintSeg; seg_count: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_File(symbol: PZintSymbol; filename: PAnsiChar): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Print(symbol: PZintSymbol; rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;

function ZBarcode_Encode_and_Print(symbol: PZintSymbol; source: PByte; length, rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_Segs_and_Print(symbol: PZintSymbol; segs: PZintSeg; seg_count, rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_File_and_Print(symbol: PZintSymbol; filename: PAnsiChar; rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;

function ZBarcode_Buffer(symbol: PZintSymbol; rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_and_Buffer(symbol: PZintSymbol; source: PByte; length, rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_Segs_and_Buffer(symbol: PZintSymbol; segs: PZintSeg; seg_count, rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_File_and_Buffer(symbol: PZintSymbol; filename: PAnsiChar; rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;

function ZBarcode_Buffer_Vector(symbol: PZintSymbol; rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_and_Buffer_Vector(symbol: PZintSymbol; source: PByte; length, rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_Segs_and_Buffer_Vector(symbol: PZintSymbol; segs: PZintSeg; seg_count, rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Encode_File_and_Buffer_Vector(symbol: PZintSymbol; filename: PAnsiChar; rotate_angle: Integer): Integer; cdecl; external ZINT_DLL;

function ZBarcode_ValidID(symbol_id: Integer): Integer; cdecl; external ZINT_DLL;
function ZBarcode_BarcodeName(symbol_id: Integer; name: PAnsiChar): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Cap(symbol_id: Integer; cap_flag: Cardinal): Cardinal; cdecl; external ZINT_DLL;

function ZBarcode_Default_Xdim(symbol_id: Integer): Single; cdecl; external ZINT_DLL;
function ZBarcode_Scale_From_XdimDp(symbol_id: Integer; x_dim_mm, dpmm: Single; filetype: PAnsiChar): Single; cdecl; external ZINT_DLL;
function ZBarcode_XdimDp_From_Scale(symbol_id: Integer; scale, x_dim_mm_or_dpmm: Single; filetype: PAnsiChar): Single; cdecl; external ZINT_DLL;

function ZBarcode_UTF8_To_ECI(eci: Integer; source: PByte; length: Integer; dest: PByte; p_dest_length: PInteger): Integer; cdecl; external ZINT_DLL;
function ZBarcode_Dest_Len_ECI(eci: Integer; source: PByte; length: Integer; p_dest_length: PInteger): Integer; cdecl; external ZINT_DLL;

function ZBarcode_NoPng: Integer; cdecl; external ZINT_DLL;
function ZBarcode_Version: Integer; cdecl; external ZINT_DLL;

implementation

end.
