from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    Language,
)
from pathlib import Path
from typing import Union

# =============================================
# File Processing Functions
# =============================================

def process_file(file_path: Union[str, Path], language: str):
    """Process a file with the appropriate text splitter."""
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Create the appropriate splitter
    splitter = RecursiveCharacterTextSplitter.from_language(
        language=language,
        chunk_size=200,  # Smaller for demo purposes
        chunk_overlap=50
    )
    
    # Split the content
    chunks = splitter.split_text(content)
    
    # Print results
    print(f"\nProcessing {file_path} as {language}")
    print("=" * 50)
    print(f"Total chunks: {len(chunks)}")
    
    for i, chunk in enumerate(chunks, 1):
        print(f"\nChunk {i} (length: {len(chunk)}):")
        print("-" * 40)
        print(chunk[:200] + "..." if len(chunk) > 200 else chunk)  # Show first 200 chars
        print("-" * 40)

# =============================================
# Example Usage
# =============================================

# Create example files (in real usage, point to your actual files)
erlang_example = """
%% @doc Example Erlang module
-module(example).

%% @doc A simple function
-spec hello() -> ok.
hello() ->
    io:format("Hello, world!~n").

%% @doc Another function
-spec add(integer(), integer()) -> integer().
add(A, B) ->
    A + B.
"""

# Write example files to disk
Path("example.erl").write_text(erlang_example)

# Process the files
process_file("example.erl", "erlang")

# Clean up (optional)
Path("example.erl").unlink()
