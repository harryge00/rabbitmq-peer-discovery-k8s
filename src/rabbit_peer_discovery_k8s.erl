%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License at
%% https://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%% License for the specific language governing rights and limitations
%% under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is AWeber Communications.
%% Copyright (c) 2015-2016 AWeber Communications
%% Copyright (c) 2016-2017 Pivotal Software, Inc. All rights reserved.
%%

-module(rabbit_peer_discovery_k8s).
-behaviour(rabbit_peer_discovery_backend).

-include_lib("rabbit_common/include/rabbit.hrl").
-include_lib("rabbitmq_peer_discovery_common/include/rabbit_peer_discovery.hrl").
-include("rabbit_peer_discovery_k8s.hrl").

-export([init/0, list_nodes/0, supports_registration/0, register/0, unregister/0,
         post_registration/0, lock/1, unlock/1, randomized_startup_delay_range/0]).

-ifdef(TEST).
-compile(export_all).
-endif.

-define(CONFIG_MODULE, rabbit_peer_discovery_config).
-define(UTIL_MODULE,   rabbit_peer_discovery_util).
-define(HTTPC_MODULE,  rabbit_peer_discovery_httpc).

-define(BACKEND_CONFIG_KEY, peer_discovery_k8s).



%%
%% API
%%

init() ->
    rabbit_log:info("Peer discovery Mesos: initialising..."),
    ok = application:ensure_started(inets),
    %% we cannot start this plugin yet since it depends on the rabbit app,
    %% which is in the process of being started by the time this function is called
    application:load(rabbitmq_peer_discovery_common),
    rabbit_peer_discovery_httpc:maybe_configure_proxy().

-spec list_nodes() -> {ok, {Nodes :: list(), NodeType :: rabbit_types:node_type()}}.

list_nodes() ->
    case make_request() of
	{ok, Response} ->
	    Addresses = extract_node_list(Response),
      rabbit_log:debug("extract_node_list ~p", [Addresses]),

	    {ok, lists:map(fun node_name/1, Addresses)};
	{error, Reason} ->
	    rabbit_log:info(
	      "Failed to get nodes from k8s - ~s", [Reason]),
	    {error, Reason}
    end.

-spec supports_registration() -> boolean().

supports_registration() ->
    %% see rabbitmq-peer-discovery-aws#17,
    %%     rabbitmq-peer-discovery-k8s#23
    true.


-spec register() -> ok.
register() ->
    ok.

-spec unregister() -> ok.
unregister() ->
    ok.

-spec post_registration() -> ok | {error, Reason :: string()}.

post_registration() ->
    ok.

-spec lock(Node :: atom()) -> not_supported.

lock(_Node) ->
    not_supported.

-spec unlock(Data :: term()) -> ok.

unlock(_Data) ->
    ok.

-spec randomized_startup_delay_range() -> {integer(), integer()}.

randomized_startup_delay_range() ->
    %% Pods in a stateful set are initialized one by one,
    %% so RSD is not really necessary for this plugin.
    %% See https://www.rabbitmq.com/cluster-formation.html#peer-discovery-k8s for details.
    {0, 2}.

%%
%% Implementation
%%

-spec get_config_key(Key :: atom(), Map :: #{atom() => peer_discovery_config_value()})
                    -> peer_discovery_config_value().

get_config_key(Key, Map) ->
    ?CONFIG_MODULE:get(Key, ?CONFIG_MAPPING, Map).

%% @doc Perform a HTTP GET request to K8s
%% @end
%%
-spec make_request() -> {ok, term()} | {error, term()}.
make_request() ->
    M = ?CONFIG_MODULE:config_map(?BACKEND_CONFIG_KEY),
    ?HTTPC_MODULE:get(
      get_config_key(master_scheme, M),
      get_config_key(master_host, M),
      get_config_key(master_port, M),
      base_path(),
      [],
      [],
      []).

%% @spec node_name(k8s_endpoint) -> list()  
%% @doc Return a full rabbit node name, appending hostname suffix
%% @end
%%
node_name(Address) ->
    M = ?CONFIG_MODULE:config_map(?BACKEND_CONFIG_KEY),
    ?UTIL_MODULE:node_name(
       ?UTIL_MODULE:as_string(Address) ++ get_config_key(k8s_hostname_suffix, M)).
    

%% @doc Return a list of nodes
%%    see https://docs.d2iq.com/mesosphere/dcos/1.12/deploying-services/marathon-api/#/apps/V2AppsByAppId
%% @end
%%
-spec extract_node_list(term()) -> [binary()].
extract_node_list(Response) ->
    rabbit_log:debug("Response: ~p", [Response]),
    App = maps:get(<<"app">>, Response, maps:new()),
    rabbit_log:debug("App: ~p", [App]),
    Tasks = maps:get(<<"tasks">>, App, []),
    rabbit_log:debug("Tasks: ~p", Tasks), 
    lists:foreach(fun(Task) ->
      case maps:get(<<"state">>, Task, <<"TASK_RUNNING">>) of
        <<"TASK_RUNNING">> -> 
              IpLists = maps:get(<<"ipAddresses">>, Task, []),
              maps:get(<<"ipAddress">>, lists:nth(1, IpLists));
        _ ->
              rabbit_log:info("Marathon endpoint listing returned nodes not yet ready: ~s",
                              [Task]),
              []
      end
    end, Tasks).


%% @doc Return a list of path segments that are the base path for k8s key actions
%% @end
%%
-spec base_path() -> [?HTTPC_MODULE:path_component()].
base_path() ->
    M = ?CONFIG_MODULE:config_map(?BACKEND_CONFIG_KEY),
    %% TODO: improve the code
     [v2] ++ string:split("apps" ++ get_config_key(marathon_app_id, M), "/", all) .
