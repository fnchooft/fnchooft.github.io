-module(session_monitor).
-export([find_lock_holders/1, await_lock_free/3]).

%% Return [{SessionId, [LockedDatastore]}] for sessions
%% that currently hold at least one lock.
find_lock_holders(Session) ->
    Filter = {subtree,
              [{'netconf-state',
                [{xmlns, "urn:ietf:params:xml:ns:yang:ietf-netconf-monitoring"}],
                [{sessions, []}]}]},
    {ok, Data} = netconf:get(Session, Filter),
    Sessions   = xpath_all(Data, "//session"),
    [{session_id(S), locked_datastores(S)}
     || S <- Sessions, locked_datastores(S) =/= []].

%% Block until no session holds a lock on Datastore,
%% or until Timeout milliseconds have elapsed.
await_lock_free(Session, Datastore, Timeout) ->
    Deadline = erlang:monotonic_time(millisecond) + Timeout,
    await_loop(Session, Datastore, Deadline).

await_loop(Session, Datastore, Deadline) ->
    case erlang:monotonic_time(millisecond) > Deadline of
        true ->
            {error, timeout};
        false ->
            Holders = find_lock_holders(Session),
            Locked  = [Id || {Id, Ds} <- Holders,
                             lists:member(Datastore, Ds)],
            case Locked of
                [] ->
                    ok;
                _ ->
                    logger:info("Waiting on lock holders: ~p", [Locked]),
                    timer:sleep(500),
                    await_loop(Session, Datastore, Deadline)
            end
    end.

%% ── Internal helpers ──────────────────────────────────────────

session_id(Node) ->
    xpath_text(Node, "session-id").

locked_datastores(Node) ->
    [binary_to_atom(T) || T <- xpath_texts(Node, "locked-datastores")].
