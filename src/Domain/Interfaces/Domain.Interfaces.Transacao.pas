unit Domain.Interfaces.Transacao;

interface

type
  /// Controle transacional compartilhado pelos repositórios de um caso de uso.
  ITransacao = interface
    ['{333E1C23-52D2-4A9B-B398-FA4C86020B8E}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Desfazer;
    function Ativa: Boolean;
  end;

implementation

end.
