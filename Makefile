# Project configuration
PROJECT_NAME = web_crawler
BUILD_DIR = _build
SRC_DIR = src
TEST_DIR = test

# OCaml/OPAM commands
OPAM = opam
DUNE = dune
OCAMLFORMAT = ocamlformat

# Default target
.PHONY: all
all: build

# Build the project
.PHONY: build
build:
	@echo "Building project..."
	$(DUNE) build @all

# Run the executable
.PHONY: run
run: build
	@echo "Running web crawler..."
	$(DUNE) exec $(PROJECT_NAME)

# Run tests
.PHONY: test
test:
	@echo "Running tests..."
	$(DUNE) runtest --force

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	$(DUNE) clean
	rm -rf $(BUILD_DIR)

# Deep clean (including opam switch)
.PHONY: distclean
distclean: clean
	@echo "Performing deep clean..."
	rm -rf _opam
	rm -f *.install

# Format code
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	$(DUNE) build @fmt --auto-promote


# Development setup target
.PHONY: setup
setup:
	$(OPAM) switch create . ocaml-base-compiler.5.1.0
	eval $($(OPAM) env)
	$(OPAM) install . --deps-only


.DEFAULT_GOAL := all