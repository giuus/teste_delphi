unit Infra.Exceptions;

{ Falhas técnicas (configuração e acesso ao banco). Diferente das exceções
  de validação, o operador normalmente não as resolve alterando os dados. }

interface

uses
  System.SysUtils;

type
  EInfraestruturaException = class(Exception);

  EConfiguracaoException = class(EInfraestruturaException);

  EConexaoBancoException = class(EInfraestruturaException);

implementation

end.
