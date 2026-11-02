object frmPedidoVenda: TfrmPedidoVenda
  Left = 0
  Top = 0
  Caption = 'Pedido de Venda'
  ClientHeight = 600
  ClientWidth = 880
  Color = clBtnFace
  Constraints.MinHeight = 520
  Constraints.MinWidth = 896
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ActiveControl = edtCodigoCliente
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlCabecalho: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 270
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object grpPedido: TGroupBox
      Left = 8
      Top = 4
      Width = 864
      Height = 52
      Anchors = [akLeft, akTop, akRight]
      Caption = ' Pedido '
      TabOrder = 0
      object lblNumeroPedido: TLabel
        Left = 12
        Top = 23
        Width = 54
        Height = 13
        Caption = 'N'#186' Pedido:'
      end
      object lblDataEmissao: TLabel
        Left = 476
        Top = 23
        Width = 44
        Height = 13
        Caption = 'Emiss'#227'o:'
      end
      object lblSituacao: TLabel
        Left = 620
        Top = 16
        Width = 236
        Height = 30
        AutoSize = False
        Anchors = [akLeft, akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        WordWrap = True
      end
      object edtNumeroPedido: TEdit
        Left = 72
        Top = 20
        Width = 70
        Height = 21
        MaxLength = 9
        NumbersOnly = True
        TabOrder = 0
        OnKeyDown = edtNumeroPedidoKeyDown
      end
      object btnCarregarPedido: TButton
        Left = 148
        Top = 18
        Width = 105
        Height = 25
        Caption = 'Carregar Pedido'
        TabOrder = 1
        OnClick = btnCarregarPedidoClick
      end
      object btnNovoPedido: TButton
        Left = 259
        Top = 18
        Width = 90
        Height = 25
        Caption = 'Novo Pedido'
        TabOrder = 2
        OnClick = btnNovoPedidoClick
      end
      object btnCancelarPedido: TButton
        Left = 355
        Top = 18
        Width = 105
        Height = 25
        Caption = 'Cancelar Pedido'
        Enabled = False
        TabOrder = 3
        OnClick = btnCancelarPedidoClick
      end
      object edtDataEmissao: TEdit
        Left = 528
        Top = 20
        Width = 80
        Height = 21
        TabStop = False
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 4
      end
    end
    object grpCliente: TGroupBox
      Left = 8
      Top = 60
      Width = 864
      Height = 106
      Anchors = [akLeft, akTop, akRight]
      Caption = ' Cliente '
      TabOrder = 1
      object lblCodigoCliente: TLabel
        Left = 12
        Top = 20
        Width = 37
        Height = 13
        Caption = 'C'#243'digo'
      end
      object lblNomeCliente: TLabel
        Left = 100
        Top = 20
        Width = 27
        Height = 13
        Caption = 'Nome'
      end
      object lblCidade: TLabel
        Left = 560
        Top = 20
        Width = 33
        Height = 13
        Caption = 'Cidade'
      end
      object lblUF: TLabel
        Left = 800
        Top = 20
        Width = 13
        Height = 13
        Caption = 'UF'
      end
      object edtCodigoCliente: TEdit
        Left = 12
        Top = 36
        Width = 80
        Height = 21
        MaxLength = 9
        NumbersOnly = True
        TabOrder = 0
        OnChange = edtCodigoClienteChange
        OnExit = edtCodigoClienteExit
        OnKeyDown = CampoKeyDownAvancar
      end
      object edtNomeCliente: TEdit
        Left = 100
        Top = 36
        Width = 452
        Height = 21
        TabStop = False
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 1
      end
      object edtCidade: TEdit
        Left = 560
        Top = 36
        Width = 232
        Height = 21
        TabStop = False
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 2
      end
      object edtUF: TEdit
        Left = 800
        Top = 36
        Width = 50
        Height = 21
        TabStop = False
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 3
      end
      object lblObservacao: TLabel
        Left = 12
        Top = 70
        Width = 62
        Height = 13
        Caption = 'Observa'#231#227'o:'
      end
      object edtObservacao: TEdit
        Left = 100
        Top = 67
        Width = 750
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        MaxLength = 200
        TabOrder = 4
        OnChange = edtObservacaoChange
        OnKeyDown = CampoKeyDownAvancar
      end
    end
    object grpItem: TGroupBox
      Left = 8
      Top = 170
      Width = 864
      Height = 96
      Anchors = [akLeft, akTop, akRight]
      Caption = ' Item '
      TabOrder = 2
      object lblCodigoProduto: TLabel
        Left = 12
        Top = 20
        Width = 64
        Height = 13
        Caption = 'C'#243'd. Produto'
      end
      object lblDescricaoProduto: TLabel
        Left = 100
        Top = 20
        Width = 46
        Height = 13
        Caption = 'Descri'#231#227'o'
      end
      object lblQuantidade: TLabel
        Left = 476
        Top = 20
        Width = 56
        Height = 13
        Caption = 'Quantidade'
      end
      object lblValorUnitario: TLabel
        Left = 580
        Top = 20
        Width = 63
        Height = 13
        Caption = 'Vlr. Unit'#225'rio'
      end
      object lblModoItem: TLabel
        Left = 12
        Top = 70
        Width = 47
        Height = 13
        Caption = 'Novo item'
      end
      object edtCodigoProduto: TEdit
        Left = 12
        Top = 36
        Width = 80
        Height = 21
        MaxLength = 9
        NumbersOnly = True
        TabOrder = 0
        OnChange = edtCodigoProdutoChange
        OnExit = edtCodigoProdutoExit
        OnKeyDown = CampoKeyDownAvancar
      end
      object edtDescricaoProduto: TEdit
        Left = 100
        Top = 36
        Width = 368
        Height = 21
        TabStop = False
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 1
      end
      object edtQuantidade: TEdit
        Left = 476
        Top = 36
        Width = 96
        Height = 21
        Alignment = taRightJustify
        MaxLength = 12
        TabOrder = 2
        OnKeyDown = CampoKeyDownAvancar
      end
      object edtValorUnitario: TEdit
        Left = 580
        Top = 36
        Width = 100
        Height = 21
        Alignment = taRightJustify
        MaxLength = 12
        TabOrder = 3
        OnKeyDown = CampoKeyDownAvancar
      end
      object btnInserirItem: TButton
        Left = 690
        Top = 34
        Width = 160
        Height = 25
        Caption = 'Inserir/Atualizar Item'
        TabOrder = 4
        OnClick = btnInserirItemClick
      end
      object btnCancelarEdicao: TButton
        Left = 690
        Top = 64
        Width = 160
        Height = 25
        Caption = 'Cancelar Edi'#231#227'o'
        Enabled = False
        TabOrder = 5
        OnClick = btnCancelarEdicaoClick
      end
    end
  end
  object grdItens: TDBGrid
    Left = 0
    Top = 270
    Width = 880
    Height = 274
    Align = alClient
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgRowSelect, dgAlwaysShowSelection]
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnKeyDown = grdItensKeyDown
  end
  object pnlRodape: TPanel
    Left = 0
    Top = 544
    Width = 880
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblAtalhos: TLabel
      Left = 12
      Top = 21
      Width = 300
      Height = 13
      Caption = 'Na grade: ENTER edita o item selecionado | DEL exclui o item'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object lblTituloTotal: TLabel
      Left = 420
      Top = 21
      Width = 150
      Height = 16
      Anchors = [akTop, akRight]
      Caption = 'Valor Total do Pedido:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblValorTotal: TLabel
      Left = 576
      Top = 17
      Width = 156
      Height = 23
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'R$ 0,00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnGravarPedido: TButton
      Left = 742
      Top = 12
      Width = 130
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Gravar Pedido'
      TabOrder = 0
      OnClick = btnGravarPedidoClick
    end
  end
end
