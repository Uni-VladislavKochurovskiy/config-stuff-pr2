ODIN ?= odin
CONFIG ?= examples/config.csv
BINARY := bin/gravel

.PHONY: build run test check clean
build:
	mkdir -p bin
	$(ODIN) build src -out:$(BINARY)

run: build
	./$(BINARY) "$(CONFIG)"

test: build build-reverse
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

.PHONY: build-reverse reverse demo-reverse
build-reverse:
	mkdir -p bin
	$(ODIN) build src -define:REVERSE=true -out:bin/gravel-reverse

reverse: build-reverse
	./bin/gravel-reverse "$(CONFIG)"

demo-reverse: build-reverse
	bash tests/demo_reverse.sh

.PHONY: demo-packages
demo-packages: build
	bash tests/demo_packages.sh

.PHONY: compare
compare: build
	bash tests/compare.sh
