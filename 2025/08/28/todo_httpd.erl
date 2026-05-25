-module(todo_httpd).
-behaviour(gen_server).

-export([start_link/0]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(APP, todo).

-record(state, {httpd_pid}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    _Res = application:ensure_all_started(inets),
    {ok, Port} = application:get_env(?APP, port),
    {ok, BindAddr} = application:get_env(?APP, bind_address),
    PrivDir = code:priv_dir(?APP),
    LogDir = filename:join(PrivDir, "log"),
    ok = filelib:ensure_dir(filename:join(LogDir, "dummy.log")),
    ServiceConfig = [
        {port, Port},
        {bind_address, BindAddr},
        {server_name, "todo-server"},
        {server_root, PrivDir},
        {document_root, PrivDir},
        {erl_script_alias, {"/todo", [todo_http]}},
        {modules, [mod_esi, mod_get, mod_head, mod_log]},
        {error_log, filename:join(LogDir, "error.log")},
        {transfer_log, filename:join(LogDir, "access.log")}
    ],
    {ok, HttpdPid} = httpd:start_service(ServiceConfig),
    {ok, #state{httpd_pid = HttpdPid}}.

handle_call(_Req, _From, S) ->
    {reply, ok, S}.

handle_cast(_Msg, S) ->
    {noreply, S}.

handle_info(_Info, S) ->
    {noreply, S}.

terminate(_Reason, #state{httpd_pid = Pid}) ->
    catch httpd:stop_service(Pid),
    ok.

code_change(_OldVsn, S, _Extra) ->
    {ok, S}.
