unit Domain.Exceptions;

{ Exceções de negócio. São erros que o operador pode corrigir (dados
  inválidos, registro inexistente) e por isso são exibidas como aviso.
  Falhas técnicas (banco, configuração) usam outras classes de exceção. }

interface

uses
  System.SysUtils;

type
  EValidacaoException = class(Exception);

  ERegistroNaoEncontradoException = class(EValidacaoException);

implementation

end.
