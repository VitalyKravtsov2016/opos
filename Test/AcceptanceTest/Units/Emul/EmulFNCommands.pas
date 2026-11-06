unit EmulFNCommands;

interface

uses
  PrinterEmulator;

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

implementation

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

end.
