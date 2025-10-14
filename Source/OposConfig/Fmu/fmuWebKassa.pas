unit fmuWebKassa;

interface

uses
  // VCL
  StdCtrls, Controls, Classes, ComObj, SysUtils, Spin, ExtCtrls,
  // 3'd
  SynMemo, SynEdit,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  PrinterParameters, FiscalPrinterDevice, FptrTypes, DirectIOAPI;


type
  { TfmWebKassa }

  TfmWebKassa = class(TFptrPage)
    chbWebKassaEnabled: TTntCheckBox;
    procedure PageChange(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

procedure TfmWebKassa.PageChange(Sender: TObject);
begin
  Modified;
end;

procedure TfmWebKassa.UpdatePage;
begin
  chbWebKassaEnabled.Checked := Parameters.WebKassaEnabled;
end;

procedure TfmWebKassa.UpdateObject;
begin
  Parameters.WebKassaEnabled := chbWebKassaEnabled.Checked;
end;

end.

