-module(msbus_rest_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("stdlib/include/qlc.hrl").
-include("../include/msbus_schema.hrl").

	
start_server_test() ->
	msbus_logger:info("========= Testes RESTfull ==========="),
	file:set_cwd("/home/agilar/Dropbox/workspace/erlang/erlangMS/msbus"),
	code:add_path("/home/agilar/Dropbox/workspace/erlang/erlangMS/msbus/deps/jsx/ebin"),
	application:start(msbus),
	application:start(inets),
	ok.

dominio() -> "http://localhost:2301".

%% Retorno 200

get_root_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio(), []}, [], []).

get_root_com_dois_backslash_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/", []}, [], []).

get_info_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/info", []}, [], []).

get_catalogo_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/catalogo", []}, [], []).

get_user_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/user", []}, [], []).

get_health_top_services_10_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/health/top_services/10", []}, [], []).

get_health_top_services_query_string_invalida_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/health/top_services/99999?codigo=100&periodo=NULL", []}, [], []).

get_portal_index_test() ->
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/portal/index.html", []}, [], []).


%% Erros 404

get_url_estranha_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/(**&($%#%$$", []}, [], []).

get_servico_nao_existe_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/naoexiste", []}, [], []).

get_url_grande_test() ->
	Url = string:copies("A", 1000),
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/" ++ Url, []}, [], []).

get_url_com_espacos_test() ->
	msbus_logger:info("\n\nTEST: Esperado um erro 400 <<invaliad_request>> pois os espaços vão dar problema no cabeçalho."),
	msbus_logger:info("OBS.: Em browsers é realizado o encode da URL então dificilmente este erro vai ocorrer."),
	{ok, {{_Version, 400, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/um serviço que não existe/", []}, [], []).

	
get_user_id_invalido_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/user/9*&&&¨%#%$@$#", []}, [], []).

get_get_user_negativo_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/user/-10", []}, [], []).

get_health_top_services_sem_parametro_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/health/top_services/", []}, [], []).

get_arquivo_estatico_nao_existe_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/portal/index___.html", []}, [], []).

get_arquivo_estatico_mime_type_nao_existe_test() ->
	{ok, {{_Version, 404, _ReasonPhrase}, _Headers, _Body}} = httpc:request(get, {dominio() ++ "/portal/index.html5", []}, [], []).

	

stop_server_test() ->
	msbus_logger:info("Finalizando os testes..."),
	application:stop(inets),
	application:stop(msbus),
	ok.
	


