-record(artifact, {
    % README.md
    name :: string(),
    % misc
    type :: atom()
}).

-record(release, {
    % abc
    name :: string(),
    % 1.2.3
    version :: string(),
    % desc
    desc :: string(),
    artifacts = [] :: list(#artifact{})
}).
