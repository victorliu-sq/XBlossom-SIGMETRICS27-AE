.PHONY: build build-cpu build-gpu

build: deps
	./scripts/3-build/build_all

build-cpu: deps-cpu
	./scripts/3-build/build_cpu

build-gpu: deps-gpu
	./scripts/3-build/build_gpu
