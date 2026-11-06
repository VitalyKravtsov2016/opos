unit EmulFECommands;

interface

uses
  PrinterEmulator;

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

implementation

uses
  EmulBinUtils, FptrTypes;

procedure CheckMinLength(const Data: AnsiString; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    raise EFptrError.Create2(FPTR_E_INVALID_CMD_LEN, '');
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

end.
