.PHONY: deps deps-cpu deps-gpu

deps:
	./scripts/1-deps/xb/install_all.sh
	./scripts/1-deps/ligra/install.sh
	./scripts/1-deps/gunrock/install.sh

deps-cpu:
	./scripts/1-deps/xb/install_all.sh
	./scripts/1-deps/ligra/install.sh

deps-gpu:
	./scripts/1-deps/xb/install_all.sh
	./scripts/1-deps/gunrock/install.sh
