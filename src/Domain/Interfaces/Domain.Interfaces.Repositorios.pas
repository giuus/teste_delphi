unit Domain.Interfaces.Repositorios;

{ Contratos de persistência. As implementações não fazem commit: a
  transação é controlada por quem coordena o caso de uso (ITransacao). }

interface

uses
  Domain.Cliente,
  Domain.Produto,
  Domain.Pedido;

type
  IClienteRepository = interface
    ['{5B730DD6-5ED6-4005-9DED-226A3D89FC09}']
    /// Retorna nil quando não existir. O chamador é dono do objeto retornado.
    function BuscarPorCodigo(ACodigo: Integer): TCliente;
  end;

  IProdutoRepository = interface
    ['{4F228613-E16E-4218-A6D4-326D3C06092D}']
    /// Retorna nil quando não existir. O chamador é dono do objeto retornado.
    function BuscarPorCodigo(ACodigo: Integer): TProduto;
  end;

  IPedidoRepository = interface
    ['{5CE87DAD-F980-494F-B6A8-F8C9F6BD846B}']
    /// Próximo valor da sequence do número do pedido.
    function GerarNumero: Integer;
    /// Insere o cabeçalho com o número informado (o pedido em memória só
    /// recebe o número depois do commit).
    procedure Inserir(ANumero: Integer; APedido: TPedido);
    /// Atualiza cliente, total e observação. Retorna False se não existir.
    function Atualizar(APedido: TPedido): Boolean;
    /// Exclusão física do cabeçalho. Retorna False se não existir.
    function Excluir(ANumero: Integer): Boolean;
    /// Cabeçalho do pedido (sem itens) ou nil. O chamador é dono do objeto.
    function BuscarPorNumero(ANumero: Integer): TPedido;
  end;

  IPedidoItemRepository = interface
    ['{A59244FE-EC50-435E-9297-A97853E715D5}']
    procedure InserirItens(ANumeroPedido: Integer; APedido: TPedido);
    procedure ExcluirPorPedido(ANumeroPedido: Integer);
    /// Adiciona ao pedido os itens gravados, na ordem de inclusão (ID).
    procedure CarregarItens(APedido: TPedido);
  end;

implementation

end.
