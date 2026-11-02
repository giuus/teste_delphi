unit Domain.Regras;

{ Regras de cálculo e limites do pedido.

  Limites (espelham os tipos de database/db.sql):
    Quantidade      NUMERIC(9,3)  -> 0,001 a 999.999,999
    Valor unitário  NUMERIC(9,2)  -> 0,01  a 9.999.999,99
    Totais          NUMERIC(18,2)

  Política de arredondamento:
    Total do item   = Quantidade x Valor unitário, arredondado para 2 casas,
                      metade para cima (0,005 -> 0,01). É a mesma regra de
                      ROUND(x, 2) do Firebird, verificada pelo CHECK
                      CK_PEDIDO_ITEM_VLR_TOTAL.
    Total do pedido = soma dos totais dos itens já arredondados (sem novo
                      arredondamento, portanto sempre igual à soma da grade).

  O cálculo é feito em aritmética inteira (milésimos x centavos) para não
  depender da precisão de ponto flutuante: com os limites acima o produto
  cabe em Int64 (999.999.999 x 999.999.999 < 9,22 x 10^18). }

interface

type
  TRegrasPedido = class
  public const
    CASAS_QUANTIDADE = 3;
    CASAS_VALOR = 2;
    QUANTIDADE_MAXIMA: Currency = 999999.999;
    VALOR_UNITARIO_MAXIMO: Currency = 9999999.99;
    // Limite de negócio para o total do pedido. Fica abaixo do limite do
    // Currency (~9,2 x 10^14) e do NUMERIC(18,2), evitando estouro na soma.
    VALOR_TOTAL_PEDIDO_MAXIMO: Currency = 99999999999999.99;
  public
    class function CalcularTotalItem(AQuantidade, AValorUnitario: Currency): Currency; static;
    class function SomarTotal(ATotalAtual, AValor: Currency): Currency; static;
    class function PossuiNoMaximoCasas(AValor: Currency; ACasas: Integer): Boolean; static;
    class procedure ValidarQuantidade(AQuantidade: Currency); static;
    class procedure ValidarValorUnitario(AValorUnitario: Currency); static;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions;

function CentavosParaCurrency(ACentavos: Int64): Currency;
begin
  // Parte inteira e fração separadas para manter a conversão exata.
  Result := ACentavos div 100;
  Result := Result + (ACentavos mod 100) / 100;
end;

function DividirArredondandoMetadeParaCima(ADividendo, ADivisor: Int64): Int64;
begin
  // "Metade para cima" em valor absoluto (afastando de zero).
  if ADividendo >= 0 then
    Result := (ADividendo + ADivisor div 2) div ADivisor
  else
    Result := -((-ADividendo + ADivisor div 2) div ADivisor);
end;

{ TRegrasPedido }

class function TRegrasPedido.CalcularTotalItem(AQuantidade, AValorUnitario: Currency): Currency;
var
  LMilesimos: Int64;
  LCentavos: Int64;
  LProdutoEscala5: Int64;
begin
  ValidarQuantidade(AQuantidade);
  ValidarValorUnitario(AValorUnitario);

  // Valores já validados: as multiplicações abaixo resultam em inteiros exatos.
  LMilesimos := Round(AQuantidade * 1000);
  LCentavos := Round(AValorUnitario * 100);
  LProdutoEscala5 := LMilesimos * LCentavos;  // unidade = 0,00001

  Result := CentavosParaCurrency(DividirArredondandoMetadeParaCima(LProdutoEscala5, 1000));
end;

class function TRegrasPedido.SomarTotal(ATotalAtual, AValor: Currency): Currency;
begin
  if AValor > VALOR_TOTAL_PEDIDO_MAXIMO - ATotalAtual then
    raise EValidacaoException.CreateFmt(
      'O valor total do pedido não pode ultrapassar %s.',
      [CurrToStrF(VALOR_TOTAL_PEDIDO_MAXIMO, ffNumber, CASAS_VALOR)]);
  Result := ATotalAtual + AValor;
end;

class function TRegrasPedido.PossuiNoMaximoCasas(AValor: Currency; ACasas: Integer): Boolean;
var
  LFator: Integer;
  LIndice: Integer;
  LEscalado: Currency;
begin
  LFator := 1;
  for LIndice := 1 to ACasas do
    LFator := LFator * 10;
  LEscalado := AValor * LFator;
  Result := Frac(LEscalado) = 0;
end;

class procedure TRegrasPedido.ValidarQuantidade(AQuantidade: Currency);
begin
  if AQuantidade <= 0 then
    raise EValidacaoException.Create('A quantidade deve ser maior que zero.');
  if AQuantidade > QUANTIDADE_MAXIMA then
    raise EValidacaoException.CreateFmt('A quantidade não pode ser maior que %s.',
      [CurrToStrF(QUANTIDADE_MAXIMA, ffNumber, CASAS_QUANTIDADE)]);
  if not PossuiNoMaximoCasas(AQuantidade, CASAS_QUANTIDADE) then
    raise EValidacaoException.CreateFmt('A quantidade aceita no máximo %d casas decimais.',
      [CASAS_QUANTIDADE]);
end;

class procedure TRegrasPedido.ValidarValorUnitario(AValorUnitario: Currency);
begin
  if AValorUnitario <= 0 then
    raise EValidacaoException.Create('O valor unitário deve ser maior que zero.');
  if AValorUnitario > VALOR_UNITARIO_MAXIMO then
    raise EValidacaoException.CreateFmt('O valor unitário não pode ser maior que %s.',
      [CurrToStrF(VALOR_UNITARIO_MAXIMO, ffNumber, CASAS_VALOR)]);
  if not PossuiNoMaximoCasas(AValorUnitario, CASAS_VALOR) then
    raise EValidacaoException.CreateFmt('O valor unitário aceita no máximo %d casas decimais.',
      [CASAS_VALOR]);
end;

end.
