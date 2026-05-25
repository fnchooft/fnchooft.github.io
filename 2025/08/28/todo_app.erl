%%%-------------------------------------------------------------------
%% @doc todo public API
%% @end
%%%-------------------------------------------------------------------

-module(todo_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    todo_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
