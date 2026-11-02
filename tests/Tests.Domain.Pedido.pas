unit Tests.Domain.Pedido;

interface

uses
  DUnitX.TestFramework,
  Domain.Pedido;

type
  [TestFixture]
  TTestesCalculoItem = class
  public
    [Test] procedure TotalSimples;
    [Test] procedure ArredondaMetadeParaCima;
    [Test] procedure ArredondaParaBaixoAbaixoDaMetade;
    [Test] procedure QuantidadeFracionaria;
    [Test] procedure LimitesMaximosNaoEstouram;
    [Test] procedure QuantidadeZeroInvalida;
    [Test] procedure QuantidadeComQuatroCasasInvalida;
    [Test] procedure QuantidadeAcimaDoLimiteInvalida;
    [Test] procedure ValorUnitarioZeroInvalido;
    [Test] procedure ValorUnitarioComTresCasasInvalido;
  end;

  [TestFixture]
  TTestesPedido = class
  private
    FPedido: TPedido;
    function Adicionar(ACodigoProduto: Integer; AQuantidade, AValor: Currency): Integer;
  public
    [Setup] procedure Preparar;
    [TearDown] procedure Liberar;
    [Test] procedure PedidoVazioTotalZero;
    [Test] procedure TotalEhSomaDosItensArredondados;
    [Test] procedure ProdutoRepetidoGeraLinhasIndependentes;
    [Test] procedure AtualizarAlteraSomenteAMesmaLinha;
    [Test] procedure RemoverRecalculaTotal;
    [Test] procedure RemoverUltimoItemZeraTotal;
    [Test] procedure RemoverMantemOutraLinhaDoMesmoProduto;
    [Test] procedure IdNaoEhReutilizadoAposRemocao;
    [Test] procedure RemoverItemInexistenteFalha;
    [Test] procedure GravacaoExigeCliente;
    [Test] procedure GravacaoExigeItens;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions,
  Domain.Regras;

{ TTestesCalculoItem }

procedure TTestesCalculoItem.TotalSimples;
begin
  Assert.AreEqual<Currency>(55.80, TRegrasPedido.CalcularTotalItem(2, 27.90));
end;

procedure TTestesCalculoItem.ArredondaMetadeParaCima;
begin
  // 1,5 x 0,05 = 0,075 -> 0,08
  Assert.AreEqual<Currency>(0.08, TRegrasPedido.CalcularTotalItem(1.5, 0.05));
  // 0,125 x 0,20 = 0,025 -> 0,03
  Assert.AreEqual<Currency>(0.03, TRegrasPedido.CalcularTotalItem(0.125, 0.20));
end;

procedure TTestesCalculoItem.ArredondaParaBaixoAbaixoDaMetade;
begin
  // 0,333 x 0,05 = 0,01665 -> 0,02 ; 1,123 x 8,39 = 9,42197 -> 9,42
  Assert.AreEqual<Currency>(0.02, TRegrasPedido.CalcularTotalItem(0.333, 0.05));
  Assert.AreEqual<Currency>(9.42, TRegrasPedido.CalcularTotalItem(1.123, 8.39));
end;

procedure TTestesCalculoItem.QuantidadeFracionaria;
begin
  // 2,345 kg x 49,90 = 117,0155 -> 117,02
  Assert.AreEqual<Currency>(117.02, TRegrasPedido.CalcularTotalItem(2.345, 49.90));
end;

procedure TTestesCalculoItem.LimitesMaximosNaoEstouram;
begin
  Assert.AreEqual<Currency>(9999999980000.00,
    TRegrasPedido.CalcularTotalItem(TRegrasPedido.QUANTIDADE_MAXIMA,
      TRegrasPedido.VALOR_UNITARIO_MAXIMO));
end;

procedure TTestesCalculoItem.QuantidadeZeroInvalida;
begin
  Assert.WillRaise(
    procedure begin TRegrasPedido.CalcularTotalItem(0, 1); end,
    EValidacaoException);
end;

procedure TTestesCalculoItem.QuantidadeComQuatroCasasInvalida;
begin
  Assert.WillRaise(
    procedure begin TRegrasPedido.CalcularTotalItem(1.0001, 1); end,
    EValidacaoException);
end;

procedure TTestesCalculoItem.QuantidadeAcimaDoLimiteInvalida;
begin
  Assert.WillRaise(
    procedure begin TRegrasPedido.CalcularTotalItem(1000000, 1); end,
    EValidacaoException);
end;

procedure TTestesCalculoItem.ValorUnitarioZeroInvalido;
begin
  Assert.WillRaise(
    procedure begin TRegrasPedido.CalcularTotalItem(1, 0); end,
    EValidacaoException);
end;

procedure TTestesCalculoItem.ValorUnitarioComTresCasasInvalido;
begin
  Assert.WillRaise(
    procedure begin TRegrasPedido.CalcularTotalItem(1, 1.001); end,
    EValidacaoException);
end;

{ TTestesPedido }

procedure TTestesPedido.Preparar;
begin
  FPedido := TPedido.Create(EncodeDate(2026, 1, 15));
end;

procedure TTestesPedido.Liberar;
begin
  FreeAndNil(FPedido);
end;

function TTestesPedido.Adicionar(ACodigoProduto: Integer; AQuantidade, AValor: Currency): Integer;
begin
  Result := FPedido.AdicionarItem(TDadosItemPedido.Criar(ACodigoProduto,
    'Produto ' + IntToStr(ACodigoProduto), AQuantidade, AValor)).Id;
end;

procedure TTestesPedido.PedidoVazioTotalZero;
begin
  Assert.AreEqual<Currency>(0, FPedido.ValorTotal);
end;

procedure TTestesPedido.TotalEhSomaDosItensArredondados;
begin
  Adicionar(1, 1.5, 0.05);   // 0,08
  Adicionar(2, 1.5, 0.05);   // 0,08
  // Soma dos itens arredondados (0,16), e não arredondamento da soma (0,15).
  Assert.AreEqual<Currency>(0.16, FPedido.ValorTotal);
end;

procedure TTestesPedido.ProdutoRepetidoGeraLinhasIndependentes;
var
  LId1, LId2: Integer;
begin
  LId1 := Adicionar(1, 2, 10);
  LId2 := Adicionar(1, 3, 10);
  Assert.AreEqual(2, FPedido.QuantidadeItens);
  Assert.AreNotEqual(LId1, LId2);
  Assert.AreEqual<Currency>(50, FPedido.ValorTotal);
end;

procedure TTestesPedido.AtualizarAlteraSomenteAMesmaLinha;
var
  LId1, LId2: Integer;
begin
  LId1 := Adicionar(1, 2, 10);
  LId2 := Adicionar(1, 3, 10);
  FPedido.AtualizarItem(LId2, TDadosItemPedido.Criar(1, 'Produto 1', 5, 12));
  Assert.AreEqual<Currency>(2, FPedido.ObterItem(LId1).Quantidade);
  Assert.AreEqual<Currency>(10, FPedido.ObterItem(LId1).ValorUnitario);
  Assert.AreEqual<Currency>(5, FPedido.ObterItem(LId2).Quantidade);
  Assert.AreEqual<Currency>(80, FPedido.ValorTotal);
end;

procedure TTestesPedido.RemoverRecalculaTotal;
var
  LId: Integer;
begin
  Adicionar(1, 1, 10);
  LId := Adicionar(2, 1, 5.55);
  FPedido.RemoverItem(LId);
  Assert.AreEqual<Currency>(10, FPedido.ValorTotal);
end;

procedure TTestesPedido.RemoverUltimoItemZeraTotal;
var
  LId: Integer;
begin
  LId := Adicionar(1, 1, 10);
  FPedido.RemoverItem(LId);
  Assert.AreEqual(0, FPedido.QuantidadeItens);
  Assert.AreEqual<Currency>(0, FPedido.ValorTotal);
end;

procedure TTestesPedido.RemoverMantemOutraLinhaDoMesmoProduto;
var
  LId1, LId2: Integer;
begin
  LId1 := Adicionar(1, 2, 10);
  LId2 := Adicionar(1, 3, 10);
  FPedido.RemoverItem(LId1);
  Assert.IsNull(FPedido.LocalizarItem(LId1));
  Assert.IsNotNull(FPedido.LocalizarItem(LId2));
  Assert.AreEqual<Currency>(30, FPedido.ValorTotal);
end;

procedure TTestesPedido.IdNaoEhReutilizadoAposRemocao;
var
  LId1, LId2: Integer;
begin
  LId1 := Adicionar(1, 1, 1);
  FPedido.RemoverItem(LId1);
  LId2 := Adicionar(1, 1, 1);
  Assert.AreNotEqual(LId1, LId2);
end;

procedure TTestesPedido.RemoverItemInexistenteFalha;
begin
  Assert.WillRaise(
    procedure begin FPedido.RemoverItem(999); end,
    ERegistroNaoEncontradoException);
end;

procedure TTestesPedido.GravacaoExigeCliente;
begin
  Adicionar(1, 1, 1);
  Assert.WillRaise(
    procedure begin FPedido.ValidarParaGravacao; end,
    EValidacaoException);
end;

procedure TTestesPedido.GravacaoExigeItens;
begin
  FPedido.CodigoCliente := 1;
  Assert.WillRaise(
    procedure begin FPedido.ValidarParaGravacao; end,
    EValidacaoException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesCalculoItem);
  TDUnitX.RegisterTestFixture(TTestesPedido);

end.
