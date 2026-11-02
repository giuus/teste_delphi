unit Services.ConsultaCadastro;

interface

uses
  Domain.Cliente,
  Domain.Produto,
  Domain.Interfaces.Repositorios,
  Services.Interfaces;

type
  TConsultaCadastroService = class(TInterfacedObject, IConsultaCadastroService)
  private
    FClienteRepository: IClienteRepository;
    FProdutoRepository: IProdutoRepository;
  public
    constructor Create(const AClienteRepository: IClienteRepository;
      const AProdutoRepository: IProdutoRepository);
    function ConsultarCliente(ACodigo: Integer): TCliente;
    function ConsultarProduto(ACodigo: Integer): TProduto;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions;

constructor TConsultaCadastroService.Create(const AClienteRepository: IClienteRepository;
  const AProdutoRepository: IProdutoRepository);
begin
  inherited Create;
  if AClienteRepository = nil then
    raise EArgumentNilException.Create('AClienteRepository');
  if AProdutoRepository = nil then
    raise EArgumentNilException.Create('AProdutoRepository');
  FClienteRepository := AClienteRepository;
  FProdutoRepository := AProdutoRepository;
end;

function TConsultaCadastroService.ConsultarCliente(ACodigo: Integer): TCliente;
begin
  if ACodigo <= 0 then
    raise EValidacaoException.Create('Informe um código de cliente maior que zero.');
  Result := FClienteRepository.BuscarPorCodigo(ACodigo);
  if Result = nil then
    raise ERegistroNaoEncontradoException.CreateFmt('Cliente %d não encontrado.', [ACodigo]);
end;

function TConsultaCadastroService.ConsultarProduto(ACodigo: Integer): TProduto;
begin
  if ACodigo <= 0 then
    raise EValidacaoException.Create('Informe um código de produto maior que zero.');
  Result := FProdutoRepository.BuscarPorCodigo(ACodigo);
  if Result = nil then
    raise ERegistroNaoEncontradoException.CreateFmt('Produto %d não encontrado.', [ACodigo]);
end;

end.
