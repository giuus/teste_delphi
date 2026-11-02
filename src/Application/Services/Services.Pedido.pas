unit Services.Pedido;

{ Caso de uso de gravação do pedido.

  Responsabilidade transacional: este serviço inicia, confirma e desfaz a
  transação. Os repositórios recebem a mesma conexão (composição em
  TCompositionRoot) e nunca fazem commit por conta própria. }

interface

uses
  Domain.Pedido,
  Domain.Interfaces.Repositorios,
  Domain.Interfaces.Transacao,
  Services.Interfaces;

type
  TPedidoService = class(TInterfacedObject, IPedidoService)
  private
    FClienteRepository: IClienteRepository;
    FPedidoRepository: IPedidoRepository;
    FItemRepository: IPedidoItemRepository;
    FTransacao: ITransacao;
    procedure ValidarClienteExistente(ACodigoCliente: Integer);
    procedure DesfazerSeAtiva;
  public
    constructor Create(const AClienteRepository: IClienteRepository;
      const APedidoRepository: IPedidoRepository;
      const AItemRepository: IPedidoItemRepository;
      const ATransacao: ITransacao);
    function GravarPedido(APedido: TPedido): Integer;
  end;

implementation

uses
  System.SysUtils,
  Domain.Cliente,
  Domain.Exceptions;

constructor TPedidoService.Create(const AClienteRepository: IClienteRepository;
  const APedidoRepository: IPedidoRepository;
  const AItemRepository: IPedidoItemRepository;
  const ATransacao: ITransacao);
begin
  inherited Create;
  if AClienteRepository = nil then
    raise EArgumentNilException.Create('AClienteRepository');
  if APedidoRepository = nil then
    raise EArgumentNilException.Create('APedidoRepository');
  if AItemRepository = nil then
    raise EArgumentNilException.Create('AItemRepository');
  if ATransacao = nil then
    raise EArgumentNilException.Create('ATransacao');
  FClienteRepository := AClienteRepository;
  FPedidoRepository := APedidoRepository;
  FItemRepository := AItemRepository;
  FTransacao := ATransacao;
end;

procedure TPedidoService.ValidarClienteExistente(ACodigoCliente: Integer);
var
  LCliente: TCliente;
begin
  LCliente := FClienteRepository.BuscarPorCodigo(ACodigoCliente);
  try
    if LCliente = nil then
      raise ERegistroNaoEncontradoException.CreateFmt(
        'Cliente %d não encontrado. Consulte um cliente válido.', [ACodigoCliente]);
  finally
    LCliente.Free;
  end;
end;

procedure TPedidoService.DesfazerSeAtiva;
begin
  if FTransacao.Ativa then
    FTransacao.Desfazer;
end;

function TPedidoService.GravarPedido(APedido: TPedido): Integer;
var
  LNumero: Integer;
begin
  if APedido = nil then
    raise EArgumentNilException.Create('APedido');
  if APedido.Persistido then
    raise EValidacaoException.CreateFmt('O pedido %d já foi gravado.', [APedido.Numero]);

  APedido.ValidarParaGravacao;
  ValidarClienteExistente(APedido.CodigoCliente);

  FTransacao.Iniciar;
  try
    LNumero := FPedidoRepository.GerarNumero;
    FPedidoRepository.Inserir(LNumero, APedido);
    FItemRepository.InserirItens(LNumero, APedido);
    FTransacao.Confirmar;
  except
    DesfazerSeAtiva;
    raise;
  end;

  APedido.DefinirNumero(LNumero);
  Result := LNumero;
end;

end.
