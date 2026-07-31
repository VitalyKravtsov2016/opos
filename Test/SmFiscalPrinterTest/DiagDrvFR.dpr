program DiagDrvFR;
{$APPTYPE CONSOLE}
uses
  SysUtils, Windows, ActiveX,
  FiscalPrinterEmulator in '..\AcceptanceTest\Units\FiscalPrinterEmulator.pas',
  StringUtils in '..\..\Source\Shared\StringUtils.pas',
  untDriver in '..\..\Source\Shared\untDriver.pas',
  DrvFRLib_TLB in '..\..\Source\Shared\DrvFRLib_TLB.pas',
  DriverError in '..\..\Source\Shared\DriverError.pas',
  BinUtils in '..\..\Source\Shared\BinUtils.pas',
  WException in '..\..\Source\Shared\WException.pas',
  gnugettext in '..\..\Source\Shared\gnugettext.pas';

var
  Emu: TFiscalPrinterEmulator;
  Drv: TDriver;
  R: Integer;
  i: Integer;
begin
  CoInitialize(nil);
  Emu := TFiscalPrinterEmulator.Create;
  try
    Emu.Start(13, 115200);
    Sleep(300);
    Drv := TDriver.Create(nil);
    try
      for i := 1 to 2 do
      begin
        WriteLn('=== Pass ', i, ' BaudMode=', i, ' ===');
        Drv.ConnectionType := 0;
        Drv.ComNumber := 12;
        if i = 1 then
          Drv.BaudRate := 6
        else
          Drv.BaudRate := 115200;
        Drv.Timeout := 1000;
        Drv.Password := 1;
        R := Drv.Connect2;
        WriteLn('Connect2=', R, ' Desc=', Drv.ResultCodeDescription,
          ' Model=', Drv.UModel, ' Name=', Drv.UDescription);
        R := Drv.GetECRStatus;
        WriteLn('GetECRStatus=', R, ' Mode=', Drv.ECRMode, ' Desc=', Drv.ResultCodeDescription);
        Drv.CheckType := 0;
        R := Drv.OpenCheck;
        WriteLn('OpenCheck=', R, ' Desc=', Drv.ResultCodeDescription);
        R := Drv.CloseCheck;
        WriteLn('CloseCheck=', R);
        Drv.Disconnect;
        WriteLn('EmuLog:');
        WriteLn(Emu.GetCommandLog);
        Emu.ClearLog;
        WriteLn;
      end;
    finally
      Drv.Free;
    end;
  finally
    Emu.Stop;
    Emu.Free;
    CoUninitialize;
  end;
end;
