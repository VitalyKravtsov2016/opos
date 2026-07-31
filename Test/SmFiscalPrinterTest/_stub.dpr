program RunMarkedTest;
{ CONSOLE}
uses
  SysUtils,
  TestFramework,
  TextTestRunner,
  Forms;
begin
  Application.Initialize;
  // Run all registered tests from linked units - we'll include duMarked only via full dpr copy truncated
  WriteLn('Use SmFiscalPrinterTest with filter');
end.
