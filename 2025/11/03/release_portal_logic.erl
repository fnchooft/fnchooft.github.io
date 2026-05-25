-module(release_portal_logic).
-export([get_filtered_releases_for_user/1, get_user_permissions/1]).
-include("release_portal.hrl").

get_filtered_releases_for_user(Username) ->
    {AllowedReleases, UserRights} = get_user_permissions(Username),
    AllReleases = get_allowed_releases(AllowedReleases),
    filter_releases(AllReleases, UserRights).

get_user_permissions(Username) ->
    ContractFile = filename:join([code:priv_dir(release_portal), "contracts", Username ++ ".xml"]),
    release_portal_parser:parse_user_contract(ContractFile).

get_allowed_releases(AllowedReleases) ->
    CatalogDir = filename:join(code:priv_dir(release_portal), "catalog"),
    % Find all versions for the allowed releases
    ReleasePaths = lists:flatmap(
        fun(ReleaseName) ->
            filelib:wildcard(filename:join(CatalogDir, ReleaseName ++ "-*.xml"))
        end,
        AllowedReleases
    ),
    [release_portal_parser:parse_release_catalog(File) || File <- ReleasePaths].

filter_releases(Releases, UserRights) ->
    [
        Release#release{artifacts = filter_artifacts(Release#release.artifacts, UserRights)}
     || Release <- Releases
    ].

% For each artifact.type check if UserRights - type
filter_artifacts(Artifacts, UserRights) ->
    % README.md     misc
    % installer.bin x86_64
    % [Art || Art = #artifact{type = Type}, lists:member(Type, UserRights)].
    lists:filter(
        fun(#artifact{type = Type}) ->
            lists:member(Type, UserRights)
        end,
        Artifacts
    ).
