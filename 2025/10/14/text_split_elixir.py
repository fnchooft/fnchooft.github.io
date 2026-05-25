from langchain_text_splitters import RecursiveCharacterTextSplitter
import textwrap

def test_elixir_splitting():
    # Sample Elixir code with various constructs
    elixir_code = textwrap.dedent("""
    defmodule Math do
      @moduledoc \"\"\"
      A module for basic math operations.
      \"\"\"
      
      @doc \"\"\"
      Adds two numbers.
      
      ## Examples
      
          iex> Math.add(2, 3)
          5
      \"\"\"
      def add(a, b) do
        a + b
      end
      
      @doc \"\"\"
      Multiplies two numbers.
      \"\"\"
      def multiply(a, b) do
        a * b
      end
      
      # Private helper function
      defp validate_number(num) when is_number(num), do: true
      defp validate_number(_), do: false
    end
    """).strip()

    # Monkey patch the get_separators_for_language method
    original_get_separators = RecursiveCharacterTextSplitter.get_separators_for_language

    print(f"\nKnown extensions/languages: {original_get_separators}")


    # Create the text splitter with default settings
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=200,  # Small chunks for testing
        chunk_overlap=20,
        separators=["\n\n", "\n", " ", ""]  # Default separators
    )

    # Split the Elixir code
    chunks = splitter.split_text(elixir_code)

    # Display results
    print("="*50)
    print("ELIXIR CODE SPLITTING TEST")
    print("="*50)
    print(f"\nOriginal code length: {len(elixir_code)} characters")
    print(f"Number of chunks: {len(chunks)}\n")

    for i, chunk in enumerate(chunks, 1):
        print(f"\nCHUNK {i} (Length: {len(chunk)})")
        print("-"*40)
        print(chunk)
        print("-"*40)

if __name__ == "__main__":
    test_elixir_splitting() 