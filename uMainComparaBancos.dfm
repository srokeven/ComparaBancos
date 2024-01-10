object fmMainCamparaBancos: TfmMainCamparaBancos
  Left = 0
  Top = 0
  Caption = 'Compara'#231#227'o entre bancos'
  ClientHeight = 418
  ClientWidth = 699
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 16
  object pnlBottom: TPanel
    Left = 0
    Top = 362
    Width = 699
    Height = 56
    Align = alBottom
    TabOrder = 0
    object Panel1: TPanel
      Left = 1
      Top = 1
      Width = 160
      Height = 54
      Align = alLeft
      BevelInner = bvLowered
      BevelOuter = bvNone
      TabOrder = 0
      object btnComparar: TButton
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 152
        Height = 46
        Align = alClient
        Caption = 'Comparar'
        TabOrder = 0
        OnClick = btnCompararClick
      end
    end
    object Panel2: TPanel
      Left = 161
      Top = 1
      Width = 537
      Height = 54
      Align = alClient
      BevelInner = bvLowered
      BevelOuter = bvNone
      TabOrder = 1
      object Progresso: TProgressBar
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 529
        Height = 46
        Align = alClient
        TabOrder = 0
      end
    end
  end
  object pnlBackground: TPanel
    Left = 0
    Top = 0
    Width = 699
    Height = 362
    Align = alClient
    TabOrder = 1
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 697
      Height = 360
      ActivePage = tsGeral
      Align = alClient
      TabOrder = 0
      object tsGeral: TTabSheet
        Caption = 'Geral'
        object gbOrigem: TGroupBox
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 337
          Height = 323
          Align = alLeft
          Caption = 'Origem'
          TabOrder = 0
          object Label1: TLabel
            Left = 11
            Top = 24
            Width = 38
            Height = 16
            Caption = 'Server'
          end
          object Label2: TLabel
            Left = 11
            Top = 76
            Width = 23
            Height = 16
            Caption = 'Port'
          end
          object Label3: TLabel
            Left = 11
            Top = 128
            Width = 53
            Height = 16
            Caption = 'Database'
          end
          object Label5: TLabel
            Left = 11
            Top = 232
            Width = 55
            Height = 16
            Caption = 'Password'
          end
          object Label4: TLabel
            Left = 11
            Top = 180
            Width = 59
            Height = 16
            Caption = 'UserName'
          end
          object edServerOrigin: TEdit
            Left = 11
            Top = 46
            Width = 121
            Height = 24
            TabOrder = 0
            Text = '127.0.0.1'
          end
          object edPortOrigin: TEdit
            Left = 11
            Top = 98
            Width = 55
            Height = 24
            NumbersOnly = True
            TabOrder = 1
            Text = '3055'
          end
          object edDatabaseOrigin: TEdit
            Left = 11
            Top = 150
            Width = 310
            Height = 24
            TabOrder = 2
            Text = 'D:\Dados\Compare\base\MASTERVENDAS.FDB'
          end
          object edPasswordOrigin: TEdit
            Left = 11
            Top = 254
            Width = 121
            Height = 24
            TabOrder = 3
            Text = 'masterkey'
          end
          object edUsernameOrigin: TEdit
            Left = 11
            Top = 202
            Width = 121
            Height = 24
            TabOrder = 4
            Text = 'SYSDBA'
          end
          object btnTesteOrigin: TButton
            Left = 11
            Top = 284
            Width = 75
            Height = 25
            Caption = 'Teste'
            TabOrder = 5
            OnClick = btnTesteOriginClick
          end
          object btnExtrairMetadadosOrigem: TButton
            Left = 92
            Top = 284
            Width = 229
            Height = 25
            Caption = 'Extrair Metadados'
            TabOrder = 6
            OnClick = btnExtrairMetadadosOrigemClick
          end
        end
        object gbDestino: TGroupBox
          AlignWithMargins = True
          Left = 349
          Top = 3
          Width = 337
          Height = 323
          Align = alRight
          Caption = 'Destino'
          TabOrder = 1
          object Label6: TLabel
            Left = 11
            Top = 24
            Width = 38
            Height = 16
            Caption = 'Server'
          end
          object Label7: TLabel
            Left = 11
            Top = 76
            Width = 23
            Height = 16
            Caption = 'Port'
          end
          object Label8: TLabel
            Left = 11
            Top = 128
            Width = 53
            Height = 16
            Caption = 'Database'
          end
          object Label9: TLabel
            Left = 11
            Top = 180
            Width = 59
            Height = 16
            Caption = 'UserName'
          end
          object Label10: TLabel
            Left = 11
            Top = 232
            Width = 55
            Height = 16
            Caption = 'Password'
          end
          object edServerDest: TEdit
            Left = 11
            Top = 46
            Width = 121
            Height = 24
            TabOrder = 0
            Text = '127.0.0.1'
          end
          object edPortDest: TEdit
            Left = 11
            Top = 98
            Width = 55
            Height = 24
            NumbersOnly = True
            TabOrder = 1
            Text = '3055'
          end
          object edDatabaseDest: TEdit
            Left = 11
            Top = 150
            Width = 310
            Height = 24
            TabOrder = 2
            Text = 'D:\Dados\Compare\Novo\MASTERVENDAS.FDB'
          end
          object edUsernameDest: TEdit
            Left = 11
            Top = 202
            Width = 121
            Height = 24
            TabOrder = 3
            Text = 'SYSDBA'
          end
          object edPasswordDest: TEdit
            Left = 11
            Top = 254
            Width = 121
            Height = 24
            TabOrder = 4
            Text = 'masterkey'
          end
          object btnTesteDest: TButton
            Left = 11
            Top = 284
            Width = 75
            Height = 25
            Caption = 'Teste'
            TabOrder = 5
            OnClick = btnTesteDestClick
          end
          object btnExtrairMetadadosDestino: TButton
            Left = 92
            Top = 284
            Width = 229
            Height = 25
            Caption = 'Extrair Metadados'
            TabOrder = 6
            OnClick = btnExtrairMetadadosDestinoClick
          end
        end
      end
      object tsSchema: TTabSheet
        Caption = 'Schema'
        ImageIndex = 1
        object mmResposta: TMemo
          Left = 0
          Top = 0
          Width = 689
          Height = 329
          Align = alClient
          TabOrder = 0
        end
      end
      object tsComparativo: TTabSheet
        Caption = 'Comparativo'
        ImageIndex = 2
        object mmComparativo: TMemo
          Left = 0
          Top = 0
          Width = 689
          Height = 329
          Align = alClient
          TabOrder = 0
        end
      end
    end
  end
end
