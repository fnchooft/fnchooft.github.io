%%% @doc
%%% otp29_new_features.erl
%%%
%%% A showcase module for the new features introduced in Erlang/OTP 29
%%% (as announced in the release candidate 3 on April 15, 2026).
%%%
%%% Reference: https://www.erlang.org/news/186
%%%
%%% NOTE: Some features (native_records, compr_assign) are guarded
%%%       behind feature flags and may require:
%%%         erlc -enable-feature native_records \
%%%              -enable-feature compr_assign   \
%%%              otp29_new_features.erl
%%%
%%% @author Fabian van 't Hooft
%%% @since  OTP 29.0-rc3

-module(otp29_new_features).
-author("Fabian van 't Hooft").

%% -------------------------------------------------------------------
%% Feature flags
%% Uncomment these when compiling with OTP 29 and the features enabled:
%% -------------------------------------------------------------------
%% -feature(native_records, enable).
%% -feature(compr_assign, enable).

-export([
    %% 1. is_integer/3 guard BIF
    demo_is_integer_guard/0,

    %% 2. Multi-valued comprehensions (EEP-78)
    demo_multi_valued_comprehensions/0,

    %% 3. rand:shuffle/1 (new in STDLIB)
    demo_rand_shuffle/0,

    %% 4. io_ansi – Virtual Terminal Sequences
    demo_io_ansi/0,

    %% 5. New compiler warnings (demonstrates intentional patterns to avoid)
    demo_compiler_warnings_guide/0,

    %% 6. Summary – run all demos
    run_all/0
]).

%% ===================================================================
%% 1. NEW GUARD BIF: is_integer/3
%%    Checks that a value is an integer AND within [Low, High] range.
%%    Previously required two separate guards.
%% ===================================================================

%% OTP 28 and earlier style:
old_style_range_check(I) when is_integer(I), I >= 0, I =< 100 ->
    {ok, I};
old_style_range_check(_) ->
    error.

%% OTP 29+ style – one guard does all three checks:
new_style_range_check(I) when is_integer(I, 0, 100) ->
    {ok, I};
new_style_range_check(_) ->
    error.

-spec demo_is_integer_guard() -> ok.
demo_is_integer_guard() ->
    io:format("~n=== 1. is_integer/3 guard BIF ===~n"),
    Tests = [42, 0, 100, 101, -1, 3.14, hello],
    lists:foreach(
        fun(V) ->
            Old = old_style_range_check(V),
            New = new_style_range_check(V),
            io:format("  Value ~w  =>  old: ~w  |  new: ~w~n", [V, Old, New])
        end,
        Tests
    ).

%% ===================================================================
%% 2. MULTI-VALUED COMPREHENSIONS (EEP-78)
%%    A generator can now yield multiple values per iteration step.
%%    [-I, I || I <- [1,2,3]]  =>  [-1, 1, -2, 2, -3, 3]
%% ===================================================================

-spec demo_multi_valued_comprehensions() -> ok.
demo_multi_valued_comprehensions() ->
    io:format("~n=== 2. Multi-valued comprehensions (EEP-78) ===~n"),

    %% Interleave negatives and positives in one comprehension:
    Interleaved = [-I, I || I <- [1, 2, 3]],
    io:format("  [-I, I || I <- [1,2,3]]  =>  ~w~n", [Interleaved]),

    %% Emit both the original and its square:
    WithSquares = [X, X * X || X <- lists:seq(1, 4)],
    io:format("  [X, X*X || X <- 1..4]    =>  ~w~n", [WithSquares]),

    %% Map comprehension – multi-valued form is also valid here:
    MapResult = #{K => V || K <- [a, b, c], V <- [1]},
    io:format("  Map comprehension        =>  ~w~n", [MapResult]).

%% ===================================================================
%% 3. rand:shuffle/1  (new in STDLIB)
%%    Randomly permutes a list.
%% ===================================================================

-spec demo_rand_shuffle() -> ok.
demo_rand_shuffle() ->
    io:format("~n=== 3. rand:shuffle/1 ===~n"),
    Original = lists:seq(1, 10),
    Shuffled = rand:shuffle(Original),
    io:format("  Original : ~w~n", [Original]),
    io:format("  Shuffled : ~w~n", [Shuffled]),

    %% Also demo the stateful variant rand:shuffle_s/2
    %% CORRECT – seed_s/1 returns a plain state() directly
    S0 = rand:seed_s(exsplus),
    {Shuffled2, _S1} = rand:shuffle_s(Original, S0),    
    
    io:format("  shuffle_s: ~w~n", [Shuffled2]).

%% ===================================================================
%% 4. io_ansi – Virtual Terminal Sequences (RC2 highlight)
%%    Emit ANSI/VT sequences for colours, bold, reset, etc.
%%    Works when the terminal supports VT sequences.
%% ===================================================================

-spec demo_io_ansi() -> ok.
demo_io_ansi() ->
    io:format("~n=== 4. io_ansi – Virtual Terminal Sequences ===~n"),
    %% io_ansi:format/2 is the new helper; the constants map to ANSI codes.
    io:format(
        "  ~s~s OTP 29 rocks! ~s~n",
        [
            io_ansi:green(),
            io_ansi:bold(),
            io_ansi:reset()
        ]
    ),
    io:format(
        "  ~sWarning text~s  ~sError text~s~n",
        [
            io_ansi:yellow(),
            io_ansi:reset(),
            io_ansi:red(),
            io_ansi:reset()
        ]
    ).

%% ===================================================================
%% 5. NEW COMPILER WARNINGS GUIDE
%%    OTP 29 enables several new warnings by default.
%%    This function documents each one and shows the PREFERRED pattern.
%% ===================================================================

-spec demo_compiler_warnings_guide() -> ok.
demo_compiler_warnings_guide() ->
    io:format("~n=== 5. New compiler warnings in OTP 29 ===~n"),

    Warnings = [
        {"catch operator deprecated",
         "Use try...catch instead of bare 'catch'.",
         "catch foo()  =>  try foo() catch _:_ -> error end",
         "nowarn_deprecated_catch"},
        {"Export var out of subexpression",
         "Do not bind variables in call arguments.",
         "file:open(F, Opts = [write])  =>  Opts=[write], file:open(F, Opts)",
         "nowarn_export_var_subexpr"},
        {"Obsolete bool operators 'and'/'or'",
         "Use 'andalso'/'orelse' (short-circuit).",
         "A and B  =>  A andalso B",
         "nowarn_obsolete_bool_op"},
        {"Match alias pattern",
         "Match both sides explicitly.",
         "{a,B} = {X,Y}  =>  a = X, B = Y  (or {a=X, B=Y})",
         "nowarn_match_alias_pats"}
    ],

    lists:foreach(
        fun({Title, Reason, Example, DisableOpt}) ->
            io:format(
                "  [~s]~n    Reason : ~s~n    Fix    : ~s~n    Disable: -compile([{~s,true}])~n~n",
                [Title, Reason, Example, DisableOpt]
            )
        end,
        Warnings
    ).

%% ===================================================================
%% 6. NATIVE RECORDS (EEP-79) – compile-time note
%%    Native records are experimental in OTP 29 and require the feature
%%    flag.  Uncomment the -feature directive at the top and recompile:
%%
%%      erlc -enable-feature native_records otp29_new_features.erl
%%
%%    Syntax preview (not compiled by default):
%%
%%    -record(point, {x :: number(), y :: number()}).
%%
%%    With native records you would write:
%%
%%      P = #point{x=1, y=2},
%%      #point{x=X} = P,            %% Pattern match (same as before)
%%      P2 = P#point{x = X + 1},   %% Update (same syntax)
%%
%%    The key difference: native records are a true data type rather
%%    than syntactic sugar over tuples.  record_is/2 and other guards
%%    work directly on the new data type.
%% ===================================================================

%% ===================================================================
%% 7. SSH SECURITY DEFAULTS (RC1 + RC3 highlights)
%%    Documented here as runtime behaviour changes (not code changes).
%%
%%    * The SSH daemon no longer enables shell/exec by default.
%%      To restore the old behaviour:
%%
%%        ssh:daemon(Port, [
%%            {shell, fun(_User) -> {ok, self()} end},
%%            {exec, {direct, fun(Cmd,_,_) -> ... end}}
%%        ]).
%%
%%    * SFTP is disabled by default.  To enable:
%%
%%        ssh:daemon(Port, [
%%            {subsystems, [ssh_sftpd:subsystem_spec([])]}
%%        ]).
%%
%%    * Default key exchange is now mlkem768x25519-sha256
%%      (post-quantum hybrid, X25519 + ML-KEM-768).
%% ===================================================================

%% ===================================================================
%% run_all/0 – convenience entry point
%% ===================================================================

-spec run_all() -> ok.
run_all() ->
    io:format("~n**** Erlang/OTP 29 – New Features Demo ****~n"),
    demo_is_integer_guard(),
    demo_multi_valued_comprehensions(),
    demo_rand_shuffle(),
    demo_io_ansi(),
    demo_compiler_warnings_guide(),
    io:format("~n**** Done! ****~n").
