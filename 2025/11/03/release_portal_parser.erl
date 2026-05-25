-module(release_portal_parser).
-export([parse_release_catalog/1, parse_user_contract/1]).
-include("release_portal.hrl").
-include_lib("xmerl/include/xmerl.hrl").

elem(Doc, XPath) ->
    Result = xmerl_xpath:string(XPath, Doc),
    [Value || #xmlText{value = Value} <- Result].

attr(Doc, XPath) ->
    Result = xmerl_xpath:string(XPath, Doc),
    [Value || #xmlAttribute{value = Value} <- Result].

%% This function is correct as it only extracts single values.
parse_release_catalog(Filepath) ->
    {ok, Bin} = file:read_file(Filepath),
    {Parsed, _} = xmerl_scan:string(binary_to_list(Bin), []),
    Name = attr(Parsed, "/release/@name"),
    Version = attr(Parsed, "/release/@version"),
    Desc = elem(Parsed, "/release/desc/text()"),
    % Here we use evaluate because we expect multiple artifact nodes
    ArtifactNodes = xmerl_xpath:string("/release/artifacts/artifact", Parsed),
    Artifacts = [
        #artifact{
            name = attr(Node, "@name"),
            type = attr(Node, "@type")
        }
     || Node <- ArtifactNodes
    ],
    #release{
        name = lists:flatten(Name),
        version = lists:flatten(Version),
        desc = lists:flatten(Desc),
        artifacts = Artifacts
    }.

%% This function has been corrected to handle multiple nodes for releases and rights.
parse_user_contract(Filepath) ->
    case file:read_file(Filepath) of
        {ok, Bin} ->
            {Parsed, _} = xmerl_scan:string(binary_to_list(Bin), []),
            % CORRECTED: Use evaluate to get a list of all matching nodes
            AllowedReleases = elem(Parsed,"/user/releases/release/text()"),
            AllowedTypes = elem(Parsed, "/user/rights/type/text()"),

            % CORRECTED: Pattern match on the records returned by evaluate
            % AllowedReleases = [lists:flatten(Val) || #xmlText{value = Val} <- ReleaseNodes],
            % AllowedTypes = [lists:flatten(Val) || #xmlText{value = Val} <- RightsNodes],

            {AllowedReleases, AllowedTypes};
        {error, enoent} ->
            % No contract file means no access
            {[], []}
    end.
