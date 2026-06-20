.PHONY: clean clean_build clean_deps clean_all
.PHONY: prepare_logs

clean_build:
	rm -rf build

clean_deps:
	rm -rf deps/xb deps/ligra deps/gunrock

clean: clean_build clean_deps

clean_all: clean

prepare_logs:
	mkdir -p tmp/logs results
