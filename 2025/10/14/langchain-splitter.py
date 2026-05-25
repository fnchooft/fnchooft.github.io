## from langchain_community.document_loaders.generic import GenericLoader
## from langchain_community.document_loaders.parsers import LanguageParser
## loader = GenericLoader.from_filesystem(
##     ".",
##     glob="**/*",
##     suffixes=[".erl", ".hrl"],
##     parser=LanguageParser()
## )
## docs = loader.load()

#from langchain_community.document_loaders import GenericLoader

#loader = GenericLoader.from_filesystem(
#    path=".",
#    glob="**/[!.]*",
#    suffixes=[".erl"],
#    show_progress=True,
#)
#docs = loader.lazy_load()
#next(docs)

# Recursively load all text files in a directory.
#loader = GenericLoader.from_filesystem("/path/to/dir", glob="**/*.txt")
# Recursively load all non-hidden files in a directory.
#loader = GenericLoader.from_filesystem("/path/to/dir", glob="**/[!.]*")
# Load all files in a directory without recursion.
#loader = GenericLoader.from_filesystem(".", glob="*.erl")

from langchain_community.document_loaders.parsers.language.tree_sitter_segmenter import TreeSitterSegmenter
from langchain_community.document_loaders.parsers.language import LanguageParser


# Example for Python
ts = TreeSitterSegmenter(
"""
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
""")    
