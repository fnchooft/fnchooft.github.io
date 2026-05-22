-module(lock_and_edit).
-export([run/2]).

%% Lock both datastores defensively before editing.
%% Devices advertising :writable-running expose two independent
%% write paths — lock both or accept you have no exclusive access.
run(Session, Config) ->
    ok = netconf:lock(Session, candidate),
    ok = netconf:lock(Session, running),
    try
        ok = netconf:edit_config(Session, candidate, Config),
        ok = netconf:commit(Session)
    after
        %% Always release — even if edit_config or commit throws.
        netconf:unlock(Session, running),
        netconf:unlock(Session, candidate)
    end.
