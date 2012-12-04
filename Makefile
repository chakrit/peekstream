
BIN = ./node_modules/.bin

TEST_OPTS = --timeout 100 --reporter list --globals __coverage__ --compilers coffee:coffee-script
COFFEE_OPTS = --bare --compile
ISTANBUL_OPTS = instrument --variable global.__coverage__ --no-compact

SRC_FILES := $(wildcard src/*.coffee)
LIB_FILES := $(SRC_FILES:src/%.coffee=lib/%.js)
TEST_FILES = test/*.coffee
COV_FILES := $(LIB_FILES:lib/%.js=lib-cov/%.js)


default: test

lib/%.js: src/%.coffee
	$(BIN)/coffee $(COFFEE_OPTS) --output $(@D) $<

lib-cov/%.js: lib/%.js
	mkdir -p ./lib-cov
	$(BIN)/istanbul $(ISTANBUL_OPTS) --output $@ $<


all: $(LIB_FILES)

publish: clean all
	npm publish

test:
	$(BIN)/mocha $(TEST_OPTS) $(TEST_FILES)
tdd:
	$(BIN)/mocha $(TEST_OPTS) --watch $(TEST_FILES)

instrument: $(COV_FILES)
cover: instrument
	COVER=1 $(BIN)/mocha $(TEST_OPTS) --reporter mocha-istanbul $(TEST_FILES)
	@echo open html-report/index.html to view coverage report.


clean:
	rm -Rf html-report
	rm -Rf coverage
	rm -Rf lib-cov
	rm -Rf lib

.PHONY: instrument all default test watch cover clean lib-cov

