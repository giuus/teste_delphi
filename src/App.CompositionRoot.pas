unit App.CompositionRoot;

{ Ponto único de composição das dependências.

  Ownership:
  - TConexaoFirebird (objeto comum) pertence a esta classe.
  - Repositórios, transação e serviços são interfaces com contagem de
    referência; vivem enquanto o controller os referenciar.
  - O controller (objeto comum) pertence a esta classe e é liberado ANTES da
    conexão, garantindo que nenhum repositório sobreviva a ela. }

interface

uses
  Infra.Configuracao,
  Infra.Conexao,
  Controllers.PedidoVenda;

type
  TCompositionRoot = class
  private
    FConexao: TConexaoFirebird;
    FPedidoVendaController: TPedidoVendaController;
    procedure CriarController;
  public
    /// Lê o config.ini de ADiretorioBase, conecta ao banco e monta o controller.
    constructor Create(const ADiretorioBase: string);
    destructor Destroy; override;
    property PedidoVendaController: TPedidoVendaController read FPedidoVendaController;
  end;

implementation

uses
  // Implementação de cursor de espera exigida pelo FireDAC em aplicações VCL.
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait,
  Domain.Interfaces.Repositorios,
  Domain.Interfaces.Transacao,
  Services.Interfaces,
  Services.ConsultaCadastro,
  Services.Pedido,
  Infra.Transacao,
  Infra.Repositorio.Cliente,
  Infra.Repositorio.Produto,
  Infra.Repositorio.Pedido,
  Infra.Repositorio.PedidoItem;

constructor TCompositionRoot.Create(const ADiretorioBase: string);
begin
  inherited Create;
  FConexao := TConexaoFirebird.Create(TLeitorConfiguracao.Carregar(ADiretorioBase));
  FConexao.Conectar;
  CriarController;
end;

destructor TCompositionRoot.Destroy;
begin
  FPedidoVendaController.Free;
  FConexao.Free;
  inherited Destroy;
end;

procedure TCompositionRoot.CriarController;
var
  LClienteRepository: IClienteRepository;
  LConsultaService: IConsultaCadastroService;
  LPedidoService: IPedidoService;
  LTransacao: ITransacao;
begin
  // Todos os repositórios e a transação usam a mesma conexão.
  LClienteRepository := TClienteRepository.Create(FConexao.Connection);
  LTransacao := TTransacaoFireDAC.Create(FConexao.Connection);

  LConsultaService := TConsultaCadastroService.Create(
    LClienteRepository,
    TProdutoRepository.Create(FConexao.Connection));

  LPedidoService := TPedidoService.Create(
    LClienteRepository,
    TPedidoRepository.Create(FConexao.Connection),
    TPedidoItemRepository.Create(FConexao.Connection),
    LTransacao);

  FPedidoVendaController := TPedidoVendaController.Create(LConsultaService, LPedidoService);
end;

end.
