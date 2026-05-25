-module(todo_http).

-export([add/3, del/3, list/3]).

%% ESI entry points: /todo/add, /todo/del, /todo/list
%% Each function has arity 3: (SessionID, Env, Input).
%% We return JSON via mod_esi:deliver/2.

add(SessionID, Env, Input) ->
    Params = parse_query(Env),
    case get_param("text", Params) of
        undefined ->
            deliver_json(SessionID, #{ok => false, error => <<"missing_text">>});
        Text ->
            case todo:add(Text) of
                {ok, Id} ->
                    deliver_json(SessionID, #{ok => true, id => Id});
                Error ->
                    deliver_json(SessionID, #{ok => false, error => format_error(Error)})
            end
    end.

del(SessionID, Env, Input) ->
    Params = parse_query(Env),
    case get_param("id", Params) of
        undefined ->
            deliver_json(SessionID, #{ok => false, error => <<"missing_id">>});
        IdStr ->
            case to_int(IdStr) of
                {ok, Id} when Id > 0 ->
                    io:format("What do we have here? id: ~p~n", [Id]),
                    case todo:del(Id) of
                        {ok, N} ->
                            deliver_json(SessionID, #{ok => true, deleted => N});
                        {error, not_found} ->
                            deliver_json(SessionID, #{ok => false, error => <<"not_found">>});
                        Error ->
                            deliver_json(SessionID, #{ok => false, error => format_error(Error)})
                    end;
                _ ->
                    deliver_json(SessionID, #{ok => false, error => <<"invalid_id">>})
            end
    end.

% http://localhost:8080/todo/todo_http:list

list(SessionID, _Env, _Input) ->
    io:format("list: ~p~n", [{SessionID, _Env, _Input}]),
    L = todo:list(),
    case L of
        {ok, Todos} ->
            %% Todos is a list of maps #{id => Id, text => Text, created_at => TS}.
            deliver_json(SessionID, #{todos => Todos});
        Error ->
            deliver_json(SessionID, #{ok => false, error => format_error(Error)})
    end.

%% Helpers

parse_query(Env) ->
    QS = proplists:get_value(query_string, Env, ""),
    uri_string:dissect_query(QS).

get_param(Key, KVs) ->
    proplists:get_value(Key, KVs).

to_int(Str) when is_list(Str) ->
    try
        {ok, list_to_integer(Str)}
    catch
        _:_ -> error
    end;
to_int(_Other) ->
    error.

format_error({error, Reason}) -> io_lib:format("~p", [Reason]);
format_error(Other) -> io_lib:format("~p", [Other]).

deliver_json(SessionID, Term) ->
    %% OTP 27+ stdlib json module.
    Body = json:encode(Term),

    mod_esi:deliver(SessionID, [
        "Content-Type: application/json\r\n\r\n", io_lib:format("~s", [Body])
    ]).
