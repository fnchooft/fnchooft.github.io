import os
import subprocess
from typing import List, Dict, Any, Optional
from pathlib import Path
from llama_index.core import SimpleDirectoryReader, Document
from llama_index.core.readers.base import BaseReader
from llama_index.embeddings.ollama import OllamaEmbedding
from llama_index.core import Settings
import re

class GitRepositoryAnalyzer:
    """Analyzes git repositories and extracts metadata."""
    
    @staticmethod
    def find_git_repositories(data_dir: str) -> List[Dict[str, str]]:
        """Find all git repositories in the data directory."""
        repositories = []
        data_path = Path(data_dir)
        
        # Check if data_dir itself is a git repository
        if (data_path / '.git').exists():
            repo_info = GitRepositoryAnalyzer._get_repo_info(str(data_path))
            if repo_info:
                repositories.append(repo_info)
        
        # Look for git repositories in subdirectories
        for item in data_path.iterdir():
            if item.is_dir() and (item / '.git').exists():
                repo_info = GitRepositoryAnalyzer._get_repo_info(str(item))
                if repo_info:
                    repositories.append(repo_info)
        
        return repositories
    
    @staticmethod
    def _get_repo_info(repo_path: str) -> Optional[Dict[str, str]]:
        """Extract git repository information."""
        try:
            # Change to repository directory for git commands
            original_cwd = os.getcwd()
            os.chdir(repo_path)
            
            repo_info = {
                'repo_path': repo_path,
                'repo_name': os.path.basename(repo_path)
            }
            
            # Get current branch
            try:
                result = subprocess.run(['git', 'branch', '--show-current'], 
                                      capture_output=True, text=True, check=True)
                repo_info['current_branch'] = result.stdout.strip()
            except subprocess.CalledProcessError:
                repo_info['current_branch'] = 'unknown'
            
            # Get remote URL
            try:
                result = subprocess.run(['git', 'remote', 'get-url', 'origin'], 
                                      capture_output=True, text=True, check=True)
                repo_info['remote_url'] = result.stdout.strip()
            except subprocess.CalledProcessError:
                repo_info['remote_url'] = 'no-remote'
            
            # Get latest commit hash
            try:
                result = subprocess.run(['git', 'rev-parse', 'HEAD'], 
                                      capture_output=True, text=True, check=True)
                repo_info['commit_hash'] = result.stdout.strip()[:8]  # Short hash
            except subprocess.CalledProcessError:
                repo_info['commit_hash'] = 'unknown'
            
            # Get latest commit message
            try:
                result = subprocess.run(['git', 'log', '-1', '--pretty=format:%s'], 
                                      capture_output=True, text=True, check=True)
                repo_info['latest_commit_message'] = result.stdout.strip()
            except subprocess.CalledProcessError:
                repo_info['latest_commit_message'] = 'unknown'
            
            # Get repository status (clean/dirty)
            try:
                result = subprocess.run(['git', 'status', '--porcelain'], 
                                      capture_output=True, text=True, check=True)
                repo_info['repo_status'] = 'dirty' if result.stdout.strip() else 'clean'
                repo_info['modified_files_count'] = len(result.stdout.strip().split('\n')) if result.stdout.strip() else 0
            except subprocess.CalledProcessError:
                repo_info['repo_status'] = 'unknown'
                repo_info['modified_files_count'] = 0
            
            os.chdir(original_cwd)
            return repo_info
            
        except Exception as e:
            if 'original_cwd' in locals():
                os.chdir(original_cwd)
            print(f"Error getting git info for {repo_path}: {e}")
            return None
    
    @staticmethod
    def get_file_git_info(file_path: str, repo_info: Dict[str, str]) -> Dict[str, Any]:
        """Get git-specific information for a file."""
        git_metadata = {}
        
        try:
            # Get relative path from repository root
            repo_path = Path(repo_info['repo_path'])
            file_path_obj = Path(file_path)
            
            if repo_path in file_path_obj.parents or repo_path == file_path_obj.parent:
                relative_path = file_path_obj.relative_to(repo_path)
                git_metadata['relative_path'] = str(relative_path)
                
                # Change to repository directory for git commands
                original_cwd = os.getcwd()
                os.chdir(repo_path)
                
                # Get last modification info for this file
                try:
                    result = subprocess.run([
                        'git', 'log', '-1', '--pretty=format:%h|%an|%ad|%s', 
                        '--date=short', '--', str(relative_path)
                    ], capture_output=True, text=True, check=True)
                    
                    if result.stdout.strip():
                        parts = result.stdout.strip().split('|', 3)
                        if len(parts) >= 4:
                            git_metadata.update({
                                'last_commit_hash': parts[0],
                                'last_author': parts[1],
                                'last_modified_date': parts[2],
                                'last_commit_message': parts[3]
                            })
                except subprocess.CalledProcessError:
                    pass
                
                # Check if file is tracked by git
                try:
                    subprocess.run(['git', 'ls-files', '--error-unmatch', str(relative_path)], 
                                 capture_output=True, check=True)
                    git_metadata['git_tracked'] = True
                except subprocess.CalledProcessError:
                    git_metadata['git_tracked'] = False
                
                os.chdir(original_cwd)
                
        except Exception as e:
            if 'original_cwd' in locals():
                os.chdir(original_cwd)
            print(f"Error getting git info for file {file_path}: {e}")
        
        return git_metadata


class SourceCodeReader(BaseReader):
    """Custom reader for source code files with syntax-aware processing and git integration."""
    
    def __init__(self, file_type: str, repo_info: Optional[Dict[str, str]] = None):
        self.file_type = file_type
        self.repo_info = repo_info
        
    def load_data(self, file_path, extra_info: Dict[str, Any] = None) -> List[Document]:
        """Load and process source code files."""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []
        
        # Enhanced metadata for source code
        metadata = extra_info or {}
        metadata.update({
            'file_type': self.file_type,
            'file_path': str(file_path),
            'file_name': os.path.basename(file_path),
            'file_size': len(content),
            'language': self._detect_language(file_path),
            'lines_of_code': len([line for line in content.split('\n') if line.strip()]),
            'has_functions': self._has_functions(content, self.file_type),
            'has_classes': self._has_classes(content, self.file_type),
            'imports_modules': self._extract_imports(content, self.file_type)
        })
        
        # Add git repository information if available
        if self.repo_info:
            metadata.update({
                'repo_name': self.repo_info['repo_name'],
                'repo_path': self.repo_info['repo_path'],
                'current_branch': self.repo_info['current_branch'],
                'remote_url': self.repo_info['remote_url'],
                'commit_hash': self.repo_info['commit_hash'],
                'latest_commit_message': self.repo_info['latest_commit_message'],
                'repo_status': self.repo_info['repo_status'],
                'modified_files_count': self.repo_info['modified_files_count']
            })
            
            # Add file-specific git information
            file_git_info = GitRepositoryAnalyzer.get_file_git_info(file_path, self.repo_info)
            metadata.update(file_git_info)
        
        # Clean and prepare content for embedding
        processed_content = self._preprocess_code(content, self.file_type)
        
        return [Document(text=processed_content, metadata=metadata)]
    
    def _detect_language(self, file_path: str) -> str:
        """Detect programming language from file extension."""
        ext_to_lang = {
            '.c': 'c', '.h': 'c',
            '.py': 'python',
            '.erl': 'erlang', '.hrl': 'erlang',
            '.xml': 'xml',
            '.yang': 'yang',
            '.docbook': 'docbook'
        }
        ext = os.path.splitext(file_path)[1].lower()
        return ext_to_lang.get(ext, 'unknown')
    
    def _preprocess_code(self, content: str, file_type: str) -> str:
        """Preprocess code content for better embedding."""
        # Remove excessive whitespace while preserving structure
        lines = content.split('\n')
        processed_lines = []
        
        for line in lines:
            # Keep meaningful whitespace for indentation
            stripped = line.rstrip()
            if stripped:  # Skip empty lines
                processed_lines.append(stripped)
        
        # Add language identifier for better context
        lang_map = {
            '.c': 'C', '.h': 'C Header',
            '.py': 'Python',
            '.erl': 'Erlang', '.hrl': 'Erlang Header',
            '.xml': 'XML',
            '.yang': 'YANG',
            '.docbook': 'DocBook'
        }
        
        lang_name = lang_map.get(file_type, 'Source Code')
        processed_content = f"// {lang_name} File\n" + '\n'.join(processed_lines)
        
        return processed_content
    
    def _has_functions(self, content: str, file_type: str) -> bool:
        """Detect if file contains function definitions."""
        patterns = {
            '.c': r'\w+\s+\w+\s*\([^)]*\)\s*\{',
            '.py': r'def\s+\w+\s*\(',
            '.erl': r'^\w+\s*\([^)]*\)\s*->',
        }
        pattern = patterns.get(file_type)
        return bool(pattern and re.search(pattern, content, re.MULTILINE))
    
    def _has_classes(self, content: str, file_type: str) -> bool:
        """Detect if file contains class definitions."""
        patterns = {
            '.py': r'class\s+\w+\s*[\(:]',
            '.c': r'typedef\s+struct\s+\w*\s*\{',
        }
        pattern = patterns.get(file_type)
        return bool(pattern and re.search(pattern, content, re.MULTILINE))
    
    def _extract_imports(self, content: str, file_type: str) -> List[str]:
        """Extract import/include statements."""
        imports = []
        patterns = {
            '.c': r'#include\s*[<"]([^>"]+)[>"]',
            '.py': r'(?:from\s+(\S+)\s+)?import\s+([^\n]+)',
            '.erl': r'-include(?:_lib)?\s*\(\s*"([^"]+)"\s*\)',
        }
        
        pattern = patterns.get(file_type)
        if pattern:
            matches = re.findall(pattern, content)
            imports = [match if isinstance(match, str) else ''.join(match).strip() 
                      for match in matches]
        
        return imports[:10]  # Limit to first 10 imports


def setup_ollama_embeddings(model_name: str = "nomic-embed-text"):
    """Configure Ollama embeddings for source code analysis."""
    embed_model = OllamaEmbedding(
        model_name=model_name,
        base_url="http://localhost:11434",
        ollama_additional_kwargs={"mirostat": 0},
    )
    
    # Set global embedding model
    Settings.embed_model = embed_model
    return embed_model


def create_source_code_directory_reader(
    data_dir: str,
    ollama_model: str = "nomic-embed-text",
    recursive: bool = True,
    show_repo_summary: bool = True
) -> SimpleDirectoryReader:
    """
    Create a configured SimpleDirectoryReader for source code analysis from git repositories.
    
    Args:
        data_dir: Directory containing one or more git repositories
        ollama_model: Ollama embedding model name
        recursive: Whether to search subdirectories
        show_repo_summary: Whether to print repository summary
    
    Returns:
        Configured SimpleDirectoryReader instance
    """
    
    # Setup Ollama embeddings
    setup_ollama_embeddings(ollama_model)
    
    # Find all git repositories in the data directory
    repositories = GitRepositoryAnalyzer.find_git_repositories(data_dir)
    
    if show_repo_summary:
        print(f"\nFound {len(repositories)} git repositories in '{data_dir}':")
        for repo in repositories:
            print(f"  📁 {repo['repo_name']}")
            print(f"     Branch: {repo['current_branch']}")
            print(f"     Commit: {repo['commit_hash']} - {repo['latest_commit_message']}")
            print(f"     Status: {repo['repo_status']}")
            if repo['repo_status'] == 'dirty':
                print(f"     Modified files: {repo['modified_files_count']}")
            print(f"     Remote: {repo['remote_url']}")
            print()
    
    # Create a mapping of file paths to repository info
    path_to_repo = {}
    for repo in repositories:
        repo_path = Path(repo['repo_path'])
        # Map all paths under this repository to this repo info
        path_to_repo[str(repo_path)] = repo
    
    def create_reader_for_path(file_path: str, file_type: str) -> SourceCodeReader:
        """Create a SourceCodeReader with appropriate repository context."""
        # Find which repository this file belongs to
        file_path_obj = Path(file_path)
        repo_info = None
        
        for repo_path, repo_data in path_to_repo.items():
            repo_path_obj = Path(repo_path)
            if repo_path_obj in file_path_obj.parents or repo_path_obj == file_path_obj.parent:
                repo_info = repo_data
                break
        
        return SourceCodeReader(file_type, repo_info)
    
    # Define file extractors for different source code types
    # Note: We'll create them dynamically to include repository context
    file_extensions = ['.c', '.h', '.py', '.erl', '.hrl', '.xml', '.yang', '.docbook']
    
    # Custom file extractor that creates readers with repository context
    class RepositoryAwareExtractor:
        def __init__(self, file_extensions: List[str]):
            self.file_extensions = file_extensions
        
        def get_extractor_for_file(self, file_path: str) -> Optional[BaseReader]:
            ext = os.path.splitext(file_path)[1].lower()
            if ext in self.file_extensions:
                return create_reader_for_path(file_path, ext)
            return None
    
    # Since SimpleDirectoryReader expects a dict, we need to create individual extractors
    file_extractors = {}
    for ext in file_extensions:
        # Create a closure to capture the extension
        def make_extractor(extension):
            return lambda: create_reader_for_path("", extension)
        file_extractors[ext] = type('DynamicReader', (BaseReader,), {
            'load_data': lambda self, file_path, extra_info=None: 
                create_reader_for_path(file_path, os.path.splitext(file_path)[1].lower()).load_data(file_path, extra_info)
        })()
    
    # Create reader with custom extractors
    reader = SimpleDirectoryReader(
        input_dir=data_dir,
        file_extractor=file_extractors,
        recursive=recursive,
        exclude_hidden=True,
        required_exts=file_extensions  # Only process our target file types
    )
    
    return reader


# Example usage
def main():
    """Example of how to use the source code reader with git repositories and Ollama embeddings."""
    
    # Setup - assuming data directory contains one or more git repositories
    data_dir = "./data"  # Replace with your data directory containing git repos
    
    print("🔍 Analyzing git repositories and setting up source code reader...")
    
    reader = create_source_code_directory_reader(
        data_dir=data_dir,
        ollama_model="nomic-embed-text",  # or "all-MiniLM-L6-v2" or other models
        recursive=True,
        show_repo_summary=True
    )
    
    # Load documents
    print("📚 Loading source code files...")
    documents = reader.load_data()
    
    print(f"\n✅ Successfully loaded {len(documents)} documents")
    
    # Group documents by repository for analysis
    repo_docs = {}
    for doc in documents:
        repo_name = doc.metadata.get('repo_name', 'unknown')
        if repo_name not in repo_docs:
            repo_docs[repo_name] = []
        repo_docs[repo_name].append(doc)
    
    # Display repository-wise summary
    print(f"\n📊 Repository Summary:")
    for repo_name, docs in repo_docs.items():
        if repo_name != 'unknown':
            print(f"\n  🏛️  Repository: {repo_name}")
            print(f"      Files processed: {len(docs)}")
            
            # Get repository metadata from first document
            first_doc = docs[0]
            print(f"      Branch: {first_doc.metadata.get('current_branch', 'N/A')}")
            print(f"      Commit: {first_doc.metadata.get('commit_hash', 'N/A')}")
            print(f"      Status: {first_doc.metadata.get('repo_status', 'N/A')}")
            
            # Language breakdown
            languages = {}
            total_lines = 0
            for doc in docs:
                lang = doc.metadata.get('language', 'unknown')
                lines = doc.metadata.get('lines_of_code', 0)
                languages[lang] = languages.get(lang, 0) + 1
                total_lines += lines
            
            print(f"      Total lines of code: {total_lines:,}")
            print(f"      Languages: {dict(languages)}")
    
    # Display detailed metadata for a few sample files
    print(f"\n🔬 Sample File Analysis:")
    for i, doc in enumerate(documents[:3]):  # Show first 3 files
        print(f"\n  📄 Document {i+1}:")
        print(f"      File: {doc.metadata.get('file_name')}")
        print(f"      Repository: {doc.metadata.get('repo_name', 'N/A')}")
        print(f"      Branch: {doc.metadata.get('current_branch', 'N/A')}")
        print(f"      Language: {doc.metadata.get('language')}")
        print(f"      Lines of code: {doc.metadata.get('lines_of_code')}")
        print(f"      Has functions: {doc.metadata.get('has_functions')}")
        print(f"      Has classes: {doc.metadata.get('has_classes')}")
        print(f"      Git tracked: {doc.metadata.get('git_tracked', 'N/A')}")
        
        if doc.metadata.get('last_author'):
            print(f"      Last modified by: {doc.metadata.get('last_author')}")
            print(f"      Last modified: {doc.metadata.get('last_modified_date')}")
        
        imports = doc.metadata.get('imports_modules', [])
        if imports:
            print(f"      Key imports: {imports[:3]}")
        
        print(f"      Content preview: {doc.text[:150]}...")
    
    return documents


def analyze_repository_structure(data_dir: str):
    """Analyze and display the structure of git repositories in the data directory."""
    repositories = GitRepositoryAnalyzer.find_git_repositories(data_dir)
    
    print(f"🔍 Repository Analysis for '{data_dir}':")
    print(f"{'='*60}")
    
    if not repositories:
        print("❌ No git repositories found in the specified directory.")
        print("   Make sure your data directory contains git repositories.")
        return
    
    for i, repo in enumerate(repositories, 1):
        print(f"\n{i}. 📁 {repo['repo_name']}")
        print(f"   📍 Path: {repo['repo_path']}")
        print(f"   🌿 Current Branch: {repo['current_branch']}")
        print(f"   📝 Latest Commit: {repo['commit_hash']} - {repo['latest_commit_message']}")
        print(f"   🔄 Status: {repo['repo_status']}")
        if repo['repo_status'] == 'dirty':
            print(f"   ⚠️  Modified Files: {repo['modified_files_count']}")
        print(f"   🌐 Remote: {repo['remote_url']}")
        
        # Note about branch responsibility
        if repo['current_branch'] != 'main' and repo['current_branch'] != 'master':
            print(f"   ℹ️  Note: Currently on '{repo['current_branch']}' branch")
    
    print(f"\n{'='*60}")
    print("📋 Notes:")
    print("   • Users are responsible for checking out the correct branch")
    print("   • The analysis will use whatever branch is currently checked out")
    print("   • Make sure all repositories are on the desired branch before processing")


if __name__ == "__main__":
    # First, analyze the repository structure
    data_directory = "./data"  # Replace with your data directory
    
    print("Step 1: Repository Structure Analysis")
    analyze_repository_structure(data_directory)
    
    print(f"\n{'='*60}")
    print("Step 2: Source Code Processing")
    
    # Then run the main processing
    documents = main()
