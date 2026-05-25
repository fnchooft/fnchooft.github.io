from tree_sitter_languages import get_language, get_parser

language = get_language('erlang')
parser = get_parser('erlang')
# Tree-sitter creates an abstract syntax tree (actually, a concrete syntax tree) and supports queries

def test_erlang_splitting():
    # Sample Erlang code with various constructs
    erlang_code = """
%% @doc This is a simple hello world module in Erlang
-module(hello_world).
-author("Your Name").
-version("1.0").

%% Export the main function
-export([greet/0, greet/1, greet/2]).

%% @doc Prints a generic greeting
greet() ->
    io:format("Hello, world!~n").

%% @doc Prints a personalized greeting
%% @param Name The name to greet
greet("Fabian"=Name) ->
    io:format("Hail to Overlord, ~s!~n", [Name]).

greet(Name) ->
    io:format("Hello, ~s!~n", [Name]).

greet(First,Last) ->
    io:format("Hello, ~s ~s!~n", [First,Last]).

%% Helper function (not exported)
capitalize(Name) ->
    string:titlecase(Name).    
    """

tree = parser.parse(test_erlang_splitting)
node = tree.root_node
print(node.sexp())
