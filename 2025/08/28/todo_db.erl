-module(todo_db).
-behaviour(gen_server).

%% Public API
-export([start_link/0, add/1, del/1, list/0]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(APP, todo).

-record(state, {db}).

%% Public API

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

add(Text) when is_list(Text) ->
    gen_server:call(?MODULE, {add, Text}).

del(Id) when is_integer(Id), Id > 0 ->
    gen_server:call(?MODULE, {del, Id}).

list() ->
    gen_server:call(?MODULE, list).

%% gen_server

init([]) ->
    CreateSql = """
    CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """,
    PrivDir = code:priv_dir(?APP),
    DbPath = filename:join(PrivDir, "todo.db"),
    ok = filelib:ensure_dir(DbPath),
    {ok, Db} = esqlite3:open(DbPath),
    ok = esqlite3:exec(Db, "PRAGMA foreign_keys=ON;"),
    ok = esqlite3:exec(Db, CreateSql),
    {ok, #state{db = Db}}.

handle_call({add, Text}, _From, #state{db = Db} = S) ->
    Sql = "INSERT INTO todos(text) VALUES(?);",
    [] = esqlite3:q(Db, Sql, [Text]),
    Id = esqlite3:last_insert_rowid(Db),
    {reply, {ok, Id}, S};
handle_call({del, Id}, _From, #state{db = Db} = S) ->
    Sql = "DELETE FROM todos WHERE id = ?;",
    Result = esqlite3:q(Db, Sql, [Id]),
    {reply, {ok, 1}, S};
handle_call(list, _From, #state{db = Db} = S) ->
    Sql = "SELECT id, text, created_at FROM todos ORDER BY id ASC;",
    case esqlite3:q(Db, Sql) of
        {error, Error} ->
            {reply, {error, Error}, S};
        Result ->
            {reply, {ok, to_map(Result)}, S}
    end.

handle_cast(_Msg, S) ->
    {noreply, S}.

handle_info(_Info, S) ->
    {noreply, S}.

terminate(_Reason, #state{db = Db}) ->
    catch esqlite3:close(Db),
    ok.

code_change(_OldVsn, S, _Extra) ->
    {ok, S}.

to_map(Result) ->
    lists:map(
        fun([Id, Text, CreatedAt]) ->
            #{id => Id, text => Text, created_at => CreatedAt}
        end,
        Result
    ).
