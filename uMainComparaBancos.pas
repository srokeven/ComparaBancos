unit uMainComparaBancos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uCompareDatabases, System.JSON, System.StrUtils, CamparaBancos.Resposta, System.Threading;

type
  TfmMainCamparaBancos = class(TForm)
    pnlBottom: TPanel;
    pnlBackground: TPanel;
    gbOrigem: TGroupBox;
    gbDestino: TGroupBox;
    pcPrincipal: TPageControl;
    tsGeral: TTabSheet;
    tsSchema: TTabSheet;
    Label1: TLabel;
    edServerOrigin: TEdit;
    Label2: TLabel;
    edPortOrigin: TEdit;
    Label3: TLabel;
    edDatabaseOrigin: TEdit;
    Label4: TLabel;
    edUsernameOrigin: TEdit;
    Label5: TLabel;
    edPasswordOrigin: TEdit;
    btnTesteOrigin: TButton;
    Label6: TLabel;
    edServerDest: TEdit;
    Label7: TLabel;
    edPortDest: TEdit;
    Label8: TLabel;
    edDatabaseDest: TEdit;
    Label9: TLabel;
    edUsernameDest: TEdit;
    Label10: TLabel;
    edPasswordDest: TEdit;
    btnTesteDest: TButton;
    btnExtrairMetadadosOrigem: TButton;
    mmResposta: TMemo;
    btnExtrairMetadadosDestino: TButton;
    tsComparativo: TTabSheet;
    mmComparativo: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    btnComparar: TButton;
    Progresso: TProgressBar;
    btnOrigemSequences: TButton;
    btnDestinoSequence: TButton;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnTesteOriginClick(Sender: TObject);
    procedure btnTesteDestClick(Sender: TObject);
    procedure btnExtrairMetadadosOrigemClick(Sender: TObject);
    procedure btnExtrairMetadadosDestinoClick(Sender: TObject);
    procedure btnCompararClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnOrigemSequencesClick(Sender: TObject);
  private
    fComparacao: TCompareDatabase;
    FProcesso: TProcesso;
    procedure HandleEscreveProcessoAtual(Sender: TObject);
    procedure HandleEscreveProcessoFinal(Sender: TObject);
  public
    { Public declarations }
  end;

var
  fmMainCamparaBancos: TfmMainCamparaBancos;

implementation

{$R *.dfm}

procedure TfmMainCamparaBancos.btnCompararClick(Sender: TObject);
var
  lSchemaOrigem, lSchemaDestino: TJSONArray;
  lJsonOrigem, lJsonDestino: string;
  lTask: ITask;
begin
  fComparacao.AdicionarBarraDeProgresso(Progresso);
  fComparacao.AdicionarRetornoDeRotina(FProcesso);
  fComparacao.OnActionEscreveProcesso := HandleEscreveProcessoFinal;
  fComparacao.OnActionEscreveProcessoAtual := HandleEscreveProcessoAtual;

  fComparacao.SetOrigemConexao(edServerOrigin.Text,
                               edPortOrigin.Text,
                               edDatabaseOrigin.Text,
                               edUsernameOrigin.Text,
                               edPasswordOrigin.Text);
  if fComparacao.TestarOrigem.Codigo = 200 then
  begin
    mmResposta.Lines.Add('Extraindo metadados da origem');
    lSchemaOrigem := TJSONObject.ParseJSONValue(fComparacao.ExtrairMetadataOrigem) as TJSONArray;
    lJsonOrigem := lSchemaOrigem.ToJSON;
    lSchemaOrigem.Free;
  end
  else mmResposta.Lines.Add('Erro ao conectar no banco de origem');
  fComparacao.SetDestinoConexao(edServerDest.Text,
                               edPortDest.Text,
                               edDatabaseDest.Text,
                               edUsernameDest.Text,
                               edPasswordDest.Text);
  if fComparacao.TestarDestino.Codigo = 200 then
  begin
    mmResposta.Lines.Add('Extraindo metadados da destino');
    lSchemaDestino := TJSONObject.ParseJSONValue(fComparacao.ExtrairMetadataDestino) as TJSONArray;
    lJsonDestino := lSchemaDestino.ToJSON;
    lSchemaDestino.Free;
  end
  else mmResposta.Lines.Add('Erro ao conectar no banco de destino');
  if (lJsonOrigem = '[]') or (lJsonDestino = '[]') then
  begin
    mmResposta.Lines.Add('Schema "'+IfThen(lJsonOrigem = '[]', 'Origem', 'Destino')+'" n�o carregado');
    Exit;
  end;
  pcPrincipal.ActivePage := tsComparativo;
  if fComparacao.VerificaVersaoEntreOsBancos then
  begin
    if fComparacao.VerificarDiferencaEntreBancos(lJsonOrigem, lJsonDestino) then
      ShowMessage('Concluido')
    else
      ShowMessage('N�o concluido');
  end
  else
  begin
    mmComparativo.Lines.Add('Vers�es incompativeis');
  end;
end;

procedure TfmMainCamparaBancos.btnExtrairMetadadosDestinoClick(Sender: TObject);
begin
  fComparacao.SetDestinoConexao(edServerDest.Text,
                               edPortDest.Text,
                               edDatabaseDest.Text,
                               edUsernameDest.Text,
                               edPasswordDest.Text);
  if fComparacao.TestarDestino.Codigo = 200 then
  begin
    mmResposta.Lines.Add('Extraindo metadados da destino');
    mmResposta.Lines.Add(fComparacao.ExtrairMetadataDestino);
  end;
end;

procedure TfmMainCamparaBancos.btnExtrairMetadadosOrigemClick(Sender: TObject);
begin
  fComparacao.SetOrigemConexao(edServerOrigin.Text,
                               edPortOrigin.Text,
                               edDatabaseOrigin.Text,
                               edUsernameOrigin.Text,
                               edPasswordOrigin.Text);
  if fComparacao.TestarOrigem.Codigo = 200 then
  begin
    mmResposta.Lines.Add('Extraindo metadados da origem');
    mmResposta.Lines.Add(fComparacao.ExtrairMetadataOrigem);
  end;
end;

procedure TfmMainCamparaBancos.btnOrigemSequencesClick(Sender: TObject);
var
  lResposta: TResposta;
begin
  lResposta := fComparacao.RecalcularSequences;
end;

procedure TfmMainCamparaBancos.btnTesteDestClick(Sender: TObject);
var
  Resp: TResposta;
begin
  fComparacao.SetDestinoConexao(edServerDest.Text,
                                edPortDest.Text,
                                edDatabaseDest.Text,
                                edUsernameDest.Text,
                                edPasswordDest.Text);
  Resp := fComparacao.TestarDestino;
  ShowMessage(Resp.Conteudo);
end;

procedure TfmMainCamparaBancos.btnTesteOriginClick(Sender: TObject);
var
  Resp: TResposta;
begin
  fComparacao.SetOrigemConexao(edServerOrigin.Text,
                               edPortOrigin.Text,
                               edDatabaseOrigin.Text,
                               edUsernameOrigin.Text,
                               edPasswordOrigin.Text);
  Resp := fComparacao.TestarOrigem;
  ShowMessage(Resp.Conteudo);
end;

procedure TfmMainCamparaBancos.FormCreate(Sender: TObject);
begin
  fComparacao := TCompareDatabase.Create;
end;

procedure TfmMainCamparaBancos.FormDestroy(Sender: TObject);
begin
  fComparacao.Free;
end;

procedure TfmMainCamparaBancos.FormResize(Sender: TObject);
begin
  gbOrigem.Width := tsGeral.Width div 2;
  gbDestino.Width := tsGeral.Width div 2;
end;

procedure TfmMainCamparaBancos.HandleEscreveProcessoAtual(Sender: TObject);
begin
  mmComparativo.Lines.Add(FProcesso.GetProcessoAtual);
end;

procedure TfmMainCamparaBancos.HandleEscreveProcessoFinal(Sender: TObject);
begin
  mmComparativo.Lines.Add(FProcesso.GetProcesso);
end;

end.
