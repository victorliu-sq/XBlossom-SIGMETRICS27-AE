.PHONY: all
.DEFAULT_GOAL := all

include make/1-deps.mk
include make/2-datasets.mk
include make/3-build.mk
include make/4-expr-local.mk
include make/0-utils.mk
