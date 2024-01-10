unit uCompareDatabases;

interface

uses System.SysUtils, System.Classes, uConnectionDataModule, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.IBBase,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.Comp.Script,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util, System.Json, System.StrUtils,
  Vcl.ComCtrls, VCL.Forms, System.Character, CamparaBancos.Resposta,
  ComparaBancos.BarraDeProgresso, ComparaBancos.Conexao,
  ComparaBancos.TipoTriggers;

type
  TCompareDatabase = class
  private
    FConexaoOrigem, FConexaoDestino: TConexao;
    FdmConexao: TdmConexao;
    FBarraDeProgresso: TBarraDeProgresso;
    //Utilitarios
    procedure SetValoresIniciaisProgresso(AMin, AMax: integer);
    procedure SetPosicao(APosicao: integer);
    procedure GravaArquivoLocal(ATexto, AArquivo: string);
    function ExtrairMetadataBanco(AConexao: TFDConnection): string;
    function MontaMetadata(AConexao: TFDConnection): string;
    function ExecutaComparacao(ASchemaOrigem, ASchemaDestino: string): TResposta;
    function ExtrairElementosDoBanco(AConexao: TFDConnection; ASqlIndex: TSqlCollection; ATabela: string): string; overload;
    function ExtrairElementosDoBanco(AConexao: TFDConnection; ASqlIndex: TSqlCollection): string; overload;
    function CompararObjetos(AObjetosOrigem, AObjetosDestino, AObjetoVerificacao: string): string;
    function ComparaObjeto(AObjetoOrigem, AObjetoDestino: string): string;
    function VerificaTriggerContemSequence(ATrigger, AGeneretor: string): boolean;
    function ExtrairCampoSequence(ATrigger: string): string;
    function DesmembrarTextoASCII(ATexto: string): TStringList;
    function GetSequenceFromTrigger(ATrigger: string): string;
    function GetSequenceFieldFromTrigger(ATrigger: string): string;
    function OrdenaEstruturaAtualizacao(ASchemaDaNovaEstrutura: string): string;
    function AplicarAtualizacao(AEstruturaOrganizadaJSON: string): TResposta;

    function CompararTabelas(ATabelaOrigenJson, ATabelaDestinoJson: string): string;
    function CompararCampos(ACamposOrigenJson, ACamposDestinoJson, ADiferencasConstraints,
      ADiferencasIndices, ADiferencaTriggers: string): string;
    function CompararConstraints(AConstraintsOrigemJson, AConstraintsDestinoJson: string): string;
    function CompararIndices(AIndicesOrigenJson, AIndicesDestinoJson: string): string;
    function CompararTriggers(ATriggersOrigenJson, ATriggersDestinoJson: string): string;
    function CompararSequences(ASequencesOrigenJson, ASequencesDestinoJson: string): string;
    function AdicionaSeparador(AText: string): string;
  public
    //Banco de origem
    procedure SetOrigemConexao(AServer, APort, ADatabase, AUsername, APassword: string);
    function TestarOrigem: TResposta;
    function ExtrairMetadataOrigem: string;

    //Banco de destino
    procedure SetDestinoConexao(AServer, APort, ADatabase, AUsername, APassword: string);
    function TestarDestino: TResposta;
    function ExtrairMetadataDestino: string;

    function VerificarDiferencaEntreBancos(ASchemaOrigem, ASchemaDestino: string): boolean;
    procedure AdicionarBarraDeProgresso(var AProgressBar: TProgressBar);
    constructor Create;
    destructor Destroy; override;
  end;

const
  EmptyJSONObject = '{}';

implementation

{ TCompareDatabase }

procedure TCompareDatabase.AdicionarBarraDeProgresso(
  var AProgressBar: TProgressBar);
begin
  FBarraDeProgresso := TBarraDeProgresso.Create(AProgressBar);
end;

function TCompareDatabase.AplicarAtualizacao(AEstruturaOrganizadaJSON: string): TResposta;
var
  lJsonDeAtaulizacao, lJsonAtual: TJSONObject;
  lRespostaAtual: TResposta;
  I: Integer;
  lRetorno: string;
begin
  //Reuqer fatoração, está muito verboso
  try
    lJsonDeAtaulizacao := TJSONObject.ParseJSONValue(AEstruturaOrganizadaJSON) as TJSONObject;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_sequences') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_sequences').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_sequences').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.DropSequence(lJsonAtual.GetValue<string>('sequence_name'), lJsonAtual.GetValue<string>('trigger_name'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('sequence_name')+' removido; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('sequence_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('sequence_name')+' erro na remoção: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_triggers') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_triggers').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_triggers').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.DropTrigger(lJsonAtual.GetValue<string>('trigger_name'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('trigger_name')+' removido; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('trigger_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('trigger_name')+' erro na remoção: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_indices') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_indices').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_indices').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.DropIndice(lJsonAtual.GetValue<string>('index_name'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('index_name')+' removido; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('index_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('index_name')+' erro na remoção: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_constraints') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_constraints').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_constraints').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.DropConstraint(lJsonAtual.GetValue<string>('constraint_name'), lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_constraints').Items[I].GetValue<string>('tabela'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('constraint_name')+' removido; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('constraint_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('constraint_name')+' erro na remoção: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_fields') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_fields').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_fields').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.DropField(lJsonAtual.GetValue<string>('field_name'), lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_fields').Items[I].GetValue<string>('tabela'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('field_name')+' removido; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('field_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('field_name')+' erro na remoção: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_tables') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_tables').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('drop_tables').Items[I].ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.DropTable(lJsonAtual.GetValue<string>('tabela'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' removido; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' erro na remoção: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('create_tables') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('create_tables').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('create_tables').Items[I].ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.CreateTable(lJsonAtual.GetValue<string>('tabela'), lJsonAtual.GetValue<TJSONObject>('alteracoes').GetValue<TJSONArray>('campos').ToJSON);
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' criada; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' erro na cração: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_fields') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_fields').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_fields').Items[I].ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.AlterOrCreateFields(lJsonAtual.GetValue<string>('tabela'),
                                                         lJsonAtual.GetValue<TJSONObject>('objeto').ToJSON,
                                                         lJsonAtual.ToJSON);
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' atualizado; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('tabela')+' erro na atualização: '+lRespostaAtual.Conteudo+'; ';
          end;
          else lRetorno := lRetorno + ' Resultado do processo: '+lRespostaAtual.Conteudo+'; ';
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_constraints') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_constraints').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_constraints').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.CreateConstraint(lJsonAtual.GetValue<string>('constraint_name'),
                                                      lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_constraints').Items[I].GetValue<string>('tabela'),
                                                      lJsonAtual.GetValue<string>('field_name'),
                                                      lJsonAtual.GetValue<string>('relation_name'),
                                                      lJsonAtual.GetValue<string>('foreign_field_name'),
                                                      lJsonAtual.GetValue<string>('constraint_type'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('constraint_name')+' atualizado; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('constraint_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('constraint_name')+' erro na atualização: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_indices') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_indices').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_indices').Items[I].ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.AlterOrCreateIndice(lJsonAtual.GetValue<string>('index_name'),
                                                         lJsonAtual.GetValue<string>('relation_name'),
                                                         lJsonAtual.GetValue<string>('expression_source'),
                                                         lJsonAtual.GetValue<string>('field_name'),
                                                         lJsonAtual.GetValue<string>('index_type'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('index_name')+' atualizado; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('index_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('index_name')+' erro na atualização: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_sequences') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_sequences').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_sequences').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.AlterOrCreateSequence(lJsonAtual.GetValue<string>('sequence_name'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('sequence_name')+' atualizado; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('sequence_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('sequence_name')+' erro na atualização: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    if lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_triggers') <> nil then
      for I := 0 to lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_triggers').Count - 1 do
      begin
        lJsonAtual :=  TJSONObject.ParseJSONValue(lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_triggers').Items[I].GetValue<TJSONObject>('objeto').ToJSON) as TJSONObject;
        lRespostaAtual := FdmConexao.CreateTrigger(lJsonDeAtaulizacao.GetValue<TJSONArray>('alter_triggers').Items[I].GetValue<string>('tabela'),
                                                   lJsonAtual.GetValue<string>('trigger_name'),
                                                   lJsonAtual.GetValue<string>('trigger_inactive') = '0',
                                                   StrToIntDef(lJsonAtual.GetValue<string>('trigger_type'), 1),
                                                   StrToIntDef(lJsonAtual.GetValue<string>('trigger_sequence'), 0),
                                                   lJsonAtual.GetValue<string>('trigger_source'));
        case lRespostaAtual.Codigo of
          200: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('trigger_name')+' atualizado; ';
          end;
          204: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('trigger_name')+' não encontrado; ';
          end;
          400, 500: begin
            lRetorno := lRetorno + lJsonAtual.GetValue<string>('trigger_name')+' erro na atualização: '+lRespostaAtual.Conteudo+'; ';
          end;
        end;
        lJsonAtual.Free;
      end;
    Result.Codigo := 200;
    Result.Conteudo := lRetorno;
  finally
    lJsonDeAtaulizacao.Free;
  end;
end;

function TCompareDatabase.ComparaObjeto(AObjetoOrigem, AObjetoDestino: string): string;
var
  lCampoOrigem, lCampoDestino: TJSONObject;
  lPairsOrigem, lPairsDestino: TJSONPair;
  I: Integer;
begin
  Result := EmptyStr;
  lCampoOrigem := TJSONObject.ParseJSONValue(AObjetoOrigem) as TJSONObject;
  lCampoDestino := TJSONObject.ParseJSONValue(AObjetoDestino) as TJSONObject;
  try
    if lCampoOrigem.Count <> lCampoDestino.Count then
      Exit(EmptyStr);

    //for lChaveValor in lCampoOrigem do
    for I := 0 to lCampoOrigem.Count - 1 do
    begin
      lPairsOrigem := lCampoOrigem.Pairs[I];
      lPairsDestino := lCampoDestino.Pairs[I];
      if lPairsOrigem.JsonString.ToJSON = '"controle"' then
        continue;

      if not (UpperCase(lPairsOrigem.JsonValue.GetValue<string>()) = UpperCase(lPairsDestino.JsonValue.GetValue<string>())) then
        Result := AObjetoOrigem;
    end;
  finally
    lCampoOrigem.Free;
    lCampoDestino.Free;
  end;
end;

function TCompareDatabase.CompararCampos(ACamposOrigenJson, ACamposDestinoJson,
   ADiferencasConstraints, ADiferencasIndices, ADiferencaTriggers: string): string;
var
  lCamposComDiferencaEncontrada, lNovaListaDeCampos: string;
  lListaDeCamposComDiferenca, lListaDeCamposComDiferencaEDependencias: TJSONArray;

  lJsonArray, lDependenciaConstraint, lDependenciaIndices, lDependenciaTriggers: TJSONArray;
  lCampoComDiferenca: TJSONObject;
  lLista: TStringList;
  A, I, O: Integer;
begin
  lNovaListaDeCampos := EmptyStr;
  lCamposComDiferencaEncontrada := CompararObjetos(ACamposOrigenJson, ACamposDestinoJson, 'field_name');
  //Verificar dependencias ao alterar o campo
  if not (lCamposComDiferencaEncontrada.IsEmpty) then
  begin
    lListaDeCamposComDiferenca := TJSONObject.ParseJSONValue(lCamposComDiferencaEncontrada) as TJSONArray;
    try
      lListaDeCamposComDiferencaEDependencias := TJSONArray.Create;
      for I := 0 to lListaDeCamposComDiferenca.Count - 1 do
      begin
        lCampoComDiferenca := TJSONObject.ParseJSONValue(lListaDeCamposComDiferenca.Items[I].ToJSON) as TJSONObject;
        if not (ADiferencasConstraints.IsEmpty) then
        begin
          lJsonArray := TJSONObject.ParseJSONValue(ADiferencasConstraints) as TJSONArray;
          lDependenciaConstraint := TJSONArray.Create;
          for A := 0 to lJsonArray.Count - 1 do
          begin
            if ContainsText(lJsonArray.Items[A].GetValue<string>('field_name'), AdicionaSeparador(lCampoComDiferenca.GetValue<TJSONObject>('objeto').GetValue<string>('field_name'))) then
              lDependenciaConstraint.Add(TJSONObject.ParseJSONValue(lJsonArray.Items[A].ToJSON) as TJSONObject);
          end;
          lCampoComDiferenca.AddPair('constraints', lDependenciaConstraint);
          lJsonArray.Free;
        end;
        if not (ADiferencasIndices.IsEmpty) then
        begin
          lJsonArray := TJSONObject.ParseJSONValue(ADiferencasIndices) as TJSONArray;
          lDependenciaIndices := TJSONArray.Create;
          for A := 0 to lJsonArray.Count - 1 do
          begin
            if lJsonArray.Items[A].GetValue<string>('field_name') <> EmptyStr then
            begin
              if ContainsText(lJsonArray.Items[A].GetValue<string>('field_name'), lCampoComDiferenca.GetValue<TJSONObject>('objeto').GetValue<string>('field_name')) then
                lDependenciaIndices.Add(TJSONObject.ParseJSONValue(lJsonArray.Items[A].ToJSON) as TJSONObject);
            end
            else
            begin
              lLista := DesmembrarTextoASCII(lJsonArray.Items[A].GetValue<string>('expression_source'));
              for O := 0 to lLista.Count - 1 do
              begin
                if UpperCase(lLista[O]) = lCampoComDiferenca.GetValue<TJSONObject>('objeto').GetValue<string>('field_name') then
                begin
                  lDependenciaIndices.Add(TJSONObject.ParseJSONValue(lJsonArray.Items[A].ToJSON) as TJSONObject);
                  Break;
                end;
              end;
              lLista.Free;
            end;
          end;
          lCampoComDiferenca.AddPair('indices', lDependenciaIndices);
          lJsonArray.Free;
        end;
        if not (ADiferencaTriggers.IsEmpty) then
        begin
          lJsonArray := TJSONObject.ParseJSONValue(ADiferencaTriggers) as TJSONArray;
          lDependenciaTriggers := TJSONArray.Create;
          for A := 0 to lJsonArray.Count - 1 do
          begin
            lLista := DesmembrarTextoASCII(lJsonArray.Items[A].GetValue<string>('trigger_source'));
            for O := 0 to lLista.Count - 1 do
            begin
              if UpperCase(lLista[O]) = lCampoComDiferenca.GetValue<TJSONObject>('objeto').GetValue<string>('field_name') then
              begin
                lDependenciaTriggers.Add(TJSONObject.ParseJSONValue(lJsonArray.Items[A].ToJSON) as TJSONObject);
                Break;
              end;
            end;
            lLista.Free;
          end;
          lCampoComDiferenca.AddPair('triggers', lDependenciaTriggers);
          lJsonArray.Free;
        end;
        lListaDeCamposComDiferencaEDependencias.Add(lCampoComDiferenca);
      end;
      lNovaListaDeCampos := lListaDeCamposComDiferencaEDependencias.ToJSON;
    finally
      lListaDeCamposComDiferencaEDependencias.Free;
    end;
  end;
  Result := lNovaListaDeCampos;
end;

function TCompareDatabase.CompararConstraints(AConstraintsOrigemJson, AConstraintsDestinoJson: string): string;
begin
  Result := CompararObjetos(AConstraintsOrigemJson, AConstraintsDestinoJson, 'constraint_name');
end;

function TCompareDatabase.CompararIndices(AIndicesOrigenJson, AIndicesDestinoJson: string): string;
begin
  Result := CompararObjetos(AIndicesOrigenJson, AIndicesDestinoJson, 'index_name');
end;

function TCompareDatabase.CompararTriggers(ATriggersOrigenJson, ATriggersDestinoJson: string): string;
begin
  Result := CompararObjetos(ATriggersOrigenJson, ATriggersDestinoJson, 'trigger_name');
end;

function TCompareDatabase.CompararObjetos(AObjetosOrigem, AObjetosDestino,
  AObjetoVerificacao: string): string;
var
  lObjetosOrigem, lObjetosDestino, lObjetosAlterados: TJSONArray;
  I, O: Integer;
  lObjetosParaAlterar: string;
  lObjetoEncontrado: boolean;
begin
  Result := EmptyStr;
  lObjetosAlterados := TJSONArray.Create;
  lObjetosOrigem := TJSONObject.ParseJSONValue(AObjetosOrigem) as TJSONArray;
  lObjetosDestino := TJSONObject.ParseJSONValue(AObjetosDestino) as TJSONArray;
  try
    for I := 0 to lObjetosOrigem.Count -1 do
    begin
      lObjetosParaAlterar := EmptyStr;
      lObjetoEncontrado := False;

      for O := 0 to lObjetosDestino.Count - 1 do //Não é o ideal de perfomace mas evita o erro de index inexistente
      begin
        if lObjetosDestino.Items[O].GetValue<string>(AObjetoVerificacao, '') = lObjetosOrigem.Items[I].GetValue<string>(AObjetoVerificacao, '')  then
        begin
          lObjetosParaAlterar := ComparaObjeto(lObjetosOrigem.Items[I].ToJSON, lObjetosDestino.Items[O].ToJSON);
          lObjetoEncontrado := True;
          Break;
        end;
      end;

      if not (lObjetoEncontrado) then
        lObjetosParaAlterar := lObjetosOrigem.Items[I].ToJSON;
      if not (lObjetosParaAlterar.IsEmpty) then
        lObjetosAlterados.Add(TJSONObject.Create
                                         .AddPair('operacao', TJSONString.Create('update'))
                                         .AddPair('objeto', TJSONObject.ParseJSONValue(lObjetosParaAlterar) as TJSONObject));
    end;
    for O := 0 to lObjetosDestino.Count - 1 do
    begin
      lObjetoEncontrado := False;
      for I := 0 to lObjetosOrigem.Count - 1 do //Não é o ideal de perfomace mas evita o erro de index inexistente
      begin
        if lObjetosDestino.Items[O].GetValue<string>(AObjetoVerificacao, '') = lObjetosOrigem.Items[I].GetValue<string>(AObjetoVerificacao, '')  then
        begin
          lObjetoEncontrado := True;
          break;
        end;
      end;
      if not (lObjetoEncontrado) then
        lObjetosAlterados.Add(TJSONObject.Create
                                        .AddPair('operacao', TJSONString.Create('delete'))
                                        .AddPair('objeto', TJSONObject.ParseJSONValue(lObjetosDestino.Items[O].ToJSON) as TJSONObject));
    end;
    if lObjetosAlterados.Count > 0 then
      Result := lObjetosAlterados.ToJSON;
  finally
    lObjetosOrigem.Free;
    lObjetosDestino.Free;
    lObjetosAlterados.Free;
  end;
end;

function TCompareDatabase.CompararSequences(ASequencesOrigenJson, ASequencesDestinoJson: string): string;
begin
  Result := CompararObjetos(ASequencesOrigenJson, ASequencesDestinoJson, 'sequence_name');;
end;

function TCompareDatabase.ExtrairCampoSequence(ATrigger: string): string;
begin
  Result := UpperCase(GetSequenceFieldFromTrigger(ATrigger));
end;

function TCompareDatabase.VerificaTriggerContemSequence(ATrigger,
  AGeneretor: string): boolean;
begin
  Result := GetSequenceFromTrigger(UpperCase(ATrigger)) = UpperCase(AGeneretor);
end;

function TCompareDatabase.CompararTabelas(ATabelaOrigenJson, ATabelaDestinoJson: string): string;
var
  lTabelaOrigem, lTabelaDestino, lDiferencas: TJSONObject;
  lDiferencasCampos, lDiferencasConstraints, lDiferencasIndices, lDiferencaTriggers, lDiferencaSequences: string;
  I: Integer;
begin
  Result := EmptyStr;
  lTabelaOrigem := TJSONObject.ParseJSONValue(ATabelaOrigenJson) as TJSONObject;
  lTabelaDestino := TJSONObject.ParseJSONValue(ATabelaDestinoJson) as TJSONObject;
  try
    //Constraints
    lDiferencasConstraints := CompararConstraints(lTabelaOrigem.GetValue('constraints').ToJSON, lTabelaDestino.GetValue('constraints').ToJSON);
    //Indices
    lDiferencasIndices := CompararIndices(lTabelaOrigem.GetValue('indices').ToJSON, lTabelaDestino.GetValue('indices').ToJSON);
    //Triggers
    lDiferencaTriggers := CompararTriggers(lTabelaOrigem.GetValue('triggers').ToJSON, lTabelaDestino.GetValue('triggers').ToJSON);
    //Sequences
    lDiferencaSequences := CompararSequences(lTabelaOrigem.GetValue('sequences').ToJSON, lTabelaDestino.GetValue('sequences').ToJSON);
    //Campos
    lDiferencasCampos := CompararCampos(lTabelaOrigem.GetValue('campos').ToJSON, lTabelaDestino.GetValue('campos').ToJSON,
                                        lTabelaOrigem.GetValue('constraints').ToJSON,
                                        lTabelaOrigem.GetValue('indices').ToJSON,
                                        lTabelaOrigem.GetValue('triggers').ToJSON);
    lDiferencas := TJSONObject.Create
                              .AddPair('campos', TJSONObject.ParseJSONValue(lDiferencasCampos) as TJSONArray)
                              .AddPair('constraints', TJSONObject.ParseJSONValue(lDiferencasConstraints) as TJSONArray)
                              .AddPair('indices', TJSONObject.ParseJSONValue(lDiferencasIndices) as TJSONArray)
                              .AddPair('triggers', TJSONObject.ParseJSONValue(lDiferencaTriggers) as TJSONArray)
                              .AddPair('sequences', TJSONObject.ParseJSONValue(lDiferencaSequences) as TJSONArray);
    Result := lDiferencas.ToJSON;
  finally
    lTabelaOrigem.Free;
    lTabelaDestino.Free;
    lDiferencas.Free;
  end;
end;

function TCompareDatabase.VerificarDiferencaEntreBancos(ASchemaOrigem, ASchemaDestino: string): boolean;
var
  lResposta, lRespostaAplicarAtualizacao: TResposta;
  tempEstruturaOrdenada: string;
begin
  lResposta := ExecutaComparacao(ASchemaOrigem, ASchemaDestino);
  if lResposta.Codigo = 200 then
  begin
    GravaArquivoLocal(lResposta.Conteudo, 'comparacao_'+FormatDateTime('hhnnss', now)+'_');
    //Apllica diferencas
    tempEstruturaOrdenada := OrdenaEstruturaAtualizacao(lResposta.Conteudo);
    GravaArquivoLocal(tempEstruturaOrdenada, 'ordenado_'+FormatDateTime('hhnnss', now)+'_');
    lRespostaAplicarAtualizacao := AplicarAtualizacao(tempEstruturaOrdenada);
    GravaArquivoLocal(lRespostaAplicarAtualizacao.Conteudo, 'execucao_'+FormatDateTime('hhnnss', now)+'_');
    Result := lRespostaAplicarAtualizacao.Codigo = 200;
  end
  else
  begin
    GravaArquivoLocal(lResposta.Conteudo, 'error_'+FormatDateTime('hhnnss', now)+'_');
    Result := False;
  end;
end;

constructor TCompareDatabase.Create;
begin
  FdmConexao := TdmConexao.Create(nil);
end;

function TCompareDatabase.DesmembrarTextoASCII(ATexto: string): TStringList;
var
  lTextoManipulado, lPalavra: string;
  I: Integer;
begin
  Result := TStringList.Create;
  lTextoManipulado := Trim(ATexto);
  if not (lTextoManipulado.IsEmpty) then
  begin
    lPalavra := EmptyStr;
    for I := 0 to Length(lTextoManipulado) - 1 do
    begin
      // Verifica se é uma letra ou número sem acentuação ou caracteres especiais
      if (lTextoManipulado[I] = '_') or (TCharacter.IsLetterOrDigit(lTextoManipulado[I]) and not TCharacter.IsWhiteSpace(lTextoManipulado[I])) then
        lPalavra := lPalavra + lTextoManipulado[I]
      else
      begin
        if not (lPalavra.IsEmpty) then
        begin
          Result.Add(lPalavra);
        end;
        lPalavra := EmptyStr;
      end;
    end;
  end;
end;

destructor TCompareDatabase.Destroy;
begin
  if Assigned(FBarraDeProgresso) then
    FBarraDeProgresso.Free;
  FdmConexao.Free;
  inherited;
end;

function TCompareDatabase.ExtrairElementosDoBanco(AConexao: TFDConnection;
  ASqlIndex: TSqlCollection; ATabela: string): string;
var
  lSql: string;
begin
  lSql := FdmConexao.GetScript(ASqlIndex);
  Result := FdmConexao.Select(lSql.Replace('$TABELA', ATabela), AConexao);
end;

function TCompareDatabase.ExtrairElementosDoBanco(AConexao: TFDConnection;
  ASqlIndex: TSqlCollection): string;
begin
  Result := FdmConexao.Select(ASqlIndex, AConexao);
end;

function TCompareDatabase.ExecutaComparacao(ASchemaOrigem,
  ASchemaDestino: string): TResposta;
var
  lSchemaOrigem, lSchemaDestino: TJSONArray;
  lAlteradosResposta, lNovasTabelas, lJsonOrigem, lJsonDestino: string;
  lJsonParaExecucao: TJSONArray;
  I: Integer;
  O: Integer;
  lTabelaEncontrada: boolean;
begin
  Result.Codigo := 0;
  lJsonParaExecucao := TJSONArray.Create;
  lSchemaOrigem := TJSONObject.ParseJSONValue(ASchemaOrigem) as TJSONArray;
  lSchemaDestino := TJSONObject.ParseJSONValue(ASchemaDestino) as TJSONArray;
  try
    if (lSchemaOrigem.Count = 0) or (lSchemaDestino.Count = 0) then
    begin
      Result.Codigo := 204;
      Result.Conteudo := 'Schema "'+IfThen(lSchemaOrigem.Count = 0, 'Origem', 'Destino')+'" não carregado';
      Exit;
    end;
    SetValoresIniciaisProgresso(0, lSchemaOrigem.Count);
    for I := 0 to lSchemaOrigem.Count -1 do
    begin
      SetPosicao(I+1);
      lAlteradosResposta := EmptyStr;
      lJsonDestino := EmptyStr;
      lJsonOrigem := lSchemaOrigem.Items[I].ToJSON;
      for O := 0 to lSchemaDestino.Count - 1 do
      begin
        if lSchemaOrigem.Items[I].GetValue<string>('tabela', '') = lSchemaDestino.Items[O].GetValue<string>('tabela', '') then
        begin
          lJsonDestino := lSchemaDestino.Items[O].ToJSON;
          Break;
        end;
      end;

      //Verificar tabelas existentes que foram alterados
      if not (lJsonDestino.IsEmpty) then
      begin
        lAlteradosResposta := CompararTabelas(lJsonOrigem, lJsonDestino);
        if not (lAlteradosResposta.IsEmpty) then
          lJsonParaExecucao.Add(TJSONObject.Create
            .AddPair('operacao', IfThen(lAlteradosResposta = EmptyJSONObject, 'none', 'update'))
            .AddPair('tabela', lSchemaOrigem.Items[I].GetValue<string>('tabela', ''))
            .AddPair('alteracoes', TJSONObject.ParseJSONValue(lAlteradosResposta) as TJSONObject));
      end
      else
        //Verificar tabelas novas que não existem
        lJsonParaExecucao.Add(TJSONObject.Create
          .AddPair('operacao', 'insert')
          .AddPair('tabela', lSchemaOrigem.Items[I].GetValue<string>('tabela', ''))
          .AddPair('alteracoes', TJSONObject.ParseJSONValue(lSchemaOrigem.Items[I].ToJSON) as TJSONObject));
    end;
    //Verificar tabelas que foram removidas
    for O := 0 to lSchemaDestino.Count - 1 do
    begin
      lTabelaEncontrada := False;
      for I := 0 to lSchemaOrigem.Count -1 do
      begin
        if lSchemaOrigem.Items[I].GetValue<string>('tabela', '') = lSchemaDestino.Items[O].GetValue<string>('tabela', '') then
          lTabelaEncontrada := True;
      end;
      if not (lTabelaEncontrada) then
        lJsonParaExecucao.Add(TJSONObject.Create
          .AddPair('operacao', 'delete')
          .AddPair('tabela', lSchemaDestino.Items[O].GetValue<string>('tabela', ''))
          .AddPair('alteracoes', TJSONObject.ParseJSONValue(lSchemaDestino.Items[O].ToJSON) as TJSONObject));
    end;
    if lJsonParaExecucao.Count > 0 then
    begin
      Result.Codigo := 200;
      Result.Conteudo := lJsonParaExecucao.ToJSON;
    end;
  finally
    lSchemaOrigem.Free;
    lSchemaDestino.Free;
    lJsonParaExecucao.Free;
  end;
end;

function TCompareDatabase.OrdenaEstruturaAtualizacao(ASchemaDaNovaEstrutura: string): string;
var
  lAlteracoesDaEstrutura,
  lSequences, lTriggers, lConstraints, lIndices, lFields: TJSONArray;
  lDropTriggers, lDropConstraints, lDropIndices, lDropSequence, lDropTables, lDropFields,
  lAlterSequence, lCreateTables, lAlterFields, lAlterConstraints, lAlterTriggers, lAlterIndices: TJSONArray;
  I, O, U: Integer;
  lSequencesJson, lTriggersJson, lConstraintsJson, lIndicesJson, lFieldsJson, lTableJson: string;
  lEstruturaOrganizada: TJSONObject;
begin
  lAlteracoesDaEstrutura := TJSONObject.ParseJSONValue(ASchemaDaNovaEstrutura) as TJSONArray;
  lEstruturaOrganizada := TJSONObject.Create;
  try
    //Classificando ordem das alterações
    lDropTriggers     := TJSONArray.Create;
    lDropConstraints  := TJSONArray.Create;
    lDropIndices      := TJSONArray.Create;
    lDropSequence     := TJSONArray.Create;
    lDropTables       := TJSONArray.Create;
    lDropFields       := TJSONArray.Create;

    lAlterSequence    := TJSONArray.Create;
    lCreateTables     := TJSONArray.Create;
    lAlterFields      := TJSONArray.Create;
    lAlterConstraints := TJSONArray.Create;
    lAlterTriggers    := TJSONArray.Create;
    lAlterIndices     := TJSONArray.Create;
    for I := 0 to lAlteracoesDaEstrutura.Count - 1 do
    begin
      //Executar procedimentos na ordem para evitar conflitos
      if not (lAlteracoesDaEstrutura.Items[I].GetValue<string>('operacao', '') = 'none') then
      begin
        if lAlteracoesDaEstrutura.Items[I].GetValue<string>('operacao', '') = 'update' then
        begin
          if lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue('sequences') <> nil then
          begin
            lSequencesJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue<TJSONArray>('sequences').ToJSON;
            lSequences := TJSONObject.ParseJSONValue(lSequencesJson) as TJSONArray;
            for O := 0 to lSequences.Count - 1 do
            begin
              //Inserir informações da tabela em questão
              lSequences.Items[O].GetValue<TJSONObject>().AddPair('tabela', lAlteracoesDaEstrutura.Items[I].GetValue<string>('tabela', ''));
              //Alterar/Criar - Sequences
              if lSequences.Items[O].GetValue<string>('operacao', '') = 'update' then
                lAlterSequence.Add(TJSONObject.ParseJSONValue(lSequences.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject);
              //Drop - Sequences
              if lSequences.Items[O].GetValue<string>('operacao', '') = 'delete' then
                lDropSequence.Add(TJSONObject.ParseJSONValue(lSequences.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject);
            end;
            lSequences.Free;
          end;

          if lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue('triggers') <> nil then
          begin
            lTriggersJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue<TJSONArray>('triggers').ToJSON;
            lTriggers := TJSONObject.ParseJSONValue(lTriggersJson) as TJSONArray;
            for O := 0 to lTriggers.Count - 1 do
            begin
              //Inserir informações da tabela em questão
              lTriggers.Items[O].GetValue<TJSONObject>().AddPair('tabela', lAlteracoesDaEstrutura.Items[I].GetValue<string>('tabela', ''));
              //Alterar/Criar - Triggers
              if lTriggers.Items[O].GetValue<string>('operacao', '') = 'update' then
                lAlterTriggers.Add(TJSONObject.ParseJSONValue(lTriggers.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject);
              //Drop - Triggers
              if lTriggers.Items[O].GetValue<string>('operacao', '') = 'delete' then
                lDropTriggers.Add(TJSONObject.ParseJSONValue(lTriggers.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject)
            end;
            lTriggers.Free;
          end;

          if lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue('constraints') <> nil then
          begin
            lConstraintsJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue<TJSONArray>('constraints').ToJSON;
            lConstraints := TJSONObject.ParseJSONValue(lConstraintsJson) as TJSONArray;
            for O := 0 to lConstraints.Count - 1 do
            begin
              //Inserir informações da tabela em questão
              lConstraints.Items[O].GetValue<TJSONObject>().AddPair('tabela', lAlteracoesDaEstrutura.Items[I].GetValue<string>('tabela', ''));
              //Alterar/Criar - Constraints/Chaves
              if lConstraints.Items[O].GetValue<string>('operacao', '') = 'update' then
                lAlterConstraints.Add(TJSONObject.ParseJSONValue(lConstraints.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject);
              //Drop - Constraints/Chaves
              if lConstraints.Items[O].GetValue<string>('operacao', '') = 'delete' then
                lDropConstraints.Add(TJSONObject.ParseJSONValue(lConstraints.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject)
            end;
            lConstraints.Free;
          end;

          if lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue('indices') <> nil then
          begin
            lIndicesJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue<TJSONArray>('indices').ToJSON;
            lIndices := TJSONObject.ParseJSONValue(lIndicesJson) as TJSONArray;
            for O := 0 to lIndices.Count - 1 do
            begin
              //Inserir informações da tabela em questão
              lIndices.Items[O].GetValue<TJSONObject>().AddPair('tabela', lAlteracoesDaEstrutura.Items[I].GetValue<string>('tabela', ''));
              //Alterar/Criar - indices
              if lIndices.Items[O].GetValue<string>('operacao', '') = 'update' then
                lAlterIndices.Add(TJSONObject.ParseJSONValue(lIndices.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject);
              //Drop - Indices
              if lIndices.Items[O].GetValue<string>('operacao', '') = 'delete' then
                lDropIndices.Add(TJSONObject.ParseJSONValue(lIndices.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject)
            end;
            lIndices.Free;
          end;

          if lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue('campos') <> nil then
          begin
            lFieldsJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>('alteracoes').GetValue<TJSONArray>('campos').ToJSON;
            lFields := TJSONObject.ParseJSONValue(lFieldsJson) as TJSONArray;
            for O := 0 to lFields.Count - 1 do
            begin
              //Inserir informações da tabela em questão
              lFields.Items[O].GetValue<TJSONObject>().AddPair('tabela', lAlteracoesDaEstrutura.Items[I].GetValue<string>('tabela', ''));
              //Alterar/Criar - Campos
              if lFields.Items[O].GetValue<string>('operacao', '') = 'update' then
                lAlterFields.Add(TJSONObject.ParseJSONValue(lFields.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject);
              //Drop - Campos
              if lFields.Items[O].GetValue<string>('operacao', '') = 'delete' then
                lDropFields.Add(TJSONObject.ParseJSONValue(lFields.Items[O].GetValue<TJSONObject>().ToJSON) as TJSONObject)
            end;
            lFields.Free;
          end;
        end;
        //Deletar tabela e suas dependencias
        if lAlteracoesDaEstrutura.Items[I].GetValue<string>('operacao', '') = 'delete' then
        begin
          lTableJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>().ToJSON;
          lDropTables.Add(TJSONObject.ParseJSONValue(lTableJson) as TJSONObject);
        end;
        //Criar tabela e suas dependencias
        if lAlteracoesDaEstrutura.Items[I].GetValue<string>('operacao', '') = 'insert' then
        begin
          lTableJson := lAlteracoesDaEstrutura.Items[I].GetValue<TJSONObject>().ToJSON;
          lCreateTables.Add(TJSONObject.ParseJSONValue(lTableJson) as TJSONObject);
        end;
      end;
    end;
    lEstruturaOrganizada
      .AddPair('drop_sequences', lDropSequence)
      .AddPair('drop_triggers', lDropTriggers)
      .AddPair('drop_indices', lDropIndices)
      .AddPair('drop_constraints', lDropConstraints)
      .AddPair('drop_fields', lDropFields)
      .AddPair('drop_tables', lDropTables)
      .AddPair('create_tables', lCreateTables)
      .AddPair('alter_fields', lAlterFields)
      .AddPair('alter_constraints', lAlterConstraints)
      .AddPair('alter_indices', lAlterIndices)
      .AddPair('alter_sequences', lAlterSequence)
      .AddPair('alter_triggers', lAlterTriggers);
     Result := lEstruturaOrganizada.ToJSON;
  finally
    lEstruturaOrganizada.Free;
    lAlteracoesDaEstrutura.Free;
  end;
end;

function TCompareDatabase.ExtrairMetadataBanco(AConexao: TFDConnection): string;
var
  lJsonSchema: TJSONArray;
begin
  Result := MontaMetadata(AConexao);
end;

function TCompareDatabase.ExtrairMetadataDestino: string;
begin
  Result := ExtrairMetadataBanco(FdmConexao.GetConexaoDestino);
end;

function TCompareDatabase.ExtrairMetadataOrigem: string;
begin
  Result := ExtrairMetadataBanco(FdmConexao.GetConexaoOrigem);
end;

function TCompareDatabase.GetSequenceFieldFromTrigger(ATrigger: string): string;
var
  lLista: TStringList;
  I: Integer;
begin
  lLista := DesmembrarTextoASCII(ATrigger);
  for I := 0 to lLista.Count - 1 do
  begin
    if I - 3 > 0 then
    begin
      //Esquema 1 usando SEQUENCE
      if (UpperCase(lLista[I - 1]) = 'NEW') and (UpperCase(lLista[I + 1]) = 'NEXT') then
      begin
        Result := lLista[I];
        Break;
      end else
      //Esquema 2 usando Generator
      if (UpperCase(lLista[I - 1]) = 'NEW') and (UpperCase(lLista[I + 1]) = 'GEN_ID') then
      begin
        Result := lLista[I];
        Break;
      end;
    end;
  end;
  lLista.Free;
end;

function TCompareDatabase.GetSequenceFromTrigger(ATrigger: string): string;
var
  lLista: TStringList;
  I: Integer;
begin
  Result := EmptyStr;
  lLista := DesmembrarTextoASCII(ATrigger);
  for I := 0 to lLista.Count - 1 do
  begin
    //Esquema 1 usando SEQUENCE
    if I - 3 > 0 then
    begin
      if (UpperCase(lLista[I - 3]) = 'NEXT') and (UpperCase(lLista[I - 2]) = 'VALUE') and (UpperCase(lLista[I - 1]) = 'FOR') then
      begin
        Result := lLista[I];
        Break;
      end else
      //Esquema 2 usando Generator
      if (UpperCase(lLista[I - 1]) = 'GEN_ID') and (UpperCase(lLista[I + 1]) = '1') then
      begin
        Result := lLista[I];
        Break;
      end;
    end;
  end;
  lLista.Free;
end;

procedure TCompareDatabase.GravaArquivoLocal(ATexto, AArquivo: string);
var
  arq: TextFile;
  vDiretorio: string;
begin
  try
    vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'logs';
    if not DirectoryExists(vDiretorio) then
      ForceDirectories(vDiretorio);
    AssignFile(arq, IncludeTrailingPathDelimiter(vDiretorio)+AArquivo+FormatDateTime('ddMMyyyy',Date)+'.txt');
    {$I-}
    Reset(arq);
    {$I+}
    if (IOResult <> 0)
       then Rewrite(arq) { arquivo não existe e será criado }
    else begin
           CloseFile(arq);
           Append(arq); { o arquivo existe e será aberto para saídas adicionais }
         end;
    WriteLn(Arq, ATexto);
    CloseFile(Arq);
  except

  end;
end;

function TCompareDatabase.AdicionaSeparador(AText: string): string;
begin
  Result := '|'+AText+'|';
end;

function TCompareDatabase.MontaMetadata(AConexao: TFDConnection): string;
var
  lTabelasStr, lJsonRespostaStr, lNomeTabelaAtual: string;
  lJsonSchemaCompleto, lJsonResposta, lTabelasJson, lSequencesJson,
  lCampos, lConstraints, lIndices, lTriggers, lSequences: TJSONArray;
  lTabela, lCampo: TJSONObject;
  I, O, U, K: Integer;
  lReinicarLoop : boolean;
begin
  lJsonSchemaCompleto := TJSONArray.Create;
  try
    lTabelasStr := ExtrairElementosDoBanco(AConexao, scSelectTabelas);
    lTabelasJson := TJSONObject.ParseJSONValue(lTabelasStr) as TJSONArray;
    try
      //Sequences - Caregando todos os generators
      SetValoresIniciaisProgresso(0, lTabelasJson.Count);
      lSequencesJson := TJSONObject.ParseJSONValue(ExtrairElementosDoBanco(AConexao, scSelectSequence)) as TJSONArray;
      for I := 0 to lTabelasJson.Count - 1 do
      begin
        SetPosicao(I+1);
        lNomeTabelaAtual := lTabelasJson.Items[I].GetValue<string>();
        if lNomeTabelaAtual = EmptyStr then
          Continue;
        lTabela := TJSONObject.Create()
          .AddPair('controle', TJSONString.Create('T'+I.ToString))
          .AddPair('tabela', TJSONString.Create(lNomeTabelaAtual));

        //Campos da tabela
        lCampos := TJSONArray.Create;
        lJsonRespostaStr := ExtrairElementosDoBanco(AConexao, scSelectCampos, lNomeTabelaAtual);
        lJsonResposta := TJSONObject.ParseJSONValue(lJsonRespostaStr) as TJSONArray;
        for O := 0 to lJsonResposta.Count - 1 do
        begin
          lCampos.Add(TJSONObject.Create
            .AddPair('controle', TJSONString.Create('T'+I.ToString+'C'+O.ToString))
            .AddPair('field_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_NAME', '')))
            .AddPair('not_null', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('NOT_NULL', '')))
            .AddPair('default_value', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('DEFAULT_VALUE', '')))
            .AddPair('field_length', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_LENGTH', '')))
            .AddPair('field_precision', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_PRECISION', '')))
            .AddPair('field_scale', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_SCALE', '')))
            .AddPair('field_type', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_TYPE', '')))
            .AddPair('field_sub_type', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_SUB_TYPE', '')))
            .AddPair('segment_length', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('SEGMENT_LENGTH', '')))
          );
        end;
        lJsonRespostaStr := '';
        lJsonResposta.Free;

        //Chavers primarias/estrangeiras
        lConstraints := TJSONArray.Create;
        lJsonRespostaStr := ExtrairElementosDoBanco(AConexao, scSelectConstraints, lNomeTabelaAtual);
        lJsonResposta := TJSONObject.ParseJSONValue(lJsonRespostaStr) as TJSONArray;
        for O := 0 to lJsonResposta.Count - 1 do
        begin
          lConstraints.AddElement(TJSONObject.Create
            .AddPair('controle', TJSONString.Create('T'+I.ToString+'K'+O.ToString))
            .AddPair('constraint_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('CONSTRAINT_NAME', '')))
            .AddPair('constraint_type', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('CONSTRAINT_TYPE', '')))
            .AddPair('foreign_key', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FOREIGN_KEY', '')))
            .AddPair('relation_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('RELATION_NAME', '')))
            .AddPair('field_name', TJSONString.Create(AdicionaSeparador(lJsonResposta.Items[O].GetValue<string>('FIELD_NAME', ''))))
            .AddPair('foreign_field_name', TJSONString.Create(AdicionaSeparador(lJsonResposta.Items[O].GetValue<string>('FOREIGN_FIELD_NAME', ''))))
          );
        end;

        lJsonRespostaStr := '';
        lJsonResposta.Free;

        //Indices
        lIndices := TJSONArray.Create;
        lJsonRespostaStr := ExtrairElementosDoBanco(AConexao, scSelectIndices, lNomeTabelaAtual);
        lJsonResposta := TJSONObject.ParseJSONValue(lJsonRespostaStr) as TJSONArray;
        for O := 0 to lJsonResposta.Count - 1 do
        begin
          lIndices.AddElement(TJSONObject.Create
            .AddPair('controle', TJSONString.Create('T'+I.ToString+'I'+O.ToString))
            .AddPair('index_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('INDEX_NAME', '')))
            .AddPair('relation_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('RELATION_NAME', '')))
            .AddPair('expression_source', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('EXPRESSION_SOURCE', '')))
            .AddPair('field_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('FIELD_NAME', '')))
            .AddPair('index_type', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('INDEX_TYPE', '')))
          );
        end;

        lJsonRespostaStr := '';
        lJsonResposta.Free;

        //triggers
        lTriggers := TJSONArray.Create;
        lJsonRespostaStr := ExtrairElementosDoBanco(AConexao, scSelectTriggers, lNomeTabelaAtual);
        lJsonResposta := TJSONObject.ParseJSONValue(lJsonRespostaStr) as TJSONArray;
        for O := 0 to lJsonResposta.Count - 1 do
        begin
          lTriggers.AddElement(TJSONObject.Create
            .AddPair('controle', TJSONString.Create('T'+I.ToString+'T'+O.ToString))
            .AddPair('trigger_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('TRIGGER_NAME', '')))
            .AddPair('relation_name', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('RELATION_NAME', '')))
            .AddPair('trigger_sequence', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('TRIGGER_SEQUENCE', '')))
            .AddPair('trigger_type', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('TRIGGER_TYPE', '')))
            .AddPair('trigger_source', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('TRIGGER_SOURCE', '')))
            .AddPair('trigger_inactive', TJSONString.Create(lJsonResposta.Items[O].GetValue<string>('TRIGGER_INACTIVE', '')))
          );
        end;

        lJsonRespostaStr := '';
        lJsonResposta.Free;

        //Sequences
        lSequences := TJSONArray.Create;
        for O := 0 to lTriggers.Count - 1 do
        begin
          //Verifica se é Before Insert
          if lTriggers.Items[O].GetValue<string>('trigger_type', '') = TTipoTriggers.TIPO_TRIGGER_BI.ToString then
          begin
            for U := 0 to lSequencesJson.Count - 1 do
            begin
              if VerificaTriggerContemSequence(lTriggers.Items[O].GetValue<string>('trigger_source',''),
                                               lSequencesJson.Items[U].GetValue<string>()) then
               lSequences.AddElement(TJSONObject.Create
                  .AddPair('controle', TJSONString.Create('T'+I.ToString+'S'+U.ToString))
                  .AddPair('sequence_name', TJSONString.Create(lSequencesJson.Items[U].GetValue<string>()))
                  .AddPair('autoincrement_field_name', TJSONString.Create(ExtrairCampoSequence(lTriggers.Items[O].GetValue<string>('trigger_source',''))))
                  .AddPair('trigger_name', TJSONString.Create(lTriggers.Items[O].GetValue<string>('trigger_name','')))
                );
            end;
          end;
        end;

        lTabela.AddPair('campos', lCampos);
        lTabela.AddPair('constraints', lConstraints);
        lTabela.AddPair('indices', lIndices);
        lTabela.AddPair('triggers', lTriggers);
        lTabela.AddPair('sequences', lSequences);
        lJsonSchemaCompleto.AddElement(lTabela);
      end;
      result := lJsonSchemaCompleto.ToJSON;
    finally
      lTabelasJson.Free;
      lSequencesJson.Free;
    end;
  finally
    lJsonSchemaCompleto.Free;
  end;
end;

procedure TCompareDatabase.SetPosicao(APosicao: integer);
begin
  if Assigned(FBarraDeProgresso) then
    FBarraDeProgresso.SetPosicao(APosicao);
end;

procedure TCompareDatabase.SetDestinoConexao(AServer, APort, ADatabase,
  AUsername, APassword: string);
begin
  FConexaoDestino.FServer := AServer;
  FConexaoDestino.FPort := APort;
  FConexaoDestino.FDatabase := ADatabase;
  FConexaoDestino.FUsername := AUsername;
  FConexaoDestino.FPassword := APassword;
end;

procedure TCompareDatabase.SetOrigemConexao(AServer, APort, ADatabase,
  AUsername, APassword: string);
begin
  FConexaoOrigem.FServer := AServer;
  FConexaoOrigem.FPort := APort;
  FConexaoOrigem.FDatabase := ADatabase;
  FConexaoOrigem.FUsername := AUsername;
  FConexaoOrigem.FPassword := APassword;
end;

procedure TCompareDatabase.SetValoresIniciaisProgresso(AMin, AMax: integer);
begin
  if Assigned(FBarraDeProgresso) then
    FBarraDeProgresso.SetValoresIniciais(AMin, AMax);
end;

function TCompareDatabase.TestarDestino: TResposta;
begin
  FdmConexao.ConectarDestino(FConexaoDestino.FServer,
                             FConexaoDestino.FPort,
                             FConexaoDestino.FDatabase,
                             FConexaoDestino.FUsername,
                             FConexaoDestino.FPassword);
  if FdmConexao.DestinoConectado then
  begin
    Result.Codigo := 200;
    Result.Conteudo := 'Conectado com sucesso';
    FdmConexao.DesconectarDestino;
  end
  else
  begin
    Result.Codigo := 400;
    Result.Conteudo := FdmConexao.GetUltimoLog;
  end;
end;

function TCompareDatabase.TestarOrigem: TResposta;
begin
  FdmConexao.ConectarOrigem(FConexaoOrigem.FServer,
                            FConexaoOrigem.FPort,
                            FConexaoOrigem.FDatabase,
                            FConexaoOrigem.FUsername,
                            FConexaoOrigem.FPassword);
  if FdmConexao.OrigemConectado then
  begin
    Result.Codigo := 200;
    Result.Conteudo := 'Conectado com sucesso';
    FdmConexao.DesconectarOrigem;
  end
  else
  begin
    Result.Codigo := 400;
    Result.Conteudo := FdmConexao.GetUltimoLog;
  end;
end;

end.
