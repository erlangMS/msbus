%%********************************************************************
%% @title Módulo dispatcher
%% @version 1.0.0
%% @doc Módulo responsável pelo componente dispatcher do erlangMS.
%% @author Everton de Vargas Agilar <evertonagilar@gmail.com>
%% @copyright erlangMS Team
%%********************************************************************

-module(msbus_dispatcher).

-behavior(gen_server). 

-include("../include/msbus_config.hrl").
-include("../include/msbus_http_messages.hrl").

%% Server API
-export([start/0, stop/0]).

%% Client API
-export([dispatch_request/6]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/1, handle_info/2, terminate/2, code_change/3]).

% estado do servidor
-record(state, {}).

-define(SERVER, ?MODULE).

%%====================================================================
%% Server API
%%====================================================================

start() -> 
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
 
stop() ->
    gen_server:cast(?SERVER, shutdown).
 

%%====================================================================
%% Client API
%%====================================================================

dispatch_request(RID, Url, Metodo, From, HeaderDict, Payload) -> 
	gen_server:cast(?SERVER, {dispatch_request, RID, Url, Metodo, HeaderDict, Payload, From}).

	
 
%%====================================================================
%% gen_server callbacks
%%====================================================================
 
init([]) ->
    {ok, #state{}}. 
    
handle_cast(shutdown, State) ->
    {stop, normal, State};

handle_cast({dispatch_request, RID, Url, Metodo, HeaderDict, Payload, From}, State) ->
	do_dispatch_request(RID, Url, Metodo, HeaderDict, Payload, From),
	{noreply, State}.
    
handle_call({dispatch_request, RID, Url, Metodo, HeaderDict, Payload}, From, State) ->
	do_dispatch_request(RID, Url, Metodo, HeaderDict, Payload, From),
	{reply, ok, State}.

handle_info(State) ->
   {noreply, State}.

handle_info(_Msg, State) ->
   {noreply, State}.

terminate(_Reason, _State) ->
    ok.
 
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

	
%%====================================================================
%% Internal functions
%%====================================================================

%% @doc Despacha a requisição para o serviço correspondente
do_dispatch_request(RID, Url, Metodo, HeaderDict, Payload, From) ->
	case msbus_catalogo:lookup(Url, Metodo) of
		{ok, Servico, ParamsUrl} -> 
			Id = msbus_catalogo:get_property_servico(<<"id">>, Servico),
			msbus_health:collect(RID, request_dispatch, {Id, Url, ParamsUrl, Payload}),
			executa_servico(RID, From, HeaderDict, Payload, Servico, ParamsUrl);
		notfound -> 
			msbus_health:collect(RID, notfound, {Url, Metodo}),
			ErroInterno = io_lib:format(?MSG_SERVICO_NAO_ENCONTRADO, [Url]),
			From ! {error, servico_nao_encontrado, ErroInterno}
	end.

%% @doc Executa o serviço correspondente
executa_servico(RID, From, HeaderDict, Payload, Servico, ParamsUrl) ->
	NomeModule = msbus_catalogo:get_property_servico(<<"nome_module">>, Servico),
	Module = msbus_catalogo:get_property_servico(<<"module">>, Servico),
	Function = msbus_catalogo:get_property_servico(<<"function">>, Servico),
	Request = msbus_request:encode_request(HeaderDict, Payload, Servico, ParamsUrl),
	case executa_processo_erlang(RID, NomeModule, Module, Function, Request, From) of
		em_andamento -> ok;	%% o serviço se encarrega de enviar mensagem quando estiver pronto
		Error -> From ! Error
	end.

%% @doc Executa o processo erlang de um serviço
executa_processo_erlang(RID, NomeModule, Module, Function, Request, From) ->
	try
		case whereis(Module) of
			undefined -> 
				msbus_health:collect(RID, module_not_loaded, NomeModule),
				Module:start(),
				apply(Module, Function, [Request, From]);
			Pid -> 
				apply(Module, Function, [Request, From])
		end,
		em_andamento
	catch
		_Exception:ErroInterno ->  {error, servico_falhou, ErroInterno}
	end.