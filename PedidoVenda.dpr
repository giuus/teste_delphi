program PedidoVenda;

uses
  Vcl.Forms,
  Vcl.Dialogs,
  System.SysUtils,
  System.UITypes,
  Domain.Exceptions in 'src\Domain\Exceptions\Domain.Exceptions.pas',
  Domain.Cliente in 'src\Domain\Entities\Domain.Cliente.pas',
  Domain.Produto in 'src\Domain\Entities\Domain.Produto.pas',
  Domain.Regras in 'src\Domain\Entities\Domain.Regras.pas',
  Domain.Pedido in 'src\Domain\Entities\Domain.Pedido.pas',
  Domain.Interfaces.Repositorios in 'src\Domain\Interfaces\Domain.Interfaces.Repositorios.pas',
  Domain.Interfaces.Transacao in 'src\Domain\Interfaces\Domain.Interfaces.Transacao.pas',
  Services.Interfaces in 'src\Application\Services\Services.Interfaces.pas',
  Services.ConsultaCadastro in 'src\Application\Services\Services.ConsultaCadastro.pas',
  Services.Pedido in 'src\Application\Services\Services.Pedido.pas',
  Infra.Exceptions in 'src\Infrastructure\Infra.Exceptions.pas',
  Infra.Configuracao in 'src\Infrastructure\Configuration\Infra.Configuracao.pas',
  Infra.Conexao in 'src\Infrastructure\Database\Infra.Conexao.pas',
  Infra.Transacao in 'src\Infrastructure\Database\Infra.Transacao.pas',
  Infra.Repositorio.Base in 'src\Infrastructure\Repositories\Infra.Repositorio.Base.pas',
  Infra.Repositorio.Cliente in 'src\Infrastructure\Repositories\Infra.Repositorio.Cliente.pas',
  Infra.Repositorio.Produto in 'src\Infrastructure\Repositories\Infra.Repositorio.Produto.pas',
  Infra.Repositorio.Pedido in 'src\Infrastructure\Repositories\Infra.Repositorio.Pedido.pas',
  Infra.Repositorio.PedidoItem in 'src\Infrastructure\Repositories\Infra.Repositorio.PedidoItem.pas',
  Controllers.PedidoVenda in 'src\Presentation\Controllers\Controllers.PedidoVenda.pas',
  Views.ConversaoEntrada in 'src\Presentation\Views\Views.ConversaoEntrada.pas',
  Views.PedidoVenda in 'src\Presentation\Views\Views.PedidoVenda.pas' {frmPedidoVenda},
  App.CompositionRoot in 'src\App.CompositionRoot.pas';

var
  Root: TCompositionRoot;
  FormPedido: TfrmPedidoVenda;

begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Pedido de Venda';

  try
    Root := TCompositionRoot.Create(TLeitorConfiguracao.DiretorioExecutavel);
  except
    on E: Exception do
    begin
      // Configuração ou conexão inválida: informa e encerra sem abrir a tela.
      MessageDlg('Não foi possível iniciar a aplicação.' + sLineBreak + sLineBreak +
        E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;

  try
    Application.CreateForm(TfrmPedidoVenda, FormPedido);
    FormPedido.Inicializar(Root.PedidoVendaController);
    Application.Run;
    // O formulário é liberado antes do controller que ele utiliza.
    FreeAndNil(FormPedido);
  finally
    Root.Free;
  end;
end.
