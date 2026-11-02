unit Tests.Services.Pedido;

interface

uses
  DUnitX.TestFramework,
  Domain.Pedido,
  Services.Interfaces,
  Tests.Fakes;

type
  [TestFixture]
  TTestesPedidoService = class
  private
    FRegistro: TRegistroGravacao;
    FService: IPedidoService;
    FPedido: TPedido;
  public
    [Setup] procedure Preparar;
    [TearDown] procedure Liberar;
    [Test] procedure GravaCabecalhoEItensComCommit;
    [Test] procedure NumeroAtribuidoSomenteAposCommit;
    [Test] procedure FalhaNoItemDesfazTudo;
    [Test] procedure FalhaPreservaPedidoEmMemoria;
    [Test] procedure NumeroConsumidoNaFalhaGeraLacuna;
    [Test] procedure SegundaGravacaoAtualizaMesmoNumero;
    [Test] procedure CarregarPedidoComProdutosRepetidos;
    [Test] procedure CarregarPedidoInexistenteFalha;
    [Test] procedure AtualizarPedidoCanceladoDesfaz;
    [Test] procedure CancelarPedidoExcluiItensECabecalho;
    [Test] procedure CancelarPedidoInexistenteDesfaz;
    [Test] procedure ClienteInexistenteNaoIniciaTransacao;
    [Test] procedure PedidoSemItensNaoIniciaTransacao;
    [Test] procedure GravaObservacao;
    [Test] procedure ObservacaoAcimaDoLimiteNaoIniciaTransacao;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions,
  Domain.Regras,
  Services.Pedido;

procedure TTestesPedidoService.Preparar;
begin
  FRegistro := TRegistroGravacao.Create;
  FService := TPedidoService.Create(TFakeClienteRepository.Create,
    TFakePedidoRepository.Create(FRegistro), TFakePedidoItemRepository.Create(FRegistro),
    TFakeTransacao.Create(FRegistro));
  FPedido := TPedido.Create(Date);
  FPedido.CodigoCliente := 1;
  FPedido.AdicionarItem(TDadosItemPedido.Criar(1, 'Produto 1', 2, 10));
  FPedido.AdicionarItem(TDadosItemPedido.Criar(1, 'Produto 1', 1.5, 0.05));
end;

procedure TTestesPedidoService.Liberar;
begin
  FreeAndNil(FPedido);
  FService := nil;
  FreeAndNil(FRegistro);
end;

procedure TTestesPedidoService.GravaCabecalhoEItensComCommit;
begin
  FService.GravarPedido(FPedido);
  Assert.AreEqual(1, FRegistro.Confirmadas);
  Assert.AreEqual(0, FRegistro.Desfeitas);
  Assert.AreEqual(1, FRegistro.CabecalhosConfirmados);
  Assert.AreEqual(2, FRegistro.ItensConfirmados);
  Assert.AreEqual<Currency>(20.08, FRegistro.TotalGravado);
end;

procedure TTestesPedidoService.NumeroAtribuidoSomenteAposCommit;
var
  LNumero: Integer;
begin
  Assert.IsFalse(FPedido.Persistido);
  LNumero := FService.GravarPedido(FPedido);
  Assert.AreEqual(1, LNumero);
  Assert.AreEqual(LNumero, FPedido.Numero);
end;

procedure TTestesPedidoService.FalhaNoItemDesfazTudo;
begin
  FRegistro.FalharNoItem := 2;
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end);
  Assert.AreEqual(1, FRegistro.Desfeitas);
  Assert.AreEqual(0, FRegistro.Confirmadas);
  Assert.AreEqual(0, FRegistro.CabecalhosConfirmados);
  Assert.AreEqual(0, FRegistro.ItensConfirmados);
  Assert.IsFalse(FRegistro.Ativa);
end;

procedure TTestesPedidoService.FalhaPreservaPedidoEmMemoria;
begin
  FRegistro.FalharNoItem := 1;
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end);
  Assert.IsFalse(FPedido.Persistido);
  Assert.AreEqual(2, FPedido.QuantidadeItens);
  Assert.AreEqual<Currency>(20.08, FPedido.ValorTotal);
end;

procedure TTestesPedidoService.NumeroConsumidoNaFalhaGeraLacuna;
begin
  FRegistro.FalharNoItem := 1;
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end);
  FRegistro.FalharNoItem := 0;
  Assert.AreEqual(2, FService.GravarPedido(FPedido));
end;

procedure TTestesPedidoService.SegundaGravacaoAtualizaMesmoNumero;
var
  LNumero: Integer;
begin
  LNumero := FService.GravarPedido(FPedido);
  FRegistro.PedidoExistente := LNumero;
  FPedido.AdicionarItem(TDadosItemPedido.Criar(2, 'Produto 2', 1, 1));
  Assert.AreEqual(LNumero, FService.GravarPedido(FPedido));
  Assert.AreEqual(1, FRegistro.Atualizados);
  Assert.AreEqual(1, FRegistro.ItensExcluidos);
  Assert.AreEqual(1, FRegistro.CabecalhosConfirmados);
  Assert.AreEqual(2 + 3, FRegistro.ItensConfirmados);
  Assert.AreEqual<Currency>(21.08, FRegistro.TotalGravado);
end;

procedure TTestesPedidoService.CarregarPedidoComProdutosRepetidos;
var
  LPedido: TPedido;
begin
  FRegistro.PedidoExistente := 7;
  LPedido := FService.CarregarPedido(7);
  try
    Assert.AreEqual(7, LPedido.Numero);
    Assert.AreEqual(2, LPedido.QuantidadeItens);
    Assert.AreEqual(LPedido.Itens[0].CodigoProduto, LPedido.Itens[1].CodigoProduto);
    Assert.AreNotEqual(LPedido.Itens[0].Id, LPedido.Itens[1].Id);
    Assert.AreEqual<Currency>(50, LPedido.ValorTotal);
    Assert.AreEqual('Gravado anteriormente', LPedido.Observacao);
  finally
    LPedido.Free;
  end;
end;

procedure TTestesPedidoService.CarregarPedidoInexistenteFalha;
begin
  Assert.WillRaise(procedure begin FService.CarregarPedido(99).Free; end,
    ERegistroNaoEncontradoException);
  Assert.IsFalse(FRegistro.Ativa);
end;

procedure TTestesPedidoService.AtualizarPedidoCanceladoDesfaz;
begin
  FService.GravarPedido(FPedido);
  FRegistro.PedidoExistente := 0;
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end,
    ERegistroNaoEncontradoException);
  Assert.AreEqual(1, FRegistro.Desfeitas);
  Assert.AreEqual(0, FRegistro.ItensExcluidos);
end;

procedure TTestesPedidoService.CancelarPedidoExcluiItensECabecalho;
begin
  FRegistro.PedidoExistente := 7;
  FService.CancelarPedido(7);
  Assert.AreEqual(1, FRegistro.ItensExcluidos);
  Assert.AreEqual(1, FRegistro.CabecalhosExcluidos);
  Assert.AreEqual(1, FRegistro.Confirmadas);
end;

procedure TTestesPedidoService.CancelarPedidoInexistenteDesfaz;
begin
  Assert.WillRaise(procedure begin FService.CancelarPedido(99); end,
    ERegistroNaoEncontradoException);
  Assert.AreEqual(1, FRegistro.Desfeitas);
  Assert.AreEqual(0, FRegistro.Confirmadas);
end;

procedure TTestesPedidoService.ClienteInexistenteNaoIniciaTransacao;
begin
  FPedido.CodigoCliente := CODIGO_MAXIMO_CADASTRADO + 1;
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end,
    ERegistroNaoEncontradoException);
  Assert.AreEqual(0, FRegistro.Iniciadas);
end;

procedure TTestesPedidoService.PedidoSemItensNaoIniciaTransacao;
begin
  FreeAndNil(FPedido);
  FPedido := TPedido.Create(Date);
  FPedido.CodigoCliente := 1;
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end, EValidacaoException);
  Assert.AreEqual(0, FRegistro.Iniciadas);
end;

procedure TTestesPedidoService.GravaObservacao;
begin
  FPedido.Observacao := '  Entregar pela manhã  ';
  FService.GravarPedido(FPedido);
  Assert.AreEqual('Entregar pela manhã', FRegistro.ObservacaoGravada);
end;

procedure TTestesPedidoService.ObservacaoAcimaDoLimiteNaoIniciaTransacao;
begin
  FPedido.Observacao := StringOfChar('x', TRegrasPedido.TAMANHO_MAXIMO_OBSERVACAO + 1);
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end, EValidacaoException);
  Assert.AreEqual(0, FRegistro.Iniciadas);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesPedidoService);

end.
