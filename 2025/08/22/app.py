import os
import chromadb
from chromadb.config import Settings
from langchain_community.document_loaders import (
    DirectoryLoader,
    TextLoader,
    UnstructuredFileLoader,
    GitLoader
)
from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    Language
)
from langchain_ollama import OllamaLLM, OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.chains import RetrievalQA
from langchain.schema import Document
import requests
import json

class SourceCodeAnalyzer:
    def __init__(self, 
                 ollama_model="llama3.1",
                 embedding_model="nomic-embed-text",
                 collection_name="source_code"):
        """
        Initialize the source code analyzer with Ollama and ChromaDB
        
        Args:
            ollama_model: Model to use for analysis (e.g., 'llama3.1', 'codellama')
            embedding_model: Model for embeddings (e.g., 'nomic-embed-text')
            collection_name: Name for the ChromaDB collection
        """
        self.ollama_model = ollama_model
        self.embedding_model = embedding_model
        self.collection_name = collection_name
        
        # Initialize Ollama
        self.llm = OllamaLLM(model=self.ollama_model)
        self.embeddings = OllamaEmbeddings(model=self.embedding_model)
        
        # Initialize ChromaDB
        self.chroma_client = chromadb.PersistentClient(path="./chroma_db")
        
        # Initialize vector store
        self.vectorstore = None
        
    def load_source_code(self, source_path, file_types=None):
        """
        Load source code from various sources using OpenAI's document loaders
        
        Args:
            source_path: Path to directory, file, or git repository
            file_types: List of file extensions to include (e.g., ['.py', '.js', '.java'])
        """
        documents = []
        
        if file_types is None:
            file_types = ['.py', '.js', '.ts', '.java', '.cpp', '.c', '.h', 
                         '.cs', '.rb', '.go', '.rs', '.php', '.swift', '.kt']
        
        try:
            # Check if it's a git repository
            if os.path.exists(os.path.join(source_path, '.git')):
                print("Loading from Git repository...")
                loader = GitLoader(
                    clone_url=source_path if source_path.startswith('http') else None,
                    repo_path=source_path if not source_path.startswith('http') else None,
                    branch="master"
                )
                documents.extend(loader.load())
            
            # Load from directory
            elif os.path.isdir(source_path):
                print("Loading from directory...")
                for ext in file_types:
                    loader = DirectoryLoader(
                        source_path,
                        glob=f"**/*{ext}",
                        loader_cls=TextLoader,
                        loader_kwargs={'encoding': 'utf-8', 'autodetect_encoding': True}
                    )
                    try:
                        docs = loader.load()
                        documents.extend(docs)
                    except Exception as e:
                        print(f"Warning: Could not load files with extension {ext}: {e}")
            
            # Load single file
            elif os.path.isfile(source_path):
                print("Loading single file...")
                loader = TextLoader(source_path, encoding='utf-8', autodetect_encoding=True)
                documents.extend(loader.load())
            
            else:
                raise ValueError(f"Invalid source path: {source_path}")
                
        except Exception as e:
            print(f"Error loading documents: {e}")
            return []
        
        print(f"Loaded {len(documents)} documents")
        return documents
    
    def split_code_documents(self, documents):
        """
        Split code documents using language-aware text splitters
        """
        split_docs = []
        
        # Language mapping for different file types
        language_map = {
            '.py': Language.PYTHON,
            '.js': Language.JS,
            '.ts': Language.TS,
            '.java': Language.JAVA,
            '.cpp': Language.CPP,
            '.c': Language.C,
            '.cs': Language.CSHARP,
            '.rb': Language.RUBY,
            '.go': Language.GO,
            '.rs': Language.RUST,
            '.php': Language.PHP,
            '.swift': Language.SWIFT,
            '.kt': Language.KOTLIN
        }
        
        for doc in documents:
            file_ext = None
            if hasattr(doc, 'metadata') and 'source' in doc.metadata:
                file_ext = os.path.splitext(doc.metadata['source'])[1]
            
            # Use language-specific splitter if available
            if file_ext in language_map:
                splitter = RecursiveCharacterTextSplitter.from_language(
                    language=language_map[file_ext],
                    chunk_size=1000,
                    chunk_overlap=200
                )
            else:
                # Default splitter
                splitter = RecursiveCharacterTextSplitter(
                    chunk_size=1000,
                    chunk_overlap=200,
                    separators=["\n\n", "\n", " ", ""]
                )
            
            splits = splitter.split_documents([doc])
            split_docs.extend(splits)
        
        print(f"Split into {len(split_docs)} chunks")
        return split_docs
    
    def create_vector_store(self, documents):
        """
        Create ChromaDB vector store from documents
        """
        print("Creating embeddings and storing in ChromaDB...")
        
        # Split documents
        split_docs = self.split_code_documents(documents)
        
        # Create vector store
        self.vectorstore = Chroma.from_documents(
            documents=split_docs,
            embedding=self.embeddings,
            collection_name=self.collection_name,
            persist_directory="./chroma_db"
        )
        
        print(f"Created vector store with {len(split_docs)} document chunks")
        return self.vectorstore
    
    def load_existing_vectorstore(self):
        """
        Load existing ChromaDB vector store
        """
        try:
            self.vectorstore = Chroma(
                collection_name=self.collection_name,
                embedding_function=self.embeddings,
                persist_directory="./chroma_db"
            )
            print("Loaded existing vector store")
            return self.vectorstore
        except Exception as e:
            print(f"Could not load existing vector store: {e}")
            return None
    
    def setup_retrieval_qa(self, k=5):
        """
        Setup retrieval QA chain with Ollama
        """
        if not self.vectorstore:
            raise ValueError("Vector store not initialized. Call create_vector_store() first.")
        
        retriever = self.vectorstore.as_retriever(search_kwargs={"k": k})
        
        self.qa_chain = RetrievalQA.from_chain_type(
            llm=self.llm,
            chain_type="stuff",
            retriever=retriever,
            return_source_documents=True
        )
        
        return self.qa_chain
    
    def analyze_code(self, query, include_sources=True):
        """
        Analyze source code using the query
        """
        if not hasattr(self, 'qa_chain'):
            self.setup_retrieval_qa()
        
        result = self.qa_chain.invoke({"query": query})
        
        response = {
            "answer": result["result"],
            "sources": []
        }
        
        if include_sources and "source_documents" in result:
            for doc in result["source_documents"]:
                source_info = {
                    "content": doc.page_content[:200] + "..." if len(doc.page_content) > 200 else doc.page_content,
                    "metadata": doc.metadata
                }
                response["sources"].append(source_info)
        
        return response
    
    def get_code_statistics(self):
        """
        Get statistics about the loaded codebase
        """
        if not self.vectorstore:
            return "No vector store loaded"
        
        stats_query = """
        Analyze the codebase and provide statistics including:
        1. Programming languages used
        2. Total number of files
        3. Main modules/components
        4. Code complexity overview
        5. Architecture patterns identified
        """
        
        return self.analyze_code(stats_query)

# Example usage
def main():
    # Initialize analyzer
    analyzer = SourceCodeAnalyzer(
        ollama_model="llama3.1",  # or "codellama" for better code understanding
        embedding_model="nomic-embed-text"
    )
    
    # Load source code from directory
    source_path = "./data/erlangprogramming"  # Replace with your path
    documents = analyzer.load_source_code(source_path)
    
    if documents:
        # Create vector store
        analyzer.create_vector_store(documents)
        
        # Setup QA chain
        analyzer.setup_retrieval_qa()
        
        # Example queries
        queries = [
            "What is the main architecture of this codebase?",
            "Find all functions that handle user authentication",
            "What are the main security vulnerabilities in this code?",
            "Explain the database interaction patterns used",
            "What design patterns are implemented in this codebase?",
            "Find all TODO comments and technical debt",
            "Analyze the error handling mechanisms",
            "What are the main API endpoints defined?"
        ]
        
        print("\n" + "="*50)
        print("SOURCE CODE ANALYSIS RESULTS")
        print("="*50)
        
        for query in queries:
            print(f"\n🔍 Query: {query}")
            print("-" * 40)
            
            result = analyzer.analyze_code(query)
            print(f"📝 Answer: {result['answer']}")
            
            if result['sources']:
                print(f"\n📚 Sources ({len(result['sources'])} files):")
                for i, source in enumerate(result['sources'][:2]):  # Show first 2 sources
                    print(f"  {i+1}. {source['metadata'].get('source', 'Unknown')}")
            
            print("\n" + "="*50)

# Advanced analysis functions
def analyze_specific_patterns(analyzer):
    """
    Analyze specific code patterns
    """
    patterns = {
        "Security Issues": "Find potential security vulnerabilities like SQL injection, XSS, or insecure authentication",
        "Performance Issues": "Identify performance bottlenecks, inefficient algorithms, or resource-heavy operations",
        "Code Smells": "Find code smells like long methods, duplicate code, or violation of SOLID principles",
        "Dependencies": "List all external dependencies and their usage patterns",
        "Testing Coverage": "Analyze test coverage and identify untested critical functions"
    }
    
    results = {}
    for pattern_name, query in patterns.items():
        print(f"\nAnalyzing: {pattern_name}")
        result = analyzer.analyze_code(query)
        results[pattern_name] = result
    
    return results

def compare_code_versions(analyzer1, analyzer2, comparison_queries):
    """
    Compare two versions of codebase
    """
    comparisons = {}
    
    for query in comparison_queries:
        result1 = analyzer1.analyze_code(query)
        result2 = analyzer2.analyze_code(query)
        
        comparisons[query] = {
            "version1": result1,
            "version2": result2
        }
    
    return comparisons

if __name__ == "__main__":
    main()
