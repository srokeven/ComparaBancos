unit uMainComparaBancos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uCompareDatabases, System.JSON, System.StrUtils, CamparaBancos.Resposta;

type
  TfmMainCamparaBancos = class(TForm)
    pnlBottom: TPanel;
    pnlBackground: TPanel;
    gbOrigem: TGroupBox;
    gbDestino: TGroupBox;
    PageControl1: TPageControl;
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
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnTesteOriginClick(Sender: TObject);
    procedure btnTesteDestClick(Sender: TObject);
    procedure btnExtrairMetadadosOrigemClick(Sender: TObject);
    procedure btnExtrairMetadadosDestinoClick(Sender: TObject);
    procedure btnCompararClick(Sender: TObject);
  private
    fComparacao: TCompareDatabase;
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
begin
  fComparacao.AdicionarBarraDeProgresso(Progresso);
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
    mmResposta.Lines.Add('Schema "'+IfThen(lJsonOrigem = '[]', 'Origem', 'Destino')+'" não carregado');
    Exit;
  end;
  if fComparacao.VerificarDiferencaEntreBancos(lJsonOrigem, lJsonDestino) then
    ShowMessage('Concluido')
  else
    raise Exception.Create('Não concluido');
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

end.
