program RunMarkedOnly2;
$APPTYPE CONSOLE
uses
  SysUtils, Forms,
  TestFramework,
  FiscalPrinterEmulator in '..\AcceptanceTest\Units\FiscalPrinterEmulator.pas',
  duMarkedReceiptDrivers in '..\AcceptanceTest\Units\duMarkedReceiptDrivers.pas';
var
  R: TTestResult;
  S: ITest;
begin
  Application.Initialize;
  S := TMarkedReceiptDriversTest.Suite;
  R := S.Run;
  WriteLn('Runs=', R.RunCount, ' Failures=', R.FailureCount, ' Errors=', R.ErrorCount);
  if Assigned(R.Failures) and (R.Failures.Count > 0) then
    WriteLn(R.Failures[0].ThrownExceptionMessage);
  if Assigned(R.Errors) and (R.Errors.Count > 0) then
    WriteLn(R.Errors[0].ThrownExceptionMessage);
  if (R.FailureCount = 0) and (R.ErrorCount = 0) then Halt(0) else Halt(1);
end.
