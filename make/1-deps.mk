.PHONY: deps deps-cpu deps-gpu remote-deps-cpu remote-deps-gpu

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

remote-deps-cpu:
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/1-deps/xb/install_all.sh"
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/1-deps/ligra/install.sh"

remote-deps-gpu:
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/1-deps/xb/install_all.sh"
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/1-deps/gunrock/install.sh"
