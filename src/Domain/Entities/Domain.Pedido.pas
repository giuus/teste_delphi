unit Domain.Pedido;

interface

uses
  System.Generics.Collections;

type
  /// Dados informados para incluir ou alterar um item.
  TDadosItemPedido = record
    CodigoProduto: Integer;
    DescricaoProduto: string;
    Quantidade: Currency;
    ValorUnitario: Currency;
    class function Criar(ACodigoProduto: Integer; const ADescricaoProduto: string;
      AQuantidade, AValorUnitario: Currency): TDadosItemPedido; static;
  end;

  TPedidoItem = class
  private
    FId: Integer;
    FCodigoProduto: Integer;
    FDescricaoProduto: string;
    FQuantidade: Currency;
    FValorUnitario: Currency;
  public
    constructor Create(AId: Integer; const ADados: TDadosItemPedido);
    procedure Alterar(const ADados: TDadosItemPedido);
    function ValorTotal: Currency;
    class procedure Validar(const ADados: TDadosItemPedido); static;
    /// Identidade do item em memória, atribuída pelo pedido. Não depende da
    /// posição na grade nem do ID gerado pelo banco, permitindo que o mesmo
    /// produto apareça em várias linhas independentes.
    property Id: Integer read FId;
    property CodigoProduto: Integer read FCodigoProduto;
    property DescricaoProduto: string read FDescricaoProduto;
    property Quantidade: Currency read FQuantidade;
    property ValorUnitario: Currency read FValorUnitario;
  end;

  TPedido = class
  private
    FNumero: Integer;
    FDataEmissao: TDateTime;
    FCodigoCliente: Integer;
    FObservacao: string;
    FItens: TObjectList<TPedidoItem>;
    FUltimoIdItem: Integer;
    function GetItem(AIndice: Integer): TPedidoItem;
    function IndiceDoItem(AIdItem: Integer): Integer;
    procedure SetObservacao(const AValor: string);
  public
    constructor Create(ADataEmissao: TDateTime);
    destructor Destroy; override;

    function AdicionarItem(const ADados: TDadosItemPedido): TPedidoItem;
    procedure AtualizarItem(AIdItem: Integer; const ADados: TDadosItemPedido);
    procedure RemoverItem(AIdItem: Integer);
    function LocalizarItem(AIdItem: Integer): TPedidoItem;
    function ObterItem(AIdItem: Integer): TPedidoItem;
    function QuantidadeItens: Integer;
    function ValorTotal: Currency;

    /// Revalida cliente, itens e totais antes da persistência.
    procedure ValidarParaGravacao;

    /// Número atribuído somente após a gravação confirmada (ou ao carregar
    /// um pedido existente). Zero indica pedido ainda não gravado.
    procedure DefinirNumero(ANumero: Integer);
    function Persistido: Boolean;

    property Numero: Integer read FNumero;
    property DataEmissao: TDateTime read FDataEmissao;
    property CodigoCliente: Integer read FCodigoCliente write FCodigoCliente;
    /// Texto curto opcional (evolução: PEDIDO.OBSERVACAO).
    property Observacao: string read FObservacao write SetObservacao;
    /// Itens pertencem ao pedido; não libere as instâncias retornadas.
    property Itens[AIndice: Integer]: TPedidoItem read GetItem;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions,
  Domain.Regras;

{ TDadosItemPedido }

class function TDadosItemPedido.Criar(ACodigoProduto: Integer; const ADescricaoProduto: string;
  AQuantidade, AValorUnitario: Currency): TDadosItemPedido;
begin
  Result.CodigoProduto := ACodigoProduto;
  Result.DescricaoProduto := ADescricaoProduto;
  Result.Quantidade := AQuantidade;
  Result.ValorUnitario := AValorUnitario;
end;

{ TPedidoItem }

constructor TPedidoItem.Create(AId: Integer; const ADados: TDadosItemPedido);
begin
  inherited Create;
  FId := AId;
  Alterar(ADados);
end;

class procedure TPedidoItem.Validar(const ADados: TDadosItemPedido);
begin
  if ADados.CodigoProduto <= 0 then
    raise EValidacaoException.Create('Informe um produto válido para o item.');
  TRegrasPedido.ValidarQuantidade(ADados.Quantidade);
  TRegrasPedido.ValidarValorUnitario(ADados.ValorUnitario);
end;

procedure TPedidoItem.Alterar(const ADados: TDadosItemPedido);
begin
  Validar(ADados);
  FCodigoProduto := ADados.CodigoProduto;
  FDescricaoProduto := ADados.DescricaoProduto;
  FQuantidade := ADados.Quantidade;
  FValorUnitario := ADados.ValorUnitario;
end;

function TPedidoItem.ValorTotal: Currency;
begin
  Result := TRegrasPedido.CalcularTotalItem(FQuantidade, FValorUnitario);
end;

{ TPedido }

constructor TPedido.Create(ADataEmissao: TDateTime);
begin
  inherited Create;
  FDataEmissao := ADataEmissao;
  FItens := TObjectList<TPedidoItem>.Create(True);
end;

destructor TPedido.Destroy;
begin
  FItens.Free;
  inherited Destroy;
end;

function TPedido.AdicionarItem(const ADados: TDadosItemPedido): TPedidoItem;
var
  LItem: TPedidoItem;
begin
  // Valida o total resultante antes de alterar o estado do pedido.
  TRegrasPedido.SomarTotal(ValorTotal,
    TRegrasPedido.CalcularTotalItem(ADados.Quantidade, ADados.ValorUnitario));

  LItem := TPedidoItem.Create(FUltimoIdItem + 1, ADados);
  try
    FItens.Add(LItem);
  except
    LItem.Free;
    raise;
  end;
  Inc(FUltimoIdItem);
  Result := LItem;
end;

procedure TPedido.AtualizarItem(AIdItem: Integer; const ADados: TDadosItemPedido);
var
  LItem: TPedidoItem;
begin
  LItem := ObterItem(AIdItem);
  TRegrasPedido.SomarTotal(ValorTotal - LItem.ValorTotal,
    TRegrasPedido.CalcularTotalItem(ADados.Quantidade, ADados.ValorUnitario));
  LItem.Alterar(ADados);
end;

procedure TPedido.RemoverItem(AIdItem: Integer);
var
  LIndice: Integer;
begin
  LIndice := IndiceDoItem(AIdItem);
  if LIndice < 0 then
    raise ERegistroNaoEncontradoException.Create('Item não encontrado no pedido.');
  FItens.Delete(LIndice);
end;

function TPedido.IndiceDoItem(AIdItem: Integer): Integer;
var
  LIndice: Integer;
begin
  for LIndice := 0 to FItens.Count - 1 do
    if FItens[LIndice].Id = AIdItem then
      Exit(LIndice);
  Result := -1;
end;

function TPedido.LocalizarItem(AIdItem: Integer): TPedidoItem;
var
  LIndice: Integer;
begin
  LIndice := IndiceDoItem(AIdItem);
  if LIndice < 0 then
    Result := nil
  else
    Result := FItens[LIndice];
end;

function TPedido.ObterItem(AIdItem: Integer): TPedidoItem;
begin
  Result := LocalizarItem(AIdItem);
  if Result = nil then
    raise ERegistroNaoEncontradoException.Create('Item não encontrado no pedido.');
end;

function TPedido.GetItem(AIndice: Integer): TPedidoItem;
begin
  Result := FItens[AIndice];
end;

function TPedido.QuantidadeItens: Integer;
begin
  Result := FItens.Count;
end;

function TPedido.ValorTotal: Currency;
var
  LItem: TPedidoItem;
begin
  Result := 0;
  for LItem in FItens do
    Result := TRegrasPedido.SomarTotal(Result, LItem.ValorTotal);
end;

procedure TPedido.ValidarParaGravacao;
var
  LItem: TPedidoItem;
begin
  if FCodigoCliente <= 0 then
    raise EValidacaoException.Create('Informe um cliente válido para o pedido.');
  if FItens.Count = 0 then
    raise EValidacaoException.Create('Inclua pelo menos um item no pedido.');
  if Length(FObservacao) > TRegrasPedido.TAMANHO_MAXIMO_OBSERVACAO then
    raise EValidacaoException.CreateFmt('A observação aceita no máximo %d caracteres.',
      [TRegrasPedido.TAMANHO_MAXIMO_OBSERVACAO]);
  for LItem in FItens do
    TPedidoItem.Validar(TDadosItemPedido.Criar(LItem.CodigoProduto, LItem.DescricaoProduto,
      LItem.Quantidade, LItem.ValorUnitario));
  // Recalcula a partir dos itens; levanta exceção se exceder o limite.
  ValorTotal;
end;

procedure TPedido.SetObservacao(const AValor: string);
begin
  // O tamanho é validado na gravação, permitindo exibir a mensagem ao operador.
  FObservacao := Trim(AValor);
end;

procedure TPedido.DefinirNumero(ANumero: Integer);
begin
  if ANumero <= 0 then
    raise EArgumentOutOfRangeException.Create('Número de pedido inválido.');
  FNumero := ANumero;
end;

function TPedido.Persistido: Boolean;
begin
  Result := FNumero > 0;
end;

end.
