program ComparaBancos;

uses
  Vcl.Forms,
  uMainComparaBancos in 'uMainComparaBancos.pas' {fmMainCamparaBancos},
  uCompareDatabases in 'uCompareDatabases.pas',
  uConnectionDataModule in 'uConnectionDataModule.pas' {dmConexao: TDataModule},
  ComparaBancos.Conexao in 'Tipos\ComparaBancos.Conexao.pas',
  CamparaBancos.Resposta in 'Tipos\CamparaBancos.Resposta.pas',
  ComparaBancos.BarraDeProgresso in 'Tipos\ComparaBancos.BarraDeProgresso.pas',
  ComparaBancos.TipoTriggers in 'Tipos\ComparaBancos.TipoTriggers.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMainCamparaBancos, fmMainCamparaBancos);
  Application.Run;
end.
