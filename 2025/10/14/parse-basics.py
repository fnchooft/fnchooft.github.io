
from langchain_community.document_loaders.parsers.language.tree_sitter_segmenter import TreeSitterSegmenter
from tree_sitter_languages_pack import get_language, get_parser

from typing import List, Dict, Any
import os

def parse_erlang_file(file_path: str) -> List[str]:
    """
    Basic example: Parse a Python file and return all segments
    
    Args:
        file_path (str): Path to the Python file
        
    Returns:
        List[str]: List of code segments
    """
    # Read the Python file
    with open(file_path, 'r', encoding='utf-8') as file:
        python_code = file.read()
    
    # Initialize TreeSitterSegmenter for Python
    segmenter = TreeSitterSegmenter(
        language=get_language("erlang"),
        chunk_lines=50,  # Maximum lines per chunk
        chunk_lines_overlap=5,  # Overlap between chunks
    )
    
    # Parse and segment the code
    segments = segmenter.split_text(python_code)
    
    return segments



if __name__ == "__main__":
    parse_erlang_file("hello_world.erl")