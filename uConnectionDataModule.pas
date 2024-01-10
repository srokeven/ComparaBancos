unit uConnectionDataModule;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.IBBase,
  Data.DB, FireDAC.Comp.Client, DataSet.Serialize, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util, FireDAC.Comp.Script,
  System.JSON, CamparaBancos.Resposta, ComparaBancos.TipoTriggers,
  System.StrUtils;

type
  TSqlCollection = (scSelectTabelas,
                    scSelectCampos,
                    scSelectConstraints,
                    scSelectIndices,
                    scSelectTriggers,
                    scSelectSequence,
                    scSelectByNameTrigger,
                    scAlterTrigger,
                    scCreateTrigger,
                    scDropTrigger,
                    scSelectByNameSequence,
                    scDropSequence,
                    scResetSequence,
                    scSelectByNameIndice,
                    scResetIndice,
                    scDropIndice,
                    scSelectByNameConstraint,
                    scDropConstraint,
                    scAlterConstraint,
                    scSelectByNameField,
                    scDropField,
                    scAlterField,
                    scSelectByNameTable,
                    scDropTable,
                    scCreateTable,
                    scCreateIndice,
                    scCreateSequence);
  TdmConexao = class(TDataModule)
    ConexaoOrigem: TFDConnection;
    ConexaoDestino: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    Scripts: TFDScript;
    procedure DataModuleDestroy(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
  private
    FLog: string;
    procedure GravaLog(AText: string);
    function CreateContextField(AFieldName, ANotNull, ADefaultValue, AFieldLength,
      AFieldPrecision, AFieldScale, AFieldType, AFieldSubType, ASegmentLength: string): string;
    function VerificaElementoExiste(ASql: string): boolean;
    function ExecutaAcaoNoElemento(ASql: string): boolean;
    function ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao: string; AExecutarSeNaoExistir: boolean): TResposta; overload;
    function ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao, ASqlExclucaoCasoExista: string): TResposta; overload;
    function DropElement(ASqlVerificacao, ASqlExecucao: string): TResposta;
    function CreateElement(ASqlVerificacao, ASqlExecucao: string; AExecutarSeNaoExistir: boolean): TResposta;
    function ForceCreateElement(ASqlVerificacao, ASqlExecucao, ASqlExclusaoCasoExista: string): TResposta; //Exclui o elemento se existir para forçar a criação
    function AlterElement(ASqlVerificacao, ASqlExecucao: string): TResposta;
  public
    procedure ConectarOrigem(AServer, APort, ADatabase, AUsername, APassword: string);
    procedure ConectarDestino(AServer, APort, ADatabase, AUsername, APassword: string);

    procedure DesconectarOrigem;
    procedure DesconectarDestino;
    procedure DesconectarTodos;

    function OrigemConectado: boolean;
    function DestinoConectado: boolean;

    function GetConexaoOrigem: TFDConnection;
    function GetConexaoDestino: TFDConnection;

    function Select(ASQL: string; AConexao: TFDConnection): string; overload;
    function Select(AIndex: TSqlCollection; AConexao: TFDConnection): string; overload;
    function SelectBoolean(ASQL: string; AConexao: TFDConnection): boolean;
    function Execute(ASQL: string; AConexao: TFDConnection): boolean; overload;
    function Execute(ASQL: array of string; AConexao: TFDConnection): boolean; overload;
    function CloneFieldValues(ATableName, AFieldSource, AFieldDestination: string; AConexao: TFDConnection): boolean;

    function GetScript(AIndex: TSqlCollection):string;
    function GetUltimoLog: string;

    function DropSequence(ASequenceName, ATriggerName: string): TResposta;
    function DropTrigger(ATriggerName: string): TResposta;
    function DropIndice(AIndexName: string): TResposta;
    function DropConstraint(AConstraintName, ATableName: string): TResposta;
    function DropField(AFieldName, ATableName: string): TResposta;
    function DropTable(ATableName: string): TResposta;
    function CreateTable(ATableName, AJsonFields: string): TResposta;
    function AlterOrCreateFields(ATableName, AJsonField, AJsonCompleto: string): TResposta;
    function CreateConstraint(AConstraintName, ATableName, AListFieldsLocalTable,
      AForeingTable, AListFieldsForeignTable, ATypeConstraint: string): TResposta;
    function AlterOrCreateIndice(AIndiceName, ATableName, AValorComputado,
      AValorIndexado, AOrderIndex: string): TResposta;
    function AlterOrCreateSequence(ASequenceName: string): TResposta;
    function AlterTrigger(ATriggerName: string; AActive: boolean; ATriggerTipo,
      ATriggerPosition: integer; ATriggerContext: string): TResposta;
    function CreateTrigger(ATableName, ATriggerName: string; AActive: boolean; ATriggerTipo,
      ATriggerPosition: integer; ATriggerContext: string): TResposta;
    class function TestarConexaoOrigem(AServer, APort, ADatabase, AUsername, APassword: string): boolean;
    class function TestarConexaoDestino(AServer, APort, ADatabase, AUsername, APassword: string): boolean;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TdmConexao }

function TdmConexao.AlterElement(ASqlVerificacao, ASqlExecucao: string): TResposta;
begin
  Result := ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao, False);
end;

function TdmConexao.CreateElement(ASqlVerificacao, ASqlExecucao: string; AExecutarSeNaoExistir: boolean): TResposta;
begin
  Result := ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao, AExecutarSeNaoExistir);
end;

function TdmConexao.ForceCreateElement(ASqlVerificacao, ASqlExecucao, ASqlExclusaoCasoExista: string): TResposta;
begin
  Result := ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao, ASqlExclusaoCasoExista);
end;

function TdmConexao.DropElement(ASqlVerificacao, ASqlExecucao: string): TResposta;
begin
  Result := ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao, False);
end;

function TdmConexao.VerificaElementoExiste(ASql: string): boolean;
begin
  Result := not(Select(ASql, GetConexaoDestino) = '[]');
end;

function TdmConexao.ExecutaAcaoNoElemento(ASql: string): boolean;
begin
  Result := Execute(ASql, GetConexaoDestino);
end;

function TdmConexao.ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao,
  ASqlExclucaoCasoExista: string): TResposta;
begin
  if VerificaElementoExiste(ASqlVerificacao) then
  begin
    if ExecutaAcaoNoElemento(ASqlExclucaoCasoExista) then //Excluindo elemento antigo
    begin
      if ExecutaAcaoNoElemento(ASqlExecucao) then
      begin
        Result.Codigo := 200;
        Result.Conteudo := 'Ok';
      end
      else
      begin
        Result.Codigo := 500;
        Result.Conteudo := GetUltimoLog;
      end;
    end
    else
    begin
      Result.Codigo := 500;
      Result.Conteudo := GetUltimoLog;
    end;
  end
  else
  if ExecutaAcaoNoElemento(ASqlExecucao) then
  begin
    Result.Codigo := 200;
    Result.Conteudo := 'Ok';
  end
  else
  begin
    Result.Codigo := 500;
    Result.Conteudo := GetUltimoLog;
  end;
end;

function TdmConexao.ExecutarAlteracaoNoBanco(ASqlVerificacao, ASqlExecucao: string; AExecutarSeNaoExistir: boolean): TResposta;
begin
  if VerificaElementoExiste(ASqlVerificacao) then
  begin
    if ExecutaAcaoNoElemento(ASqlExecucao) then
    begin
      Result.Codigo := 200;
      Result.Conteudo := 'Ok';
    end
    else
    begin
      Result.Codigo := 500;
      Result.Conteudo := GetUltimoLog;
    end;
  end
  else
  if AExecutarSeNaoExistir then
  begin
    if ExecutaAcaoNoElemento(ASqlExecucao) then
    begin
      Result.Codigo := 200;
      Result.Conteudo := 'Ok';
    end
    else
    begin
      Result.Codigo := 500;
      Result.Conteudo := GetUltimoLog;
    end;
  end
  else
  begin
    Result.Codigo := 204;
    Result.Conteudo := 'Não encontrado';
  end;
end;

function TdmConexao.DropConstraint(AConstraintName, ATableName: string): TResposta;
var
  lSqlConsultaConstraintExiste, lSqlDropConstraint: string;
begin
  lSqlConsultaConstraintExiste := GetScript(scSelectByNameConstraint).Replace('$NOME', AConstraintName);
  lSqlDropConstraint := GetScript(scDropConstraint).Replace('$NOME', AConstraintName).Replace('$TABELA', ATableName);
  Result := DropElement(lSqlConsultaConstraintExiste, lSqlDropConstraint);
end;

function TdmConexao.DropField(AFieldName, ATableName: string): TResposta;
var
  lSqlConsultaFieldExiste, lSqlDropField: string;
begin
  lSqlConsultaFieldExiste := GetScript(scSelectByNameField).Replace('$NOME', AFieldName).Replace('$TABELA', ATableName);
  lSqlDropField := GetScript(scDropField).Replace('$NOME', AFieldName).Replace('$TABELA', ATableName);
  Result := DropElement(lSqlConsultaFieldExiste, lSqlDropField);
end;

function TdmConexao.DropIndice(AIndexName: string): TResposta;
var
  lSqlConsultaIndiceExiste, lSqlDropIndice: string;
begin
  lSqlConsultaIndiceExiste := GetScript(scSelectByNameIndice).Replace('$NOME', AIndexName);
  lSqlDropIndice := GetScript(scDropIndice).Replace('$NOME', AIndexName);
  Result := DropElement(lSqlConsultaIndiceExiste, lSqlDropIndice);
end;

function TdmConexao.DropSequence(ASequenceName, ATriggerName: string): TResposta;
var
  lRespostaAlterTrigger: TResposta;
  lSqlConsultaSequenceExiste, lSqlDropSequence: string;
begin
  lSqlConsultaSequenceExiste := GetScript(scSelectByNameSequence).Replace('$NOME', ASequenceName);
  lSqlDropSequence := GetScript(scDropSequence).Replace('$NOME', ASequenceName);
  //Verificar e alterar a trigger para evitar problema de conflito de dependencia
  lRespostaAlterTrigger := AlterTrigger(ATriggerName, True, TTipoTriggers.TIPO_TRIGGER_BI, 0, 'as begin EXIT; end');
  if lRespostaAlterTrigger.Codigo = 200 then
  begin
    Result := DropElement(lSqlConsultaSequenceExiste, lSqlDropSequence);
  end
  else Result := lRespostaAlterTrigger;
end;

function TdmConexao.DropTable(ATableName: string): TResposta;
var
  lSqlConsultaTableExiste, lSqlDropTable: string;
begin
  lSqlConsultaTableExiste := GetScript(scSelectByNameTable).Replace('$NOME', ATableName);
  lSqlDropTable := GetScript(scDropTable).Replace('$NOME', ATableName);
  Result := DropElement(lSqlConsultaTableExiste, lSqlDropTable);
end;

function TdmConexao.CreateTable(ATableName, AJsonFields: string): TResposta;
var
  lSqlConsultaTableExiste, lSqlCreateTable, lSqlPartFields: string;
  lFieldsJsonArray: TJSONArray;
  I: Integer;
begin
  lSqlConsultaTableExiste := GetScript(scSelectByNameTable).Replace('$NOME', ATableName);

  lSqlPartFields := '';
  lFieldsJsonArray := TJSONObject.ParseJSONValue(AJsonFields) as TJSONArray;
  for I := 0 to lFieldsJsonArray.Count - 1 do
  begin
    lSqlPartFields := IfThen(lSqlPartFields.IsEmpty, '', lSqlPartFields +',') +
      CreateContextField(lFieldsJsonArray.Items[I].GetValue<string>('field_name', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('not_null', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('default_value', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('field_length', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('field_precision', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('field_scale', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('field_type', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('field_sub_type', ''),
                         lFieldsJsonArray.Items[I].GetValue<string>('segment_length', ''));
  end;
  lFieldsJsonArray.Free;
  lSqlCreateTable := GetScript(scCreateTable).Replace('$NOME', ATableName).Replace('$CAMPOS', lSqlPartFields);
  Result := CreateElement(lSqlConsultaTableExiste, lSqlCreateTable, True);
end;

function TdmConexao.CreateTrigger(ATableName, ATriggerName: string;
  AActive: boolean; ATriggerTipo, ATriggerPosition: integer;
  ATriggerContext: string): TResposta;
var
  lSqlConsultaTriggerExiste, lSqlCriarTrigger: string;
begin
  lSqlConsultaTriggerExiste := GetScript(scSelectByNameTrigger).Replace('$NOME', ATriggerName);
  lSqlCriarTrigger := GetScript(scCreateTrigger)
    .Replace('$NOME', ATriggerName)
    .Replace('$TABELA', ATableName)
    .Replace('$INATIVO_ATIVO', IfThen(aActive, 'ACTIVE', 'INACTIVE'))
    .Replace('$TIPO', TTipoTriggers.ParseToString(ATriggerTipo))
    .Replace('$POSICAO', ATriggerPosition.ToString)
    .Replace('$CONTEUDO', aTriggerContext);
  Result := AlterElement(lSqlConsultaTriggerExiste, lSqlCriarTrigger);
end;

function TdmConexao.CreateConstraint(AConstraintName, ATableName, AListFieldsLocalTable,
  AForeingTable, AListFieldsForeignTable, ATypeConstraint: string): TResposta;
var
  lSqlConsultaConstraintExiste, lSqlCriaConstraint, lSqlExcluirConstraint, lSintaxeChaveEstrangeira,
  lCamposChave, lCamposEstrangeirosChave: string;
begin
  lSintaxeChaveEstrangeira := EmptyStr;
  lCamposChave := Copy(AListFieldsLocalTable, 2, Length(AListFieldsLocalTable) -2);
  lCamposChave := lCamposChave.Replace('|', ',');
  lSqlConsultaConstraintExiste := GetScript(scSelectByNameConstraint).Replace('$NOME', AConstraintName);
  lSqlExcluirConstraint := GetScript(scDropConstraint).Replace('$NOME', AConstraintName).Replace('$TABELA', ATableName);
  if (ATypeConstraint = 'FOREIGN KEY') then
  begin
    lCamposEstrangeirosChave := Copy(AListFieldsForeignTable, 2, Length(AListFieldsForeignTable) -2);
    lCamposEstrangeirosChave := lCamposEstrangeirosChave.Replace('|', ',');
    lSintaxeChaveEstrangeira := Format('REFERENCES %s (%s)', [AForeingTable, lCamposEstrangeirosChave]);
  end;
  lSqlCriaConstraint := GetScript(scAlterConstraint)
    .Replace('$TABELA', ATableName)
    .Replace('$NOME', AConstraintName)
    .Replace('$TIPO', ATypeConstraint)
    .Replace('$CAMPO', lCamposChave)
    .Replace('$SINTAXE_CHAVE_ESTRANGEIRA', lSintaxeChaveEstrangeira);
   Result := ForceCreateElement(lSqlConsultaConstraintExiste, lSqlCriaConstraint, lSqlExcluirConstraint);
end;

function TdmConexao.CreateContextField(AFieldName, ANotNull, ADefaultValue, AFieldLength,
  AFieldPrecision, AFieldScale, AFieldType, AFieldSubType, ASegmentLength: string): string;
var
  lFieldSintaxe: string;
begin
   //Verificar necessidade de colocar o char-collection
   lFieldSintaxe := AFieldName + ' ' + AFieldType;
   if (AFieldType = 'TIMESTAMP') or
      (AFieldType = 'DATE') or
      (AFieldType = 'TIME') or
      (AFieldType = 'INTEGER') or
      (AFieldType = 'INT64') or
      (AFieldType = 'DOUBLE') or
      (AFieldType = 'SMALLINT') then
   begin
     if not (ADefaultValue.IsEmpty) then
       lFieldSintaxe := lFieldSintaxe + ' DEFAULT '+ADefaultValue;
   end
   else
   if (AFieldType = 'VARCHAR') or (AFieldType = 'CHAR') then
   begin
     lFieldSintaxe := lFieldSintaxe + '('+AFieldLength+')';
     if not (ADefaultValue.IsEmpty) then
       lFieldSintaxe := lFieldSintaxe + ' DEFAULT '+ QuotedStr(ADefaultValue);
   end
   else
   if AFieldType = 'BLOB' then
   begin
     lFieldSintaxe := lFieldSintaxe + Format(' SUB_TYPE %s SEGMENT SIZE %s', [AFieldSubType, ASegmentLength]);
     if not (ADefaultValue.IsEmpty) then
       lFieldSintaxe := lFieldSintaxe + ' DEFAULT '+ QuotedStr(ADefaultValue);
   end
   else
   if (AFieldType = 'DECIMAL') or (AFieldType = 'NUMERIC') or (AFieldType = 'FLOAT') then
   begin
     lFieldSintaxe := lFieldSintaxe + Format(' (%s, %s)', [AFieldPrecision, AFieldScale]);
     if not (ADefaultValue.IsEmpty) then
       lFieldSintaxe := lFieldSintaxe + ' DEFAULT '+ADefaultValue;
   end;
   if ANotNull = '1' then
     lFieldSintaxe := lFieldSintaxe + ' NOT NULL';
   Result := lFieldSintaxe;
end;

function TdmConexao.DropTrigger(ATriggerName: string): TResposta;
var
  lSqlConsultaTriggerExiste, lSqlDropTrigger: string;
begin
  lSqlConsultaTriggerExiste := GetScript(scSelectByNameTrigger).Replace('$NOME', ATriggerName);
  lSqlDropTrigger := GetScript(scDropTrigger).Replace('$NOME', ATriggerName);
  Result := DropElement(lSqlConsultaTriggerExiste, lSqlDropTrigger);
end;

function TdmConexao.AlterOrCreateIndice(AIndiceName, ATableName, AValorComputado,
  AValorIndexado, AOrderIndex: string): TResposta;
var
  lSqlConsultaIndiceExiste, lSqlCriarIndice, lSqlExclusaoIndice, lValor, lTextoTipoComputado, lOrder: string;
begin
  lSqlConsultaIndiceExiste := GetScript(scSelectByNameIndice).Replace('$NOME', AIndiceName);
  lSqlExclusaoIndice := GetScript(scDropIndice).Replace('$NOME', AIndiceName);
  if not (AValorComputado.IsEmpty) then
  begin
    lTextoTipoComputado := 'COMPUTED BY';
    lValor := AValorComputado;
  end
  else
    lValor := AValorIndexado;
  if AOrderIndex = '1' then
    lOrder := 'DESCENDING';
  lSqlCriarIndice := GetScript(scCreateIndice).Replace('$NOME', AIndiceName)
                                              .Replace('$ORDER', lOrder)
                                              .Replace('$TABELA', ATableName)
                                              .Replace('$COMPUTED_SINTAXE', lTextoTipoComputado)
                                              .Replace('$VALOR', lValor);
  Result := ForceCreateElement(lSqlConsultaIndiceExiste, lSqlCriarIndice, lSqlExclusaoIndice);
end;

function TdmConexao.AlterOrCreateSequence(ASequenceName: string): TResposta;
var
  lSqlConsultaSequenceExiste, lSqlCriarSequence: string;
begin
  lSqlConsultaSequenceExiste := GetScript(scSelectByNameSequence).Replace('$NOME', ASequenceName);
  lSqlCriarSequence := GetScript(scCreateSequence).Replace('$NOME', ASequenceName);
  Result := CreateElement(lSqlConsultaSequenceExiste, lSqlCriarSequence, False);
end;

function TdmConexao.AlterOrCreateFields(ATableName, AJsonField, AJsonCompleto: string): TResposta;
var
  lSqlConsultaTableExiste, lSqlConsultaFieldExiste, lSqlContextField, lSqlAlteraTabelaComCampo,
  lFieldName, lFieldNameTemp, lSqlConsultaFieldTempExiste, lSqlAlteraTabelaComCampoTemp: string;
  lRespostaCampoTemporario: TResposta;
  lFieldJson, lFieldDependencies: TJSONObject;
  I: Integer;
begin
  lSqlConsultaTableExiste := GetScript(scSelectByNameTable).Replace('$NOME', ATableName);

  lSqlContextField := '';
  lFieldJson := TJSONObject.ParseJSONValue(AJsonField) as TJSONObject;
  lSqlContextField := CreateContextField(lFieldJson.GetValue<string>('field_name', ''),
                                         lFieldJson.GetValue<string>('not_null', ''),
                                         lFieldJson.GetValue<string>('default_value', ''),
                                         lFieldJson.GetValue<string>('field_length', ''),
                                         lFieldJson.GetValue<string>('field_precision', ''),
                                         lFieldJson.GetValue<string>('field_scale', ''),
                                         lFieldJson.GetValue<string>('field_type', ''),
                                         lFieldJson.GetValue<string>('field_sub_type', ''),
                                         lFieldJson.GetValue<string>('segment_length', ''));
  lFieldName := lFieldJson.GetValue<string>('field_name', '');
  lFieldNameTemp := lFieldName + '_TEMP';
  lFieldJson.Free;
  lSqlConsultaFieldExiste := GetScript(scSelectByNameField).Replace('$NOME', lFieldName).Replace('$TABELA', ATableName);
  lSqlAlteraTabelaComCampo := GetScript(scAlterField).Replace('$CAMPO', lSqlContextField).Replace('$TABELA', ATableName);

  //Cria campo Temporario
  lSqlConsultaFieldTempExiste := GetScript(scSelectByNameField).Replace('$NOME', lFieldNameTemp).Replace('$TABELA', ATableName);
  lSqlAlteraTabelaComCampoTemp := GetScript(scAlterField).Replace('$CAMPO', lSqlContextField.Replace(lFieldName, lFieldNameTemp)).Replace('$TABELA', ATableName);

  if VerificaElementoExiste(lSqlConsultaTableExiste) then
  begin
    //Verificar se o campo existe
    if VerificaElementoExiste(lSqlConsultaFieldExiste) then
    begin
      if VerificaElementoExiste(lSqlConsultaFieldTempExiste) then
        if DropField(lFieldNameTemp, ATableName).Codigo <> 200 then
        begin
          Result.Codigo := 500;
          Result.Conteudo := Format('Não foi possivel remover o campo %s na tabela %s', [lFieldNameTemp, ATableName]);
          Exit;
        end;
      lRespostaCampoTemporario := CreateElement(lSqlConsultaFieldTempExiste, lSqlAlteraTabelaComCampoTemp, True);
      if lRespostaCampoTemporario.Codigo = 200 then
      begin
        if CloneFieldValues(ATableName, lFieldName, lFieldNameTemp, GetConexaoDestino) then
        begin
          //Verificando e desabilitando dependencias
          lFieldDependencies := TJSONObject.ParseJSONValue(AJsonCompleto) as TJSONObject;
          for I := 0 to lFieldDependencies.GetValue<TJSONArray>('triggers').Count - 1 do
          begin
            AlterTrigger(lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_name'),
                         lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_inactive') = '0',
                         StrToInt(lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_type')),
                         StrToInt(lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_sequence')),
                         'as begin EXIT; end'
            );
          end;
          for I := 0 to lFieldDependencies.GetValue<TJSONArray>('constraints').Count - 1 do
          begin
            DropConstraint(lFieldDependencies.GetValue<TJSONArray>('constraints').Items[I].GetValue<string>('constraint_name'),
                           ATableName);
          end;
          for I := 0 to lFieldDependencies.GetValue<TJSONArray>('indices').Count - 1 do
          begin
            DropIndice(lFieldDependencies.GetValue<TJSONArray>('indices').Items[I].GetValue<string>('index_name'));
          end;
          lRespostaCampoTemporario := DropField(lFieldName, ATableName);
          if lRespostaCampoTemporario.Codigo = 200 then
          begin
            lRespostaCampoTemporario := CreateElement(lSqlConsultaFieldExiste, lSqlAlteraTabelaComCampo, True);
            if lRespostaCampoTemporario.Codigo = 200 then
            begin
              if CloneFieldValues(ATableName, lFieldNameTemp, lFieldName, GetConexaoDestino) then
              begin
                DropField(lFieldNameTemp, ATableName);
                Result.Codigo := 200;
                Result.Conteudo := 'Campo '+lFieldName+' Criado/Alterado na tabela '+ATableName;
              end;
            end
            else
            begin
              DropField(lFieldNameTemp, ATableName);
              Result := lRespostaCampoTemporario;
            end;
          end
          else
          begin
            DropField(lFieldNameTemp, ATableName);
            Result := lRespostaCampoTemporario;
          end;
          //Reativando dependendcias
          for I := 0 to lFieldDependencies.GetValue<TJSONArray>('triggers').Count - 1 do
          begin
            AlterTrigger(lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_name'),
                         lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_inactive') = '0',
                         StrToInt(lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_type')),
                         StrToInt(lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_sequence')),
                         lFieldDependencies.GetValue<TJSONArray>('triggers').Items[I].GetValue<string>('trigger_source')
            );
          end;
          for I := 0 to lFieldDependencies.GetValue<TJSONArray>('constraints').Count - 1 do
          begin
            CreateConstraint(lFieldDependencies.GetValue<TJSONArray>('constraints').Items[I].GetValue<string>('constraint_name'),
                             ATableName,
                             lFieldDependencies.GetValue<TJSONArray>('constraints').Items[I].GetValue<string>('field_name'),
                             lFieldDependencies.GetValue<TJSONArray>('constraints').Items[I].GetValue<string>('relation_name'),
                             lFieldDependencies.GetValue<TJSONArray>('constraints').Items[I].GetValue<string>('foreign_field_name'),
                             lFieldDependencies.GetValue<TJSONArray>('constraints').Items[I].GetValue<string>('constraint_type')
            );
          end;
          for I := 0 to lFieldDependencies.GetValue<TJSONArray>('indices').Count - 1 do
          begin
            AlterOrCreateIndice(lFieldDependencies.GetValue<TJSONArray>('indices').Items[I].GetValue<string>('index_name'),
                                ATableName,
                                lFieldDependencies.GetValue<TJSONArray>('indices').Items[I].GetValue<string>('expression_source'),
                                lFieldDependencies.GetValue<TJSONArray>('indices').Items[I].GetValue<string>('field_name'),
                                lFieldDependencies.GetValue<TJSONArray>('indices').Items[I].GetValue<string>('index_type'));
          end;
          lFieldDependencies.Free;
        end
        else
        begin
          Result.Codigo := 500;
          Result.Conteudo := GetUltimoLog;
        end;
      end
      else
      begin
        Result := lRespostaCampoTemporario;
        Exit;
      end;
    end
    else
      Result := CreateElement(lSqlConsultaFieldExiste, lSqlAlteraTabelaComCampo, True);
  end
  else
  begin
    Result.Codigo := 404;
    Result.Conteudo := Format('Tabela %s não encontrada', [ATableName])
  end;
end;

function TdmConexao.AlterTrigger(ATriggerName: string; AActive: boolean;
  ATriggerTipo, ATriggerPosition: integer; ATriggerContext: string): TResposta;
var
  lSqlConsultaTriggerExiste, lSqlAlteraTrigger: string;
begin                                                            //Verifica: quotedstr
  lSqlConsultaTriggerExiste := GetScript(scSelectByNameTrigger).Replace('$NOME', ATriggerName);
  lSqlAlteraTrigger := GetScript(scAlterTrigger)
    .Replace('$NOME', ATriggerName)
    .Replace('$INATIVO_ATIVO', IfThen(aActive, 'ACTIVE', 'INACTIVE'))
    .Replace('$TIPO', TTipoTriggers.ParseToString(ATriggerTipo))
    .Replace('$POSICAO', ATriggerPosition.ToString)
    .Replace('$CONTEUDO', aTriggerContext);
  Result := AlterElement(lSqlConsultaTriggerExiste, lSqlAlteraTrigger);
end;

function TdmConexao.CloneFieldValues(ATableName, AFieldSource,
  AFieldDestination: string; AConexao: TFDConnection): boolean;
var
  lQuery: TFDQuery;
begin
  lQuery := TFDQuery.Create(nil);
  Result := False;
  try
    lQuery.Connection := AConexao;
    lQuery.SQL.Text := Format('update %s set %s = %s', [ATableName, AFieldDestination, AFieldSource]);
    try
      lQuery.ExecSQL;
      Result := True;
    except
      on e: exception do
        GravaLog('Erro ao executar comando SQL: '+lQuery.SQL.Text+sLineBreak+'Erro: '+e.Message);
    end;
  finally
    lQuery.Free;
  end;
end;

procedure TdmConexao.ConectarDestino(AServer, APort, ADatabase, AUsername, APassword: string);
begin
  try
    ConexaoDestino.Params.Values['Server']    := AServer;
    ConexaoDestino.Params.Values['Port']      := APort;
    ConexaoDestino.Params.Values['Database']  := ADatabase;
    ConexaoDestino.Params.Values['User_Name'] := AUsername;
    ConexaoDestino.Params.Values['Password']  := APassword;
    ConexaoDestino.Open;
  except
    on E: exception do
    begin
      GravaLog('Erro ao tentar se conectar ao banco de dados de destino: '+e.Message);
    end;
  end;
end;

procedure TdmConexao.ConectarOrigem(AServer, APort, ADatabase, AUsername, APassword: string);
begin
  try
    ConexaoOrigem.Params.Values['Server']    := AServer;
    ConexaoOrigem.Params.Values['Port']      := APort;
    ConexaoOrigem.Params.Values['Database']  := ADatabase;
    ConexaoOrigem.Params.Values['User_Name'] := AUsername;
    ConexaoOrigem.Params.Values['Password']  := APassword;
    ConexaoOrigem.Open;
  except
    on E: exception do
    begin
      GravaLog('Erro ao tentar se conectar ao banco de dados de origem: '+e.Message);
    end;
  end;
end;

procedure TdmConexao.DataModuleCreate(Sender: TObject);
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := TCaseNameDefinition.cndNone;
end;

procedure TdmConexao.DataModuleDestroy(Sender: TObject);
begin
  DesconectarTodos;
end;

procedure TdmConexao.DesconectarDestino;
begin
  ConexaoDestino.Close;
end;

procedure TdmConexao.DesconectarOrigem;
begin
  ConexaoOrigem.Close;
end;

procedure TdmConexao.DesconectarTodos;
begin
  DesconectarOrigem;
  DesconectarDestino;
end;

function TdmConexao.DestinoConectado: boolean;
begin
  Result := ConexaoDestino.Connected;
end;

function TdmConexao.Execute(ASQL: array of string; AConexao: TFDConnection): boolean;
var
  lQuery: TFDQuery;
  I: Integer;
begin
  lQuery := TFDQuery.Create(nil);
  Result := False;
  try
    lQuery.Connection := AConexao;
    try
      for I := Low(ASQL) to High(ASQL) do
      begin
        lQuery.ExecSQL(ASQL[I]);
      end;
      Result := True;
    except
      on e: exception do
        GravaLog('Erro ao executar comando SQL'+sLineBreak+'Erro: '+e.Message);
    end;
  finally
    lQuery.Free;
  end;
end;

function TdmConexao.Execute(ASQL: string; AConexao: TFDConnection): boolean;
var
  lQuery: TFDQuery;
begin
  lQuery := TFDQuery.Create(nil);
  Result := False;
  try
    lQuery.Connection := AConexao;
    lQuery.SQL.Text := ASQL;
    try
      lQuery.ExecSQL;
      Result := True;
    except
      on e: exception do
        GravaLog('Erro ao executar comando SQL: '+ASQL+sLineBreak+'Erro: '+e.Message);
    end;
  finally
    lQuery.Free;
  end;
end;

function TdmConexao.GetConexaoDestino: TFDConnection;
begin
  Result := ConexaoDestino;
end;

function TdmConexao.GetConexaoOrigem: TFDConnection;
begin
  Result := ConexaoOrigem;
end;

function TdmConexao.GetScript(AIndex: TSqlCollection): string;
begin
  Result := Scripts.SQLScripts.Items[Integer(AIndex)].SQL.Text;
end;

function TdmConexao.GetUltimoLog: string;
begin
  Result := FLog;
end;

procedure TdmConexao.GravaLog(AText: string);
begin
  FLog := AText;
end;

function TdmConexao.OrigemConectado: boolean;
begin
  Result := ConexaoOrigem.Connected;
end;

function TdmConexao.Select(AIndex: TSqlCollection; AConexao: TFDConnection): string;
var
  lQuery: TFDQuery;
  LJSONArray: TJSONArray;
begin
  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := AConexao;
    lQuery.Open(GetScript(AIndex));
    LJSONArray := lQuery.ToJSONArray();
    Result := LJSONArray.toJSON;
  finally
    lQuery.Free;
    LJSONArray.Free;
  end;
end;

class function TdmConexao.TestarConexaoDestino(AServer, APort, ADatabase,
  AUsername, APassword: string): boolean;
var
  dmConexao: TdmConexao;
begin
  dmConexao := TdmConexao.Create(nil);
  try
    dmConexao.ConectarDestino(AServer, APort, ADatabase, AUsername, APassword);
    Result := dmConexao.DestinoConectado;
  finally
    dmConexao.Free;
  end;
end;

class function TdmConexao.TestarConexaoOrigem(AServer, APort, ADatabase,
  AUsername, APassword: string): boolean;
var
  dmConexao: TdmConexao;
begin
  dmConexao := TdmConexao.Create(nil);
  try
    dmConexao.ConectarOrigem(AServer, APort, ADatabase, AUsername, APassword);
    Result := dmConexao.OrigemConectado;
  finally
    dmConexao.Free;
  end;
end;

function TdmConexao.Select(ASQL: string; AConexao: TFDConnection): string;
var
  lQuery: TFDQuery;
  LJSONArray: TJSONArray;
begin
  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := AConexao;
    lQuery.Open(ASQL);
    LJSONArray := lQuery.ToJSONArray();
    Result := LJSONArray.toJSON;
  finally
    lQuery.Free;
    LJSONArray.Free;
  end;
end;

function TdmConexao.SelectBoolean(ASQL: string; AConexao: TFDConnection): boolean;
var
  lQuery: TFDQuery;
begin
  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := AConexao;
    lQuery.Open(ASQL);
    Result := not (lQuery.IsEmpty);
  finally
    lQuery.Free;
  end;
end;

end.
