program EmuHost;
{$APPTYPE CONSOLE}
uses
  SysUtils, Windows,
  StringUtils in '..\..\Source\Shared\StringUtils.pas',
  FiscalPrinterEmulator in '..\AcceptanceTest\Units\FiscalPrinterEmulator.pas';
var
  Emu: TFiscalPrinterEmulator;
  Flag: string;
  Kind: TFrEmulatorKind;
  Arg: string;
begin
  Kind := ekPosCenter;
  if ParamCount >= 1 then
  begin
    Arg := LowerCase(ParamStr(1));
    if (Arg = 'shtrih') or (Arg = 'internal') then
      Kind := ekShtrih
    else if (Arg = 'poscenter') or (Arg = 'pc') then
      Kind := ekPosCenter
    else if (Arg = 'torgbalance') or (Arg = 'tb') then
      Kind := ekTorgBalance
    else if (Arg = 'rr') or (Arg = 'rrelectro') then
      Kind := ekRRElectro;
  end;

  Flag := ExtractFilePath(ParamStr(0)) + 'emuhost.stop';
  if FileExists(Flag) then
    SysUtils.DeleteFile(Flag);

  Emu := CreateFrEmulator(Kind);
  try
    Emu.Start(13, 115200);
    WriteLn('Emulator ', FrEmulatorKindToName(Kind), ' on COM13');
    WriteLn('Close codes: model-specific (PosCenter FF7B, TorgBalance FF78, ...)');
    WriteLn('Stop: create ', Flag);
    while not FileExists(Flag) do
      Sleep(200);
    Emu.GetCommandLogLines.SaveToFile(ExtractFilePath(ParamStr(0)) + 'emuhost.tx');
    WriteLn('Stopped, cmds=', Emu.GetCommandLogLines.Count);
  finally
    Emu.Free;
  end;
end.
