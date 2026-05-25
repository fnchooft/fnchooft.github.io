from langchain_text_splitters import RecursiveCharacterTextSplitter
import textwrap

def test_elixir_splitting():
    # Sample Erlang code with various constructs
    erlang_code = textwrap.dedent("""
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
    """).strip()

    # Create the text splitter with default settings
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=200,  # Small chunks for testing
        chunk_overlap=20,
        separators=["\n\n", "\n", " ", ""]  # Default separators
    )

    # Split the Erlang code
    chunks = splitter.split_text(erlang_code)

    # Display results
    print("="*50)
    print("ELRANG CODE SPLITTING TEST")
    print("="*50)
    print(f"\nOriginal code length: {len(erlang_code)} characters")
    print(f"Number of chunks: {len(chunks)}\n")

    for i, chunk in enumerate(chunks, 1):
        print(f"\nCHUNK {i} (Length: {len(chunk)})")
        print("-"*40)
        print(chunk)
        print("-"*40)

if __name__ == "__main__":
    test_elixir_splitting()