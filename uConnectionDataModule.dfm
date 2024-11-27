object dmConexao: TdmConexao
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 399
  Width = 575
  object ConexaoOrigem: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'User_Name=sysdba'
      'Password=masterkey')
    UpdateOptions.AssignedValues = [uvAutoCommitUpdates]
    UpdateOptions.AutoCommitUpdates = True
    LoginPrompt = False
    Left = 88
    Top = 56
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    Left = 88
    Top = 144
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 80
    Top = 224
  end
  object ConexaoDestino: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'User_Name=sysdba'
      'Password=masterkey')
    UpdateOptions.AssignedValues = [uvAutoCommitUpdates]
    UpdateOptions.AutoCommitUpdates = True
    LoginPrompt = False
    Left = 184
    Top = 56
  end
  object Scripts: TFDScript
    SQLScripts = <
      item
        Name = 'TABELAS'
        SQL.Strings = (
          
            'select distinct RDB$RELATION_NAME TABELA from RDB$RELATION_FIELD' +
            'S where RDB$SYSTEM_FLAG = 0 order by RDB$RELATION_NAME')
      end
      item
        Name = 'CAMPOS'
        SQL.Strings = (
          'select DISTINCT'
          '       RF.RDB$FIELD_NAME FIELD_NAME,'
          '       case RF.RDB$NULL_FLAG'
          '         when 1 then 1'
          '         else 0'
          '       end as NOT_NULL,'
          
            '       coalesce(replace(RF.RDB$DEFAULT_SOURCE, '#39'DEFAULT '#39', '#39#39'), ' +
            #39#39') as DEFAULT_VALUE,'
          '       F.RDB$FIELD_LENGTH FIELD_LENGTH,'
          '       coalesce(F.RDB$FIELD_PRECISION, '#39#39') as FIELD_PRECISION,'
          '       abs(F.RDB$FIELD_SCALE) as FIELD_SCALE,'
          '       case F.RDB$FIELD_TYPE'
          '         when 261 then '#39'BLOB'#39
          '         when 14 then '#39'CHAR'#39
          '         when 40 then '#39'VARCHAR'#39
          '         when 11 then '#39'FLOAT'#39
          '         when 27 then '#39'DOUBLE'#39
          '         when 10 then '#39'FLOAT'#39
          
            '         when 16 then iif(F.RDB$FIELD_PRECISION = 0, '#39'INT64'#39', ii' +
            'f(F.RDB$FIELD_SUB_TYPE = 1, '#39'NUMERIC'#39', '#39'DECIMAL'#39'))'
          
            '         when 8 then iif(F.RDB$FIELD_PRECISION = 0, '#39'INTEGER'#39', '#39 +
            'DECIMAL'#39')'
          '         when 7 then '#39'SMALLINT'#39
          '         when 12 then '#39'DATE'#39
          '         when 13 then '#39'TIME'#39
          '         when 35 then '#39'TIMESTAMP'#39
          '         when 37 then '#39'VARCHAR'#39
          '         else '#39'UNKNOWN'#39
          '       end as FIELD_TYPE,'
          '       coalesce(F.RDB$FIELD_SUB_TYPE, '#39'0'#39') FIELD_SUB_TYPE,'
          '       coalesce(F.RDB$SEGMENT_LENGTH, '#39#39') SEGMENT_LENGTH,'
          
            '       coalesce(CSET.RDB$CHARACTER_SET_NAME, '#39#39') as FIELD_CHARSE' +
            'T'
          'from RDB$RELATION_FIELDS RF'
          'join RDB$FIELDS F on RF.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME'
          
            'left join RDB$CHARACTER_SETS CSET on F.RDB$CHARACTER_SET_ID = CS' +
            'ET.RDB$CHARACTER_SET_ID'
          'where RF.RDB$RELATION_NAME = '#39'$TABELA'#39
          'order by RF.RDB$FIELD_NAME asc ')
      end
      item
        Name = 'CONSTRAINTS'
        SQL.Strings = (
          
            'select rc.rdb$constraint_name constraint_name, rc.rdb$constraint' +
            '_type constraint_type, i.rdb$foreign_key foreign_key, rcf.rdb$re' +
            'lation_name relation_name, list(distinct trim(isg.rdb$field_name' +
            '), '#39'|'#39') field_name, list(distinct trim(isgf.rdb$field_name),'#39'|'#39')' +
            ' foreign_field_name from rdb$relation_constraints rc left join r' +
            'db$indices i on i.rdb$index_name = rc.rdb$constraint_name left j' +
            'oin rdb$relation_constraints rcf on rcf.rdb$constraint_name = i.' +
            'rdb$foreign_key left join rdb$index_segments isg on i.rdb$index_' +
            'name = isg.rdb$index_name left join rdb$indices ifk on ifk.rdb$i' +
            'ndex_name = rcf.rdb$constraint_name left join rdb$index_segments' +
            ' isgf on ifk.rdb$index_name = isgf.rdb$index_name where rc.rdb$i' +
            'ndex_name is not null and rc.rdb$relation_name = '#39'$TABELA'#39' group' +
            ' by 1, 2, 3, 4 order by rc.rdb$constraint_name, field_name, fiel' +
            'd_name asc ')
      end
      item
        Name = 'INDICES'
        SQL.Strings = (
          'select I.RDB$INDEX_NAME INDEX_NAME,'
          '       I.RDB$RELATION_NAME RELATION_NAME,'
          '       coalesce(I.RDB$EXPRESSION_SOURCE, '#39#39') EXPRESSION_SOURCE,'
          '       coalesce(ISEG.RDB$FIELD_NAME, '#39#39') FIELD_NAME,'
          '       coalesce(I.RDB$INDEX_TYPE,0) INDEX_TYPE'
          'from RDB$INDICES I'
          
            'left join RDB$INDEX_SEGMENTS ISEG on I.RDB$INDEX_NAME = ISEG.RDB' +
            '$INDEX_NAME'
          'where RDB$RELATION_NAME = '#39'$TABELA'#39' and'
          '      coalesce(RDB$UNIQUE_FLAG, 0) = 0 and'
          '      RDB$FOREIGN_KEY is null'
          'order by I.RDB$INDEX_NAME asc')
      end
      item
        Name = 'TRIGGERS'
        SQL.Strings = (
          'select T.RDB$TRIGGER_NAME TRIGGER_NAME,'
          '       T.RDB$RELATION_NAME RELATION_NAME,'
          '       T.RDB$TRIGGER_SEQUENCE TRIGGER_SEQUENCE,'
          '       T.RDB$TRIGGER_TYPE TRIGGER_TYPE,'
          '       T.RDB$TRIGGER_SOURCE TRIGGER_SOURCE,'
          '       T.RDB$TRIGGER_INACTIVE TRIGGER_INACTIVE'
          'from RDB$TRIGGERS T'
          'where RDB$SYSTEM_FLAG = 0 and'
          '      RDB$RELATION_NAME = '#39'$TABELA'#39
          'order by T.RDB$TRIGGER_NAME asc')
      end
      item
        Name = 'SEQUENCES'
        SQL.Strings = (
          'select SEQ.RDB$GENERATOR_NAME SEQUENCE_NAME'
          'from RDB$GENERATORS SEQ'
          'where RDB$SYSTEM_FLAG = 0'
          'order by SEQ.RDB$GENERATOR_NAME')
      end
      item
        Name = 'TRIGGER_POR_NOME'
        SQL.Strings = (
          'select T.RDB$TRIGGER_NAME TRIGGER_NAME'
          'from RDB$TRIGGERS T'
          'where RDB$SYSTEM_FLAG = 0 and'
          '      T.RDB$TRIGGER_NAME = '#39'$NOME'#39)
      end
      item
        Name = 'TRIGGER_ALTERAR'
        SQL.Strings = (
          'alter trigger $NOME'
          '$INATIVO_ATIVO $TIPO position $POSICAO'
          '  $CONTEUDO')
      end
      item
        Name = 'TRIGGER_CRIAR'
        SQL.Strings = (
          'CREATE OR ALTER TRIGGER $NOME FOR $TABELA'
          '$INATIVO_ATIVO $TIPO position $POSICAO'
          '  $CONTEUDO')
      end
      item
        Name = 'TRIGGER_DROP'
        SQL.Strings = (
          'DROP TRIGGER $NOME')
      end
      item
        Name = 'SEQUENCE_POR_NOME'
        SQL.Strings = (
          'select SEQ.RDB$GENERATOR_NAME SEQUENCE_NAME'
          'from RDB$GENERATORS SEQ'
          'where RDB$SYSTEM_FLAG = 0 and'
          '      SEQ.RDB$GENERATOR_NAME = '#39'$NOME'#39
          'order by SEQ.RDB$GENERATOR_NAME  ')
      end
      item
        Name = 'SEQUENCE_DROP'#180
        SQL.Strings = (
          'DROP SEQUENCE $NOME')
      end
      item
        Name = 'SEQUENCE_RECALCULAR'
      end
      item
        Name = 'INDICE_POR_NOME'
        SQL.Strings = (
          'select I.RDB$INDEX_NAME INDEX_NAME'
          'from RDB$INDICES I'
          'where I.RDB$INDEX_NAME = '#39'$NOME'#39)
      end
      item
        Name = 'INDICE_RECALCULAR'
        SQL.Strings = (
          'SET STATISTICS INDEX $NOME')
      end
      item
        Name = 'INDICE_DROP'
        SQL.Strings = (
          'DROP INDEX $NOME')
      end
      item
        Name = 'CONSTRAINT_POR_NOME'
        SQL.Strings = (
          'select RC.RDB$CONSTRAINT_NAME CONSTRAINT_NAME'
          'from RDB$RELATION_CONSTRAINTS RC'
          'where RC.RDB$INDEX_NAME is not null and'
          '      RC.RDB$CONSTRAINT_NAME = '#39'$NOME'#39)
      end
      item
        Name = 'CONSTRAINT_DROP'
        SQL.Strings = (
          'ALTER TABLE $TABELA DROP CONSTRAINT $NOME')
      end
      item
        Name = 'CONSTRAINT_ALTERAR'
        SQL.Strings = (
          
            'ALTER TABLE $TABELA ADD CONSTRAINT $NOME $TIPO ($CAMPO) $SINTAXE' +
            '_CHAVE_ESTRANGEIRA;')
      end
      item
        Name = 'CAMPO_POR_NOME'
        SQL.Strings = (
          'select RF.RDB$FIELD_NAME FIELD_NAME'
          'from RDB$RELATION_FIELDS RF'
          'where RF.RDB$RELATION_NAME = '#39'$TABELA'#39' and'
          '      RF.RDB$FIELD_NAME = '#39'$NOME'#39)
      end
      item
        Name = 'CAMPO_DROP'
        SQL.Strings = (
          'ALTER TABLE $TABELA DROP $NOME')
      end
      item
        Name = 'CAMPO_ALTERAR'
        SQL.Strings = (
          'ALTER TABLE $TABELA ADD $CAMPO')
      end
      item
        Name = 'TABELA_POR_NOME'
        SQL.Strings = (
          'select distinct RDB$RELATION_NAME TABELA'
          'from RDB$RELATION_FIELDS'
          'where RDB$SYSTEM_FLAG = 0 and'
          '      RDB$RELATION_NAME = '#39'$NOME'#39)
      end
      item
        Name = 'DROP_TABELA'
        SQL.Strings = (
          'DROP TABLE $NOME')
      end
      item
        Name = 'TABELA_CRIAR'
        SQL.Strings = (
          'CREATE TABLE $NOME ('
          '    $CAMPOS'
          ');')
      end
      item
        Name = 'INDICE_CRIAR'
        SQL.Strings = (
          'CREATE $ORDER INDEX $NOME ON $TABELA $COMPUTED_SINTAXE ($VALOR);')
      end
      item
        Name = 'SEQUENCE_CRIAR'
        SQL.Strings = (
          'CREATE SEQUENCE $NOME;')
      end
      item
        Name = 'CHECK_VERSAO'
        SQL.Strings = (
          'select VERSIONDB from SYSINFO')
      end>
    Connection = ConexaoOrigem
    Params = <>
    Macros = <>
    Left = 184
    Top = 144
  end
end
