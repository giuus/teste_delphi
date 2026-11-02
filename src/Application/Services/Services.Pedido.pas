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
    function InserirNovo(APedido: TPedido): Integer;
    procedure AtualizarExistente(APedido: TPedido);
    procedure ValidarNumero(ANumero: Integer);
  public
    constructor Create(const AClienteRepository: IClienteRepository;
      const APedidoRepository: IPedidoRepository;
      const AItemRepository: IPedidoItemRepository;
      const ATransacao: ITransacao);
    function GravarPedido(APedido: TPedido): Integer;
    function CarregarPedido(ANumero: Integer): TPedido;
    procedure CancelarPedido(ANumero: Integer);
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

procedure TPedidoService.ValidarNumero(ANumero: Integer);
begin
  if ANumero <= 0 then
    raise EValidacaoException.Create('Informe um número de pedido maior que zero.');
end;

function TPedidoService.InserirNovo(APedido: TPedido): Integer;
begin
  Result := FPedidoRepository.GerarNumero;
  FPedidoRepository.Inserir(Result, APedido);
  FItemRepository.InserirItens(Result, APedido);
end;

procedure TPedidoService.AtualizarExistente(APedido: TPedido);
begin
  // Mantém o número original; os itens são substituídos por completo para
  // não duplicar linhas nem depender dos IDs antigos.
  if not FPedidoRepository.Atualizar(APedido) then
    raise ERegistroNaoEncontradoException.CreateFmt(
      'O pedido %d não existe mais no banco (pode ter sido cancelado).', [APedido.Numero]);
  FItemRepository.ExcluirPorPedido(APedido.Numero);
  FItemRepository.InserirItens(APedido.Numero, APedido);
end;

function TPedidoService.GravarPedido(APedido: TPedido): Integer;
var
  LNumero: Integer;
begin
  if APedido = nil then
    raise EArgumentNilException.Create('APedido');

  APedido.ValidarParaGravacao;
  ValidarClienteExistente(APedido.CodigoCliente);

  FTransacao.Iniciar;
  try
    if APedido.Persistido then
    begin
      AtualizarExistente(APedido);
      LNumero := APedido.Numero;
    end
    else
      LNumero := InserirNovo(APedido);
    FTransacao.Confirmar;
  except
    DesfazerSeAtiva;
    raise;
  end;

  if not APedido.Persistido then
    APedido.DefinirNumero(LNumero);
  Result := LNumero;
end;

function TPedidoService.CarregarPedido(ANumero: Integer): TPedido;
var
  LPedido: TPedido;
begin
  ValidarNumero(ANumero);
  LPedido := nil;
  // Cabeçalho e itens lidos na mesma transação.
  FTransacao.Iniciar;
  try
    LPedido := FPedidoRepository.BuscarPorNumero(ANumero);
    if LPedido = nil then
      raise ERegistroNaoEncontradoException.CreateFmt('Pedido %d não encontrado.', [ANumero]);
    FItemRepository.CarregarItens(LPedido);
    FTransacao.Confirmar;
  except
    LPedido.Free;
    DesfazerSeAtiva;
    raise;
  end;
  Result := LPedido;
end;

procedure TPedidoService.CancelarPedido(ANumero: Integer);
begin
  ValidarNumero(ANumero);
  FTransacao.Iniciar;
  try
    FItemRepository.ExcluirPorPedido(ANumero);
    if not FPedidoRepository.Excluir(ANumero) then
      raise ERegistroNaoEncontradoException.CreateFmt('Pedido %d não encontrado.', [ANumero]);
    FTransacao.Confirmar;
  except
    DesfazerSeAtiva;
    raise;
  end;
end;

end.
