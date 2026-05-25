-module(release_portal_app).
-behaviour(application).
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    start_httpd(),
    release_portal_sup:start_link().

stop(_State) -> ok.

start_httpd() ->
    inets:start(),
    AppDir = code:priv_dir(release_portal),
    HtDocs = filename:join(AppDir, "htdocs"),
    AuthUserFile = filename:join(AppDir, "auth/passwd"),
    AuthGroupFile = filename:join(AppDir, "auth/group"),
    
    LogDir = filename:join(AppDir, "log"),
    ok = filelib:ensure_dir(filename:join(LogDir, "dummy.log")),

    DefaultMods = [mod_alias, mod_auth, mod_esi, mod_actions, mod_cgi, mod_get, mod_head, mod_log, mod_disk_log],

    DownloadDir = filename:join(HtDocs, "download"),

    HTTPD_Args = [
        % {modules, [mod_esi, mod_get, mod_head, mod_alias, mod_auth, mod_log]},
        {modules, DefaultMods},
        {port, 8080},
        {server_name, "release_portal"},
        {server_root, AppDir},
        {document_root, HtDocs},
        % Route ALL traffic
        {erl_script_alias, {"/download", [release_portal_service]}},
        {erl_script_nocache, true},
        
        {directory_index, ["index.html"]},
        {default_type, "text/plain"},
        
        % Get some logging going...
        {error_log, filename:join(LogDir, "error.log")},
        {transfer_log, filename:join(LogDir, "access.log")},
        {security_log, filename:join(LogDir, "security.log")},
        % Secure the whole server
        {directory,
            {DownloadDir, [
                {auth_type, "plain"},
                {auth_name, "Release Portal"},
                {auth_user_file, AuthUserFile},
                {auth_group_file, AuthGroupFile}
            ]}}
    ],
    inets:start(httpd, HTTPD_Args).
