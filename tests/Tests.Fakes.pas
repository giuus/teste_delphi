unit Tests.Fakes;

{ Implementações em memória dos repositórios e da transação, usadas para
  testar serviços e controller sem banco de dados. }

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Domain.Cliente,
  Domain.Produto,
  Domain.Pedido,
  Domain.Interfaces.Repositorios,
  Domain.Interfaces.Transacao;

type
  TFakeClienteRepository = class(TInterfacedObject, IClienteRepository)
  public
    function BuscarPorCodigo(ACodigo: Integer): TCliente;
  end;

  TFakeProdutoRepository = class(TInterfacedObject, IProdutoRepository)
  public
    function BuscarPorCodigo(ACodigo: Integer): TProduto;
  end;

  /// Registra o que foi executado para conferir commit/rollback nos testes.
  TRegistroGravacao = class
  public
    Iniciadas: Integer;
    Confirmadas: Integer;
    Desfeitas: Integer;
    Ativa: Boolean;
    ProximoNumero: Integer;
    CabecalhosPendentes: Integer;
    ItensPendentes: Integer;
    CabecalhosConfirmados: Integer;
    ItensConfirmados: Integer;
    FalharNoItem: Integer;
    TotalGravado: Currency;
    ObservacaoGravada: string;
    constructor Create;
  end;

  TFakeTransacao = class(TInterfacedObject, ITransacao)
  private
    FRegistro: TRegistroGravacao;
  public
    constructor Create(ARegistro: TRegistroGravacao);
    procedure Iniciar;
    procedure Confirmar;
    procedure Desfazer;
    function Ativa: Boolean;
  end;

  TFakePedidoRepository = class(TInterfacedObject, IPedidoRepository)
  private
    FRegistro: TRegistroGravacao;
  public
    constructor Create(ARegistro: TRegistroGravacao);
    function GerarNumero: Integer;
    procedure Inserir(ANumero: Integer; APedido: TPedido);
  end;

  TFakePedidoItemRepository = class(TInterfacedObject, IPedidoItemRepository)
  private
    FRegistro: TRegistroGravacao;
  public
    constructor Create(ARegistro: TRegistroGravacao);
    procedure InserirItens(ANumeroPedido: Integer; APedido: TPedido);
  end;

const
  /// Clientes e produtos de 1 a 10 existem nos fakes.
  CODIGO_MAXIMO_CADASTRADO = 10;

implementation

{ TFakeClienteRepository }

function TFakeClienteRepository.BuscarPorCodigo(ACodigo: Integer): TCliente;
begin
  if (ACodigo >= 1) and (ACodigo <= CODIGO_MAXIMO_CADASTRADO) then
    Result := TCliente.Create(ACodigo, 'Cliente ' + IntToStr(ACodigo), 'Cidade', 'SP')
  else
    Result := nil;
end;

{ TFakeProdutoRepository }

function TFakeProdutoRepository.BuscarPorCodigo(ACodigo: Integer): TProduto;
begin
  if (ACodigo >= 1) and (ACodigo <= CODIGO_MAXIMO_CADASTRADO) then
    Result := TProduto.Create(ACodigo, 'Produto ' + IntToStr(ACodigo), ACodigo * 1.5)
  else
    Result := nil;
end;

{ TRegistroGravacao }

constructor TRegistroGravacao.Create;
begin
  inherited Create;
  ProximoNumero := 1;
end;

{ TFakeTransacao }

constructor TFakeTransacao.Create(ARegistro: TRegistroGravacao);
begin
  inherited Create;
  FRegistro := ARegistro;
end;

procedure TFakeTransacao.Iniciar;
begin
  if FRegistro.Ativa then
    raise EInvalidOpException.Create('Transação já iniciada.');
  Inc(FRegistro.Iniciadas);
  FRegistro.Ativa := True;
end;

procedure TFakeTransacao.Confirmar;
begin
  Inc(FRegistro.Confirmadas);
  Inc(FRegistro.CabecalhosConfirmados, FRegistro.CabecalhosPendentes);
  Inc(FRegistro.ItensConfirmados, FRegistro.ItensPendentes);
  FRegistro.CabecalhosPendentes := 0;
  FRegistro.ItensPendentes := 0;
  FRegistro.Ativa := False;
end;

procedure TFakeTransacao.Desfazer;
begin
  Inc(FRegistro.Desfeitas);
  FRegistro.CabecalhosPendentes := 0;
  FRegistro.ItensPendentes := 0;
  FRegistro.Ativa := False;
end;

function TFakeTransacao.Ativa: Boolean;
begin
  Result := FRegistro.Ativa;
end;

{ TFakePedidoRepository }

constructor TFakePedidoRepository.Create(ARegistro: TRegistroGravacao);
begin
  inherited Create;
  FRegistro := ARegistro;
end;

function TFakePedidoRepository.GerarNumero: Integer;
begin
  // Como uma sequence: o valor consumido não volta em rollback.
  Result := FRegistro.ProximoNumero;
  Inc(FRegistro.ProximoNumero);
end;

procedure TFakePedidoRepository.Inserir(ANumero: Integer; APedido: TPedido);
begin
  if not FRegistro.Ativa then
    raise EInvalidOpException.Create('Inserir fora de transação.');
  Inc(FRegistro.CabecalhosPendentes);
  FRegistro.TotalGravado := APedido.ValorTotal;
  FRegistro.ObservacaoGravada := APedido.Observacao;
end;

{ TFakePedidoItemRepository }

constructor TFakePedidoItemRepository.Create(ARegistro: TRegistroGravacao);
begin
  inherited Create;
  FRegistro := ARegistro;
end;

procedure TFakePedidoItemRepository.InserirItens(ANumeroPedido: Integer; APedido: TPedido);
var
  LIndice: Integer;
begin
  if not FRegistro.Ativa then
    raise EInvalidOpException.Create('Inserir fora de transação.');
  for LIndice := 0 to APedido.QuantidadeItens - 1 do
  begin
    if FRegistro.FalharNoItem = LIndice + 1 then
      raise Exception.CreateFmt('Falha simulada ao gravar o item %d.', [LIndice + 1]);
    Inc(FRegistro.ItensPendentes);
  end;
end;

end.
