venv:
	rm -rf venv
	python -m venv venv

act:
	source venv/bin/activate

pip-deps: act
	pip install chromadb

deact:
	deactivate

all:
	@echo "Setting up local RAG analysis..."
