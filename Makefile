ODIN ?= odin
CONFIG ?= examples/config.csv
BINARY := bin/gravel

.PHONY: build run test check clean
build:
	mkdir -p bin
	$(ODIN) build src -out:$(BINARY)

run: build
	./$(BINARY) "$(CONFIG)"

test: build
	$(ODIN) test tests -out:bin/tests
	bash tests/cli.sh

check:
	$(ODIN) check src

clean:
	rm -rf bin

.PHONY: demo-errors
demo-errors: build
	bash tests/demo_errors.sh

.PHONY: demo-graphs
demo-graphs: build
	bash tests/demo_graphs.sh
