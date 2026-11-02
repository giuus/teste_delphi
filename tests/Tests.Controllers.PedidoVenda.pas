unit Tests.Controllers.PedidoVenda;

interface

uses
  DUnitX.TestFramework,
  Controllers.PedidoVenda,
  Tests.Fakes;

type
  [TestFixture]
  TTestesPedidoVendaController = class
  private
    FRegistro: TRegistroGravacao;
    FController: TPedidoVendaController;
    function IncluirItem(ACodigoProduto: Integer; AQuantidade, AValor: Currency): Integer;
  public
    [Setup] procedure Preparar;
    [TearDown] procedure Liberar;
    [Test] procedure ClienteInexistenteDescartaClienteAnterior;
    [Test] procedure AlterarCodigoDescartaCliente;
    [Test] procedure ProdutoNovoSugerePreco;
    [Test] procedure ReconsultaDoMesmoProdutoEmEdicaoNaoSugerePreco;
    [Test] procedure TrocaDeProdutoEmEdicaoSugerePreco;
    [Test] procedure EdicaoAtualizaSomenteAMesmaLinha;
    [Test] procedure SalvarItemEncerraEdicao;
    [Test] procedure SalvarSemProdutoFalha;
    [Test] procedure GravarSemClienteFalha;
    [Test] procedure GravarComItemEmEdicaoFalha;
    [Test] procedure GravarComSucessoIniciaNovoPedido;
    [Test] procedure FalhaNaGravacaoPreservaDados;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions,
  Domain.Pedido,
  Services.ConsultaCadastro,
  Services.Pedido;

procedure TTestesPedidoVendaController.Preparar;
begin
  FRegistro := TRegistroGravacao.Create;
  FController := TPedidoVendaController.Create(
    TConsultaCadastroService.Create(TFakeClienteRepository.Create, TFakeProdutoRepository.Create),
    TPedidoService.Create(TFakeClienteRepository.Create, TFakePedidoRepository.Create(FRegistro),
      TFakePedidoItemRepository.Create(FRegistro), TFakeTransacao.Create(FRegistro)));
end;

procedure TTestesPedidoVendaController.Liberar;
begin
  FreeAndNil(FController);
  FreeAndNil(FRegistro);
end;

function TTestesPedidoVendaController.IncluirItem(ACodigoProduto: Integer;
  AQuantidade, AValor: Currency): Integer;
var
  LSugerir: Boolean;
begin
  FController.ConsultarProduto(ACodigoProduto, LSugerir);
  Result := FController.SalvarItem(AQuantidade, AValor);
end;

procedure TTestesPedidoVendaController.ClienteInexistenteDescartaClienteAnterior;
begin
  FController.ConsultarCliente(1);
  Assert.WillRaise(procedure begin FController.ConsultarCliente(999); end,
    ERegistroNaoEncontradoException);
  Assert.IsNull(FController.Cliente);
  Assert.AreEqual(0, FController.Pedido.CodigoCliente);
end;

procedure TTestesPedidoVendaController.AlterarCodigoDescartaCliente;
begin
  FController.ConsultarCliente(1);
  FController.DescartarCliente;
  Assert.IsNull(FController.Cliente);
end;

procedure TTestesPedidoVendaController.ProdutoNovoSugerePreco;
var
  LSugerir: Boolean;
begin
  FController.ConsultarProduto(2, LSugerir);
  Assert.IsTrue(LSugerir);
end;

procedure TTestesPedidoVendaController.ReconsultaDoMesmoProdutoEmEdicaoNaoSugerePreco;
var
  LId: Integer;
  LSugerir: Boolean;
begin
  LId := IncluirItem(2, 1, 7.77);
  FController.IniciarEdicaoItem(LId);
  FController.ConsultarProduto(2, LSugerir);
  Assert.IsFalse(LSugerir);
end;

procedure TTestesPedidoVendaController.TrocaDeProdutoEmEdicaoSugerePreco;
var
  LId: Integer;
  LSugerir: Boolean;
begin
  LId := IncluirItem(2, 1, 7.77);
  FController.IniciarEdicaoItem(LId);
  FController.ConsultarProduto(3, LSugerir);
  Assert.IsTrue(LSugerir);
end;

procedure TTestesPedidoVendaController.EdicaoAtualizaSomenteAMesmaLinha;
var
  LId1, LId2: Integer;
  LItem: TPedidoItem;
begin
  LId1 := IncluirItem(2, 1, 7.77);
  LId2 := IncluirItem(2, 2, 7.77);
  LItem := FController.IniciarEdicaoItem(LId2);
  Assert.AreEqual<Currency>(2, LItem.Quantidade);
  Assert.AreEqual(LId2, FController.SalvarItem(4, 8));
  Assert.AreEqual(2, FController.Pedido.QuantidadeItens);
  Assert.AreEqual<Currency>(1, FController.Pedido.ObterItem(LId1).Quantidade);
  Assert.AreEqual<Currency>(4, FController.Pedido.ObterItem(LId2).Quantidade);
  Assert.AreEqual<Currency>(39.77, FController.Pedido.ValorTotal);
end;

procedure TTestesPedidoVendaController.SalvarItemEncerraEdicao;
var
  LId: Integer;
begin
  LId := IncluirItem(2, 1, 1);
  FController.IniciarEdicaoItem(LId);
  FController.SalvarItem(2, 1);
  Assert.IsFalse(FController.EmEdicaoItem);
  Assert.IsNull(FController.Produto);
end;

procedure TTestesPedidoVendaController.SalvarSemProdutoFalha;
begin
  Assert.WillRaise(procedure begin FController.SalvarItem(1, 1); end, EValidacaoException);
end;

procedure TTestesPedidoVendaController.GravarSemClienteFalha;
begin
  IncluirItem(1, 1, 1);
  Assert.WillRaise(procedure begin FController.GravarPedido; end, EValidacaoException);
  Assert.AreEqual(0, FRegistro.Iniciadas);
end;

procedure TTestesPedidoVendaController.GravarComItemEmEdicaoFalha;
var
  LId: Integer;
begin
  FController.ConsultarCliente(1);
  LId := IncluirItem(1, 1, 1);
  FController.IniciarEdicaoItem(LId);
  Assert.WillRaise(procedure begin FController.GravarPedido; end, EValidacaoException);
  Assert.AreEqual(0, FRegistro.Iniciadas);
end;

procedure TTestesPedidoVendaController.GravarComSucessoIniciaNovoPedido;
begin
  FController.ConsultarCliente(1);
  IncluirItem(1, 1, 1);
  Assert.AreEqual(1, FController.GravarPedido);
  Assert.AreEqual(0, FController.Pedido.QuantidadeItens);
  Assert.IsFalse(FController.Pedido.Persistido);
  Assert.IsNull(FController.Cliente);
  Assert.IsFalse(FController.PossuiAlteracoes);
  // Um segundo acionamento não grava o mesmo pedido de novo.
  Assert.WillRaise(procedure begin FController.GravarPedido; end, EValidacaoException);
  Assert.AreEqual(1, FRegistro.Confirmadas);
end;

procedure TTestesPedidoVendaController.FalhaNaGravacaoPreservaDados;
begin
  FController.ConsultarCliente(1);
  IncluirItem(1, 1, 1);
  IncluirItem(1, 2, 1);
  FRegistro.FalharNoItem := 2;
  Assert.WillRaise(procedure begin FController.GravarPedido; end);
  Assert.IsNotNull(FController.Cliente);
  Assert.AreEqual(2, FController.Pedido.QuantidadeItens);
  Assert.IsFalse(FController.Pedido.Persistido);
  Assert.IsTrue(FController.PossuiAlteracoes);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesPedidoVendaController);

end.
