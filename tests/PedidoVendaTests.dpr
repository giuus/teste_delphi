program PedidoVendaTests;

{ Testes de regras de negócio, serviço e controller com DUnitX (incluído no
  Delphi 10.3). Não dependem de Forms nem de conexão com o banco. }

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Domain.Exceptions in '..\src\Domain\Exceptions\Domain.Exceptions.pas',
  Domain.Cliente in '..\src\Domain\Entities\Domain.Cliente.pas',
  Domain.Produto in '..\src\Domain\Entities\Domain.Produto.pas',
  Domain.Regras in '..\src\Domain\Entities\Domain.Regras.pas',
  Domain.Pedido in '..\src\Domain\Entities\Domain.Pedido.pas',
  Domain.Interfaces.Repositorios in '..\src\Domain\Interfaces\Domain.Interfaces.Repositorios.pas',
  Domain.Interfaces.Transacao in '..\src\Domain\Interfaces\Domain.Interfaces.Transacao.pas',
  Services.Interfaces in '..\src\Application\Services\Services.Interfaces.pas',
  Services.ConsultaCadastro in '..\src\Application\Services\Services.ConsultaCadastro.pas',
  Services.Pedido in '..\src\Application\Services\Services.Pedido.pas',
  Controllers.PedidoVenda in '..\src\Presentation\Controllers\Controllers.PedidoVenda.pas',
  Tests.Fakes in 'Tests.Fakes.pas',
  Tests.Domain.Pedido in 'Tests.Domain.Pedido.pas',
  Tests.Services.Pedido in 'Tests.Services.Pedido.pas',
  Tests.Controllers.PedidoVenda in 'Tests.Controllers.PedidoVenda.pas';

var
  LRunner: ITestRunner;
  LResultados: IRunResults;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.FailsOnNoAsserts := False;
    LRunner.AddLogger(TDUnitXConsoleLogger.Create(True));
    LResultados := LRunner.Execute;
    if not LResultados.AllPassed then
      System.ExitCode := EXIT_ERRORS;
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
end.
