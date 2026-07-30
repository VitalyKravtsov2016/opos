unit fmuFptrConnection;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Spin,
  // Tnt
  TntStdCtrls,
  // This
  untUtil, PrinterParameters, FptrTypes, PrinterModel, XmlModelReader,
  FiscalPrinterDevice, FileUtils, PrinterTypes, DriverTypes;

type
  { TfmFptrConnection }

  TfmFptrConnection = class(TFptrPage)
    gbConenction: TTntGroupBox;
    lblComPort: TTntLabel;
    lblBaudRate: TTntLabel;
    lblByteTimeout: TTntLabel;
    lblMaxRetryCount: TTntLabel;
    lblConnectionType: TTntLabel;
    lblRemoteHost: TTntLabel;
    lblRemotePort: TTntLabel;
    cbComPort: TTntComboBox;
    cbBaudRate: TTntComboBox;
    chbSearchByPort: TTntCheckBox;
    chbSearchByBaudRate: TTntCheckBox;
    cbConnectionType: TTntComboBox;
    edtRemoteHost: TTntEdit;
    gbPassword: TTntGroupBox;
    lblUsrPassword: TTntLabel;
    lblSysPassword: TTntLabel;
    lblStorage: TTntLabel;
    cbStorage: TTntComboBox;
    seRemotePort: TSpinEdit;
    seByteTimeout: TSpinEdit;
    seUsrPassword: TSpinEdit;
    seSysPassword: TSpinEdit;
    lblPrinterProtocol: TTntLabel;
    cbPrinterProtocol: TTntComboBox;
    cbMaxRetryCount: TTntComboBox;
    gbPolling: TTntGroupBox;
    lblPropertyUpdateMode: TTntLabel;
    cbPropertyUpdateMode: TTntComboBox;
    sePollInterval: TSpinEdit;
    lblPollInterval: TTntLabel;
    lblStatusInterval: TTntLabel;
    seStatusInterval: TSpinEdit;
    seStatusTimeout: TSpinEdit;
    lblStatusTimeout: TTntLabel;
    lblEventsType: TTntLabel;
    cbCCOType: TTntComboBox;
    lblModel: TTntLabel;
    cbModel: TTntComboBox;
    lblDriverType: TTntLabel;
    cbDriverType: TTntComboBox;
    procedure FormCreate(Sender: TObject);
  private
    FModels: TPrinterModels;
    procedure UpdateModels;
    procedure InitDriverTypes;
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  fmFptrConnection: TfmFptrConnection;

implementation

{$R *.dfm}

{ TfmFptrConnection }

constructor TfmFptrConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FModels := TPrinterModels.Create;
end;

destructor TfmFptrConnection.Destroy;
begin
  FModels.Free;
  inherited Destroy;
end;

procedure TfmFptrConnection.UpdateModels;
var
  i: Integer;
  FileName: WideString;
  Model: TPrinterModel;
  Reader: TXmlModelReader;
  ModelData: TPrinterModelRec;
begin
  cbModel.Items.BeginUpdate;
  Reader := TXmlModelReader.Create(FModels, Logger);
  try
    cbModel.Items.Clear;
    FileName := GetModulePath + ModelsFileName;
    Reader.Load(FileName);

    ModelData.ID := -1;
    ModelData.Name := 'Autoselect';
    Model := TPrinterModel.Create(nil, ModelData);
    FModels.Insert(0, Model);

    for i := 0 to FModels.Count-1 do
    begin
      Model := FModels[i];
      cbModel.Items.Add(Model.Data.Name);
    end;
  except
    on E: Exception do
    begin
      Logger.Error('TFiscalPrinterDevice.LoadModels', E);
    end;
  end;
  Reader.Free;
  cbModel.Items.EndUpdate;
end;

procedure TfmFptrConnection.InitDriverTypes;
begin
  // Order must match DriverType* constants in PrinterParameters
  cbDriverType.Items.BeginUpdate;
  try
    cbDriverType.Items.Clear;
    cbDriverType.Items.Add('Internal');              // DriverTypeInternal
    cbDriverType.Items.Add('SHTRIH-M DrvFR');         // DriverTypeShtrihDriver
    cbDriverType.Items.Add('RR-Electro KKTDrv');     // DriverTypeRRElectro
    cbDriverType.Items.Add('TorgBalance DrvFR5');    // DriverTypeTorgBalance
  finally
    cbDriverType.Items.EndUpdate;
  end;
end;

procedure TfmFptrConnection.UpdatePage;
var
  Index: Integer;
begin
  UpdateModels;
  cbConnectionType.ItemIndex := Parameters.ConnectionType;
  if (Parameters.DriverType >= 0) and
     (Parameters.DriverType < cbDriverType.Items.Count) then
    cbDriverType.ItemIndex := Parameters.DriverType
  else
    cbDriverType.ItemIndex := DriverTypeInternal;
  cbPrinterProtocol.ItemIndex := Parameters.PrinterProtocol;
  edtRemoteHost.Text := Parameters.RemoteHost;
  seRemotePort.Value := Parameters.RemotePort;
  cbComPort.ItemIndex := Parameters.PortNumber-1;
  cbBaudRate.ItemIndex := BaudRateToInt(Parameters.BaudRate);
  seByteTimeout.Value := Parameters.ByteTimeout;
  cbMaxRetryCount.ItemIndex := Parameters.MaxRetryCount;
  chbSearchByBaudRate.Checked := Parameters.SearchByBaudRateEnabled;
  chbSearchByPort.Checked := Parameters.SearchByPortEnabled;
  cbPropertyUpdateMode.ItemIndex := Parameters.PropertyUpdateMode;
  sePollInterval.Value := Parameters.PollIntervalInSeconds;
  seStatusInterval.Value := Parameters.StatusInterval;
  cbCCOType.ItemIndex := Parameters.CCOType;
  seUsrPassword.Value := Parameters.UsrPassword;
  seSysPassword.Value := Parameters.SysPassword;
  cbStorage.ItemIndex := Parameters.Storage;
  seStatusTimeout.Value := Parameters.StatusTimeout;
  Index := FModels.IndexById(Parameters.ModelId);
  if Index = -1 then Index := 0;
  cbModel.ItemIndex := Index;
end;

procedure TfmFptrConnection.UpdateObject;
begin
  Parameters.ConnectionType := cbConnectionType.ItemIndex;
  if cbDriverType.ItemIndex >= 0 then
    Parameters.DriverType := cbDriverType.ItemIndex
  else
    Parameters.DriverType := DriverTypeInternal;
  Parameters.PrinterProtocol := cbPrinterProtocol.ItemIndex;
  Parameters.RemoteHost := edtRemoteHost.Text;
  Parameters.RemotePort := seRemotePort.Value;
  Parameters.PortNumber := cbComPort.ItemIndex + 1;
  Parameters.BaudRate := IntToBaudRate(cbBaudRate.ItemIndex);
  Parameters.ByteTimeout := seByteTimeout.Value;
  Parameters.MaxRetryCount := cbMaxRetryCount.ItemIndex;
  Parameters.SearchByBaudRateEnabled := chbSearchByBaudRate.Checked;
  Parameters.SearchByPortEnabled := chbSearchByPort.Checked;
  Parameters.PropertyUpdateMode := cbPropertyUpdateMode.ItemIndex;
  Parameters.PollIntervalInSeconds := sePollInterval.Value;
  Parameters.StatusInterval := seStatusInterval.Value;
  Parameters.CCOType := cbCCOType.ItemIndex;
  Parameters.UsrPassword := seUsrPassword.Value;
  Parameters.SysPassword := seSysPassword.Value;
  Parameters.Storage := cbStorage.ItemIndex;
  Parameters.StatusTimeout := seStatusTimeout.Value;

  Parameters.ModelId := FModels[cbModel.ItemIndex].Data.ID;
end;

procedure TfmFptrConnection.FormCreate(Sender: TObject);
begin
  CreatePorts(cbComPort.Items);
  InitDriverTypes;
end;

end.
