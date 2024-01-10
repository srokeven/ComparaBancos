unit ComparaBancos.TipoTriggers;

interface

type
  TTipoTriggers = class
  private
    function ToString(ATipo: integer): string;
  public
  const
    // B* = Before / A* = After
    // *I = Insert / *U = Update / *D = Delete
    TIPO_TRIGGER_BI = 1;
    TIPO_TRIGGER_AI = 2;
    TIPO_TRIGGER_BU = 3;
    TIPO_TRIGGER_AU = 4;
    TIPO_TRIGGER_BD = 5;
    TIPO_TRIGGER_AD = 6;
    TIPO_TRIGGER_BI_BU = 17;
    TIPO_TRIGGER_AI_AU = 18;
    TIPO_TRIGGER_BI_BD = 25;
    TIPO_TRIGGER_AI_AD = 26;
    TIPO_TRIGGER_BU_BD = 27;
    TIPO_TRIGGER_AU_AD = 28;
    TIPO_TRIGGER_BI_BU_BD = 113;
    TIPO_TRIGGER_AI_AU_AD = 114;
  public
    class function ParseToString(ATipo: integer): string;
  end;

implementation

{ TTipoTriggers }

class function TTipoTriggers.ParseToString(ATipo: integer): string;
var
  lClasse: TTipoTriggers;
begin
  try
    lClasse := TTipoTriggers.Create;
    Result := lClasse.ToString(ATipo);
  finally
    lClasse.Free;
  end;
end;

function TTipoTriggers.ToString(ATipo: integer): string;
begin
  case ATipo of
    TIPO_TRIGGER_BI: Result := 'BEFORE INSERT';
    TIPO_TRIGGER_BU: Result := 'BEFORE UPDATE';
    TIPO_TRIGGER_BD: Result := 'BEFORE DELETE';
    TIPO_TRIGGER_BI_BU: Result := 'BEFORE INSERT OR UPDATE';
    TIPO_TRIGGER_BI_BD: Result := 'BEFORE INSERT OR DELETE';
    TIPO_TRIGGER_BU_BD: Result := 'BEFORE UPDATE OR DELETE';
    TIPO_TRIGGER_BI_BU_BD: Result := 'BEFORE INSERT OR UPDATE OR DELETE';
    TIPO_TRIGGER_AI: Result := 'AFTER INSERT';
    TIPO_TRIGGER_AU: Result := 'AFTER UPDATE';
    TIPO_TRIGGER_AD: Result := 'AFTER DELETE';
    TIPO_TRIGGER_AI_AU: Result := 'AFTER INSERT OR UPDATE';
    TIPO_TRIGGER_AI_AD: Result := 'AFTER INSERT OR DELETE';
    TIPO_TRIGGER_AU_AD: Result := 'AFTER UPDATE OR DELETE';
    TIPO_TRIGGER_AI_AU_AD: Result := 'AFTER INSERT OR UPDATE OR DELETE';
  end;
end;

end.
