%%%-------------------------------------------------------------------
%% @doc todo top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(todo_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },
    DbChild = #{
        id => todo_db,
        start => {todo_db, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [todo_db]
    },
    HttpdChild = #{
        id => todo_httpd,
        start => {todo_httpd, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [todo_httpd]
    },
    ChildSpecs = [DbChild, HttpdChild],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
