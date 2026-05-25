-module(todo).

-export([add/1, del/1, list/0]).

add(Text) ->
    todo_db:add(Text).

del(Id) ->
    todo_db:del(Id).

list() ->
    todo_db:list().
