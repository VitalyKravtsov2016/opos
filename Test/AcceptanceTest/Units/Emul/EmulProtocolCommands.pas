unit EmulProtocolCommands;

interface

uses
  PrinterEmulator, FptrTypes;

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

implementation

uses
  SysUtils, EmulBinUtils, EmulFNCommands, EmulFECommands;

procedure CheckMinLength(const Data: AnsiString; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    raise EFptrError.Create2(FPTR_E_INVALID_CMD_LEN, '');
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

end.
