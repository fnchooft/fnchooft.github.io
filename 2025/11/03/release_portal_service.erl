-module(release_portal_service).
-include("release_portal.hrl").
-include_lib("xmerl/include/xmerl.hrl").

-export([test/3,'GET'/3, 'GET /download/:RELEASE/:VERSION/:FILE'/3]).
-export([' HTTP/1.1'/3]).
-export([''/3]).

''(SessionID, Env, _Input) ->
    Username = proplists:get_value(remote_user, Env),
    io:format("empty user: ~p~n",[Username]),
    Response = "Content-Type: text/plain\r\n\r\nHello.",
    mod_esi:deliver(SessionID, Response).


' HTTP/1.1'(SessionID, Env, _Input) ->
    Username = proplists:get_value(remote_user, Env),
    io:format("HTTP/1.1 user: ~p~n",[Username]),
    Response = "Content-Type: text/plain\r\n\r\nHello.",
    mod_esi:deliver(SessionID, Response).


test(SessionID, Env, _Input) ->
    Username = proplists:get_value(remote_user, Env),
    io:format("test: user: ~p~n",[Username]),
    Response = "Content-Type: text/plain\r\n\r\nHello.",
    mod_esi:deliver(SessionID, Response).


% Handler for the main download page
'GET'(SessionID, Env, _Input) ->
    io:format("GET....~n"),
    Username = proplists:get_value(remote_user, Env),
    FilteredReleases = release_portal_logic:get_filtered_releases_for_user(Username),
    HTML = release_portal_view:render_download_page(Username, FilteredReleases),
    Response = ["Content-Type: text/html\r\n\r\n" | HTML],
    mod_esi:deliver(SessionID, Response).

% Handler for file downloads
'GET /download/:RELEASE/:VERSION/:FILE'(SessionID, Env, _Input) ->
    Username = proplists:get_value(remote_user, Env),
    Release = proplists:get_value(release, Env),
    Version = proplists:get_value(version, Env),
    File = proplists:get_value(file, Env),

    case can_user_download(Username, Release, Version, File) of
        true ->
            Filepath = filename:join([
                code:priv_dir(release_portal), "releases", Release, Version, File
            ]),
            mod_esi:deliver_file(SessionID, Filepath);
        false ->
            Response = "Content-Type: text/plain\r\n\r\nForbidden.",
            mod_esi:deliver(SessionID, Response, [{status, 403}])
    end.

%% SECURITY check: Verifies a user has rights to the release AND the artifact type.
can_user_download(Username, ReleaseName, Version, Filename) ->
    {AllowedReleases, UserRights} = release_portal_logic:get_user_permissions(Username),
    case lists:member(ReleaseName, AllowedReleases) of
        true ->
            CatalogFile = filename:join(
                code:priv_dir(release_portal), "catalog", ReleaseName ++ "-" ++ Version ++ ".xml"
            ),
            case filelib:is_file(CatalogFile) of
                true ->
                    #release{artifacts = Artifacts} = release_portal_parser:parse_release_catalog(
                        CatalogFile
                    ),
                    case lists:keyfind(Filename, #artifact.name, Artifacts) of
                        #artifact{type = Type} -> lists:member(Type, UserRights);
                        false -> false
                    end;
                false ->
                    false
            end;
        false ->
            % User is not allowed to access this release name
            false
    end.
