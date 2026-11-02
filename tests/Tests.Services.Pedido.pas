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
    [Test] procedure NaoRegravaPedidoJaGravado;
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

procedure TTestesPedidoService.NaoRegravaPedidoJaGravado;
begin
  FService.GravarPedido(FPedido);
  Assert.WillRaise(procedure begin FService.GravarPedido(FPedido); end, EValidacaoException);
  Assert.AreEqual(1, FRegistro.Iniciadas);
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
