%%********************************************************************
%% @title Module ems_webservice
%% @version 1.0.0
%% @doc Module ems_webservice
%% @author Everton de Vargas Agilar <evertonagilar@gmail.com>
%% @copyright ErlangMS Team
%%********************************************************************

-module(ems_web_service).

-behavior(gen_server). 

-include("../..//include/ems_config.hrl").
-include("../../include/ems_schema.hrl").

%% Server API
-export([start/1, start_link/1, stop/0]).

%% Client API
-export([execute/1]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/1, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%  Armazena o estado do service. 
-record(state, {request}). 



%%====================================================================
%% Server API
%%====================================================================

start(_) -> 
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
 
start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

stop() ->
    gen_server:cast(?SERVER, shutdown).
 
execute(Request = #request{rid = Rid,
						   node_exec = Node,
						   service=#service{host=Host, 
											service = ServName,
											module=Module, 
											function=Function,
											timeout = Timeout}}) ->
	case Host == '' of
		true ->	
			ems_logger:info("ems_web_service send local msg to ~p.", [ServName]),
			%?DEBUG("Exec: apply(~p, ~p, [~p])", [Module, Function, Request]),
			apply(Module, Function, [Request]);
		false ->
			WebService = ems_pool:checkout(ems_web_service),
			gen_server:cast(WebService, {execute_remote, Request}),
			ems_logger:info("ems_web_service send msg to ~p with timeout ~pms.", [{Module, Node}, Timeout]),
			receive 
				{Code, RidRemote, {Reason, ResponseData}} when RidRemote == Rid -> 
					?DEBUG("ems_web_service received msg from ~p: ~p.", [{Module, Node}, {Code, RidRemote, {Reason, ResponseData}}]),
					Reply = {Reason, Request#request{code = Code,
													 reason = Reason,
													 response_header = #{<<"ems-node">> => erlang:atom_to_binary(Node, utf8)},
													 response_data = ResponseData}};
				Msg -> 
					ems_logger:error("ems_web_service received invalid message ~p.", [Msg]), 
					Reply = {ok, Request#request{code = 500,
												 reason = einvalid_rec_message,
												 response_header = #{<<"ems-node">> => erlang:atom_to_binary(Node, utf8)},
												 response_data = {error, einvalid_rec_message}}}
				after Timeout ->
					?DEBUG("ems_web_service received a timeout while waiting ~pms for the result of a service from ~p.", [Timeout, {Module, Node}]),
					Reply = {error, Request#request{code = 503,
													reason = etimeout_service,
													response_header = #{<<"ems-node">> => erlang:atom_to_binary(Node, utf8)},
													response_data = {error, etimeout_service}}}
			end,
			ems_pool:checkin(ems_web_service, WebService),
			Reply
	end.



%%====================================================================
%% gen_server callbacks
%%====================================================================
 
init(_Args) ->
    process_flag(trap_exit, true),
    {ok, #state{}}. 
    
handle_cast(shutdown, State) ->
    {stop, normal, State};

handle_cast({execute_remote, Request}, _State) ->
	do_execute_remote(Request),
	{noreply, #state{request = Request}}.

handle_call(Msg, _From, State) ->
	{reply, Msg, State}.
    
handle_info(State) ->
   {noreply, State}.

handle_info(Msg, #state{request = #request{worker_send = Worker}}) ->
	Worker ! Msg,
	{noreply, #state{}}.

terminate(_Reason, _State) ->
    ok.
 
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
     
    
%%====================================================================
%% Funções internas
%%====================================================================
    
									 
do_execute_remote(#request{rid = Rid,
						   uri = Uri,
						   type = Type,
						   params_url = ParamsUrl,
						   querystring_map = QuerystringMap,
						   payload = Payload,
						   content_type = ContentType,
						   node_exec = Node,
						   service=#service{module_name = ModuleName, 
										    function_name = FunctionName, 
										    module = Module}}) ->
	Msg = {{Rid, Uri, Type, ParamsUrl, QuerystringMap, Payload, ContentType, ModuleName, FunctionName}, self()},
	?DEBUG("ems_web_service send remote msg to ~p: ~p.", [{Module, Node}, Msg]),
	{Module, Node} ! Msg.
