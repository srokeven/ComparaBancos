unit ComparaBancos.BarraDeProgresso;

interface

uses Vcl.ComCtrls, Vcl.Forms;

type
  TBarraDeProgresso = class
  private
    FBarra: TProgressBar;
  public
    procedure SetValoresIniciais(AMin, AMax: integer);
    procedure SetPosicao(APosicao: integer);
    constructor Create(var ABarra: TProgressBar);
  end;

implementation

{ TBarraDeProgresso }

constructor TBarraDeProgresso.Create(var ABarra: TProgressBar);
begin
  FBarra := ABarra;
end;

procedure TBarraDeProgresso.SetPosicao(APosicao: integer);
begin
  if APosicao <= FBarra.Max then
    FBarra.Position := APosicao
  else
    FBarra.Position := FBarra.Max;
  Application.ProcessMessages;
end;

procedure TBarraDeProgresso.SetValoresIniciais(AMin, AMax: integer);
begin
  SetPosicao(0);
  FBarra.Min := AMin;
  FBarra.Max := AMax;
end;

end.
