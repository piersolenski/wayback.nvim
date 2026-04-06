.PHONY: all test fmt lint

all: lint test

test:
	./tests/run.sh

fmt:
	stylua .

lint:
	stylua --check .
