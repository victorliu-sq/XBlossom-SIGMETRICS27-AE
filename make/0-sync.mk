.PHONY: clean clean_build clean_deps clean_all
.PHONY: update prepare_logs remote-update remote-upate

clean_build:
	rm -rf build

clean_deps:
	rm -rf deps/xb deps/ligra deps/gunrock

clean: clean_build clean_deps

clean_all: clean

update:
	git pull --recurse-submodules
	git submodule update --init --recursive --remote

prepare_logs:
	mkdir -p tmp/logs results

remote-update:
	./scripts/0-sync/update_main_and_sub.sh

remote-upate: remote-update
