.PHONY: build build-cpu build-gpu remote-build remote-build-cpu remote-build-gpu

build: deps
	./scripts/3-build/build_all

build-cpu: deps-cpu
	./scripts/3-build/build_cpu

build-gpu: deps-gpu
	./scripts/3-build/build_gpu

remote-build:
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/3-build/build_all"

remote-build-cpu:
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/3-build/build_cpu"

remote-build-gpu:
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/3-build/build_gpu"
