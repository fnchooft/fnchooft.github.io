-module(release_portal_view).
-export([render_download_page/2]).
-include("release_portal.hrl").

render_download_page(Username, Releases) ->
    Header = io_lib:format(
        "<html><head><title>Downloads for ~s</title></head><body><h1>Welcome, ~s!</h1>", [
            Username, Username
        ]
    ),
    ReleaseHTML = [render_release(R) || R <- Releases],
    Footer = "</body></html>",
    [Header, ReleaseHTML, Footer].

render_release(#release{name = Name, version = Vsn, desc = Desc, artifacts = Arts}) ->
    case Arts of
        % Don't show releases for which the user has no downloadable files
        [] ->
            [];
        _ ->
            Header = io_lib:format("<h2>~s ~s - <i>~s</i></h2>", [Name, Vsn, Desc]),
            ArtifactList = ["<ul>", [render_artifact(Name, Vsn, A) || A <- Arts], "</ul>"],
            [Header, ArtifactList]
    end.

render_artifact(ReleaseName, Vsn, #artifact{name = Name}) ->
    URL = io_lib:format("/download/~s/~s/~s", [ReleaseName, Vsn, Name]),
    io_lib:format("<li><a href=\"~s\">~s</a></li>", [URL, Name]).
