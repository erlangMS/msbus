-module(msbus_logger_tests).

-include_lib("eunit/include/eunit.hrl").

start_server_test() ->
	%% Inicia o barramento antes de executar os testes
	file:set_cwd("/home/agilar/Dropbox/workspace/erlang/erlangMS/msbus"),
	code:add_path("/home/agilar/Dropbox/workspace/erlang/erlangMS/msbus/deps/jsx/ebin"),
	application:start(msbus),
	ok.

logger_test() ->
	msbus_logger:error("Mensagem erro sem parametro."),
	msbus_logger:info("Mensagem info sem parametro."),
	msbus_logger:warn("Mensagem warn sem parametro."),
	ok.

logger_com_params_test() ->
	msbus_logger:error("Mensagem ~p sem parametro.", ["erro"]),
	msbus_logger:info("Mensagem ~p sem parametro.", ["info"]),
	msbus_logger:warn("Mensagem ~p sem parametro.", ["warn"]),	
	ok.

stop_server_test() ->
	application:stop(msbus),
	ok.
	
