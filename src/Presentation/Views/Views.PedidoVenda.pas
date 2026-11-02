unit Views.PedidoVenda;

{ Tela de pedido de venda. Responsável apenas por ler os campos, exibir o
  estado do controller e pedir confirmações ao operador. A grade é uma
  projeção (TFDMemTable) reconstruída a partir dos itens do pedido; as
  regras e os totais vêm do domínio. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Grids,
  Vcl.DBGrids,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Domain.Pedido,
  Domain.Produto,
  Controllers.PedidoVenda;

type
  TfrmPedidoVenda = class(TForm)
    pnlCabecalho: TPanel;
    grpPedido: TGroupBox;
    lblDataEmissao: TLabel;
    edtDataEmissao: TEdit;
    lblSituacao: TLabel;
    grpCliente: TGroupBox;
    lblCodigoCliente: TLabel;
    edtCodigoCliente: TEdit;
    lblNomeCliente: TLabel;
    edtNomeCliente: TEdit;
    lblCidade: TLabel;
    edtCidade: TEdit;
    lblUF: TLabel;
    edtUF: TEdit;
    lblObservacao: TLabel;
    edtObservacao: TEdit;
    grpItem: TGroupBox;
    lblCodigoProduto: TLabel;
    edtCodigoProduto: TEdit;
    lblDescricaoProduto: TLabel;
    edtDescricaoProduto: TEdit;
    lblQuantidade: TLabel;
    edtQuantidade: TEdit;
    lblValorUnitario: TLabel;
    edtValorUnitario: TEdit;
    btnInserirItem: TButton;
    btnCancelarEdicao: TButton;
    lblModoItem: TLabel;
    grdItens: TDBGrid;
    pnlRodape: TPanel;
    lblTituloTotal: TLabel;
    lblValorTotal: TLabel;
    lblAtalhos: TLabel;
    btnGravarPedido: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CampoKeyDownAvancar(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtCodigoClienteChange(Sender: TObject);
    procedure edtCodigoClienteExit(Sender: TObject);
    procedure edtObservacaoChange(Sender: TObject);
    procedure edtCodigoProdutoChange(Sender: TObject);
    procedure edtCodigoProdutoExit(Sender: TObject);
    procedure btnInserirItemClick(Sender: TObject);
    procedure btnCancelarEdicaoClick(Sender: TObject);
    procedure grdItensKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnGravarPedidoClick(Sender: TObject);
  private const
    CAMPO_ID = 'ITEM_ID';
    CAMPO_CODIGO = 'CODIGO_PRODUTO';
    CAMPO_DESCRICAO = 'DESCRICAO';
    CAMPO_QUANTIDADE = 'QUANTIDADE';
    CAMPO_VALOR_UNITARIO = 'VLR_UNITARIO';
    CAMPO_VALOR_TOTAL = 'VLR_TOTAL';
  private
    /// Pertence ao TCompositionRoot; o formulário apenas o utiliza.
    FController: TPedidoVendaController;
    FItens: TFDMemTable;
    FDataSourceItens: TDataSource;
    /// Evita que alterações feitas pelo próprio código nos campos sejam
    /// tratadas como digitação do operador (OnChange).
    FAtualizandoCampos: Boolean;
    procedure CriarProjecaoItens;
    procedure AdicionarCampo(const ANome: string; ATipo: TFieldType; ATamanho: Integer = 0);
    procedure ConfigurarCampos;
    function ExecutarAcao(const AAcao: TProc): Boolean;
    procedure ExibirPedido;
    procedure ExibirCliente;
    procedure ExibirTotal;
    procedure ExibirEstadoEdicao;
    procedure AtualizarItens(AIdSelecionar: Integer);
    procedure PreencherCamposItem(AItem: TPedidoItem);
    procedure LimparCamposItem;
    procedure ExibirProduto(AProduto: TProduto; ASugerirPreco: Boolean);
    procedure DefinirTexto(AEdit: TEdit; const ATexto: string);
    function IdItemSelecionado: Integer;
    procedure ConsultarCliente;
    procedure ConsultarProduto;
    procedure CarregarItemSelecionado;
    procedure ExcluirItemSelecionado;
    function ConfirmarDescarte: Boolean;
  public
    procedure Inicializar(AController: TPedidoVendaController);
  end;

implementation

uses
  System.UITypes,
  Domain.Exceptions,
  Domain.Regras,
  Views.ConversaoEntrada;

{$R *.dfm}

const
  FORMATO_QUANTIDADE = '#,##0.000';
  FORMATO_VALOR = '#,##0.00';

{ Inicialização }

procedure TfrmPedidoVenda.FormCreate(Sender: TObject);
begin
  // Mesmo limite de PEDIDO.OBSERVACAO VARCHAR(200).
  edtObservacao.MaxLength := TRegrasPedido.TAMANHO_MAXIMO_OBSERVACAO;
  CriarProjecaoItens;
end;

procedure TfrmPedidoVenda.Inicializar(AController: TPedidoVendaController);
begin
  if AController = nil then
    raise EArgumentNilException.Create('AController');
  FController := AController;
  ExibirPedido;
end;

procedure TfrmPedidoVenda.CriarProjecaoItens;
begin
  FItens := TFDMemTable.Create(Self);
  AdicionarCampo(CAMPO_ID, ftInteger);
  AdicionarCampo(CAMPO_CODIGO, ftInteger);
  AdicionarCampo(CAMPO_DESCRICAO, ftWideString, 120);
  AdicionarCampo(CAMPO_QUANTIDADE, ftBCD, 4);
  AdicionarCampo(CAMPO_VALOR_UNITARIO, ftBCD, 4);
  AdicionarCampo(CAMPO_VALOR_TOTAL, ftBCD, 4);
  FItens.CreateDataSet;
  ConfigurarCampos;

  FDataSourceItens := TDataSource.Create(Self);
  FDataSourceItens.DataSet := FItens;
  grdItens.DataSource := FDataSourceItens;
end;

procedure TfrmPedidoVenda.AdicionarCampo(const ANome: string; ATipo: TFieldType;
  ATamanho: Integer);
var
  LDefinicao: TFieldDef;
begin
  LDefinicao := FItens.FieldDefs.AddFieldDef;
  LDefinicao.Name := ANome;
  LDefinicao.DataType := ATipo;
  if ATipo = ftBCD then
    LDefinicao.Precision := 18;
  if ATamanho > 0 then
    LDefinicao.Size := ATamanho;
end;

procedure TfrmPedidoVenda.ConfigurarCampos;

  procedure Configurar(const ANome, ATitulo: string; ALargura: Integer;
    const AFormato: string = '');
  var
    LCampo: TField;
  begin
    LCampo := FItens.FieldByName(ANome);
    LCampo.DisplayLabel := ATitulo;
    LCampo.DisplayWidth := ALargura;
    if AFormato <> '' then
      (LCampo as TNumericField).DisplayFormat := AFormato;
  end;

begin
  FItens.FieldByName(CAMPO_ID).Visible := False;
  Configurar(CAMPO_CODIGO, 'Cód. Produto', 12);
  Configurar(CAMPO_DESCRICAO, 'Descrição', 45);
  Configurar(CAMPO_QUANTIDADE, 'Quantidade', 14, FORMATO_QUANTIDADE);
  Configurar(CAMPO_VALOR_UNITARIO, 'Vlr. Unitário', 14, FORMATO_VALOR);
  Configurar(CAMPO_VALOR_TOTAL, 'Vlr. Total', 16, FORMATO_VALOR);
end;

{ Tratamento de erros }

function TfrmPedidoVenda.ExecutarAcao(const AAcao: TProc): Boolean;
begin
  Result := False;
  try
    AAcao();
    Result := True;
  except
    on E: EValidacaoException do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    on E: Exception do
      MessageDlg('Não foi possível concluir a operação.' + sLineBreak + sLineBreak +
        E.Message, mtError, [mbOK], 0);
  end;
end;

{ Exibição }

procedure TfrmPedidoVenda.DefinirTexto(AEdit: TEdit; const ATexto: string);
begin
  FAtualizandoCampos := True;
  try
    AEdit.Text := ATexto;
  finally
    FAtualizandoCampos := False;
  end;
end;

procedure TfrmPedidoVenda.ExibirPedido;
begin
  edtDataEmissao.Text := DateToStr(FController.Pedido.DataEmissao);
  lblSituacao.Caption := 'Novo pedido (ainda não gravado)';
  if FController.Cliente = nil then
    DefinirTexto(edtCodigoCliente, '');
  ExibirCliente;
  DefinirTexto(edtObservacao, FController.Pedido.Observacao);
  LimparCamposItem;
  AtualizarItens(0);
end;

procedure TfrmPedidoVenda.ExibirCliente;
begin
  if FController.Cliente = nil then
  begin
    edtNomeCliente.Clear;
    edtCidade.Clear;
    edtUF.Clear;
    Exit;
  end;
  DefinirTexto(edtCodigoCliente, IntToStr(FController.Cliente.Codigo));
  edtNomeCliente.Text := FController.Cliente.Nome;
  edtCidade.Text := FController.Cliente.Cidade;
  edtUF.Text := FController.Cliente.UF;
end;

procedure TfrmPedidoVenda.ExibirTotal;
begin
  lblValorTotal.Caption := CurrToStrF(FController.Pedido.ValorTotal, ffCurrency,
    TRegrasPedido.CASAS_VALOR);
end;

procedure TfrmPedidoVenda.ExibirEstadoEdicao;
begin
  btnCancelarEdicao.Enabled := FController.EmEdicaoItem;
  if FController.EmEdicaoItem then
    lblModoItem.Caption := 'Editando item selecionado - confirme com "Inserir/Atualizar Item"'
  else
    lblModoItem.Caption := 'Novo item';
end;

procedure TfrmPedidoVenda.AtualizarItens(AIdSelecionar: Integer);
var
  LIndice: Integer;
  LItem: TPedidoItem;
begin
  FItens.DisableControls;
  try
    FItens.EmptyDataSet;
    for LIndice := 0 to FController.Pedido.QuantidadeItens - 1 do
    begin
      LItem := FController.Pedido.Itens[LIndice];
      FItens.Append;
      FItens.FieldByName(CAMPO_ID).AsInteger := LItem.Id;
      FItens.FieldByName(CAMPO_CODIGO).AsInteger := LItem.CodigoProduto;
      FItens.FieldByName(CAMPO_DESCRICAO).AsString := LItem.DescricaoProduto;
      FItens.FieldByName(CAMPO_QUANTIDADE).AsCurrency := LItem.Quantidade;
      FItens.FieldByName(CAMPO_VALOR_UNITARIO).AsCurrency := LItem.ValorUnitario;
      FItens.FieldByName(CAMPO_VALOR_TOTAL).AsCurrency := LItem.ValorTotal;
      FItens.Post;
    end;
    if not ((AIdSelecionar > 0) and FItens.Locate(CAMPO_ID, AIdSelecionar, [])) then
      FItens.First;
  finally
    FItens.EnableControls;
  end;
  ExibirTotal;
end;

procedure TfrmPedidoVenda.PreencherCamposItem(AItem: TPedidoItem);
begin
  DefinirTexto(edtCodigoProduto, IntToStr(AItem.CodigoProduto));
  edtDescricaoProduto.Text := AItem.DescricaoProduto;
  // Preserva a quantidade e o valor já informados no item.
  edtQuantidade.Text := TConversaoEntrada.FormatarParaEdicao(AItem.Quantidade,
    TRegrasPedido.CASAS_QUANTIDADE);
  edtValorUnitario.Text := TConversaoEntrada.FormatarParaEdicao(AItem.ValorUnitario,
    TRegrasPedido.CASAS_VALOR);
  ExibirEstadoEdicao;
end;

procedure TfrmPedidoVenda.LimparCamposItem;
begin
  DefinirTexto(edtCodigoProduto, '');
  edtDescricaoProduto.Clear;
  edtQuantidade.Clear;
  edtValorUnitario.Clear;
  ExibirEstadoEdicao;
end;

procedure TfrmPedidoVenda.ExibirProduto(AProduto: TProduto; ASugerirPreco: Boolean);
begin
  edtDescricaoProduto.Text := AProduto.Descricao;
  if ASugerirPreco then
    edtValorUnitario.Text := TConversaoEntrada.FormatarParaEdicao(AProduto.PrecoVenda,
      TRegrasPedido.CASAS_VALOR);
end;

{ Cliente }

procedure TfrmPedidoVenda.CampoKeyDownAvancar(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // ENTER nos campos do cabeçalho e do item avança para o próximo campo;
  // nos campos de código a consulta acontece no OnExit.
  if Key = VK_RETURN then
  begin
    Key := 0;
    SelectNext(Sender as TWinControl, True, True);
  end;
end;

procedure TfrmPedidoVenda.edtCodigoClienteChange(Sender: TObject);
begin
  if FAtualizandoCampos or (FController = nil) then
    Exit;
  // Código alterado: o cliente consultado anteriormente deixa de valer.
  FController.DescartarCliente;
  ExibirCliente;
end;

procedure TfrmPedidoVenda.edtObservacaoChange(Sender: TObject);
begin
  if FAtualizandoCampos or (FController = nil) then
    Exit;
  FController.AlterarObservacao(edtObservacao.Text);
end;

procedure TfrmPedidoVenda.edtCodigoClienteExit(Sender: TObject);
begin
  ConsultarCliente;
end;

procedure TfrmPedidoVenda.ConsultarCliente;
begin
  if Trim(edtCodigoCliente.Text) = '' then
    Exit;
  if (FController.Cliente <> nil) and
    (IntToStr(FController.Cliente.Codigo) = Trim(edtCodigoCliente.Text)) then
    Exit;

  ExecutarAcao(
    procedure
    begin
      try
        FController.ConsultarCliente(TConversaoEntrada.LerCodigo(edtCodigoCliente.Text,
          'código do cliente'));
      finally
        ExibirCliente;
      end;
    end);
end;

{ Produto e itens }

procedure TfrmPedidoVenda.edtCodigoProdutoChange(Sender: TObject);
begin
  if FAtualizandoCampos or (FController = nil) then
    Exit;
  FController.DescartarProduto;
  edtDescricaoProduto.Clear;
end;

procedure TfrmPedidoVenda.edtCodigoProdutoExit(Sender: TObject);
begin
  ConsultarProduto;
end;

procedure TfrmPedidoVenda.ConsultarProduto;
begin
  if Trim(edtCodigoProduto.Text) = '' then
    Exit;
  if (FController.Produto <> nil) and
    (IntToStr(FController.Produto.Codigo) = Trim(edtCodigoProduto.Text)) then
    Exit;

  ExecutarAcao(
    procedure
    var
      LSugerirPreco: Boolean;
      LProduto: TProduto;
    begin
      edtDescricaoProduto.Clear;
      LProduto := FController.ConsultarProduto(
        TConversaoEntrada.LerCodigo(edtCodigoProduto.Text, 'código do produto'),
        LSugerirPreco);
      ExibirProduto(LProduto, LSugerirPreco);
    end);
end;

procedure TfrmPedidoVenda.btnInserirItemClick(Sender: TObject);
var
  LIdItem: Integer;
begin
  LIdItem := 0;
  if FController.Produto = nil then
  begin
    ConsultarProduto;
    // A consulta já exibiu a mensagem de erro; evita um segundo aviso.
    if (FController.Produto = nil) and (Trim(edtCodigoProduto.Text) <> '') then
      Exit;
  end;

  if ExecutarAcao(
    procedure
    begin
      LIdItem := FController.SalvarItem(
        TConversaoEntrada.LerDecimal(edtQuantidade.Text, 'Quantidade',
          TRegrasPedido.CASAS_QUANTIDADE),
        TConversaoEntrada.LerDecimal(edtValorUnitario.Text, 'Vlr. Unitário',
          TRegrasPedido.CASAS_VALOR));
    end) then
  begin
    AtualizarItens(LIdItem);
    LimparCamposItem;
    edtCodigoProduto.SetFocus;
  end;
end;

procedure TfrmPedidoVenda.btnCancelarEdicaoClick(Sender: TObject);
begin
  FController.CancelarEdicaoItem;
  LimparCamposItem;
  grdItens.SetFocus;
end;

{ Grade }

function TfrmPedidoVenda.IdItemSelecionado: Integer;
var
  LCampoId: TField;
begin
  Result := 0;
  if not FItens.Active or FItens.IsEmpty then
    Exit;
  LCampoId := FItens.FieldByName(CAMPO_ID);
  if LCampoId.IsNull then
    Exit;
  if FController.Pedido.LocalizarItem(LCampoId.AsInteger) <> nil then
    Result := LCampoId.AsInteger;
end;

procedure TfrmPedidoVenda.grdItensKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        CarregarItemSelecionado;
      end;
    VK_DELETE:
      begin
        // Key := 0 também impede o Ctrl+Del padrão do TDBGrid.
        Key := 0;
        ExcluirItemSelecionado;
      end;
  end;
end;

procedure TfrmPedidoVenda.CarregarItemSelecionado;
var
  LIdItem: Integer;
begin
  LIdItem := IdItemSelecionado;
  if LIdItem = 0 then
    Exit;

  ExecutarAcao(
    procedure
    begin
      PreencherCamposItem(FController.IniciarEdicaoItem(LIdItem));
      edtQuantidade.SetFocus;
      edtQuantidade.SelectAll;
    end);
end;

procedure TfrmPedidoVenda.ExcluirItemSelecionado;
var
  LIdItem: Integer;
  LItem: TPedidoItem;
begin
  LIdItem := IdItemSelecionado;
  if LIdItem = 0 then
    Exit;
  LItem := FController.Pedido.ObterItem(LIdItem);

  if MessageDlg(Format('Excluir o item "%d - %s" (quantidade %s)?',
    [LItem.CodigoProduto, LItem.DescricaoProduto,
     FormatCurr(FORMATO_QUANTIDADE, LItem.Quantidade)]),
    mtConfirmation, [mbYes, mbNo], 0, mbNo) <> mrYes then
    Exit;

  if ExecutarAcao(
    procedure
    begin
      FController.ExcluirItem(LIdItem);
    end) then
    FItens.Delete;
end;

{ Gravação }

procedure TfrmPedidoVenda.btnGravarPedidoClick(Sender: TObject);
var
  LNumero: Integer;
begin
  LNumero := 0;
  btnGravarPedido.Enabled := False;
  try
    if ExecutarAcao(
      procedure
      begin
        LNumero := FController.GravarPedido;
      end) then
    begin
      // O número só é exibido depois do commit.
      MessageDlg(Format('Pedido nº %d gravado com sucesso.', [LNumero]),
        mtInformation, [mbOK], 0);
      ExibirPedido;
      edtCodigoCliente.SetFocus;
    end;
    // Em caso de erro os dados da tela são mantidos para correção.
  finally
    btnGravarPedido.Enabled := True;
  end;
end;

{ Fechamento }

function TfrmPedidoVenda.ConfirmarDescarte: Boolean;
begin
  Result := (FController = nil) or not FController.PossuiAlteracoes or
    (MessageDlg('O pedido atual possui alterações não gravadas. Deseja descartá-las?',
      mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes);
end;

procedure TfrmPedidoVenda.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmarDescarte;
end;

end.
