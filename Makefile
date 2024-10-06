MKFILE_DIR := $(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

.PHONY: fixcommit
fixcommit:
	pre-commit run --all-files

.PHONY: diagram
diagram:
	python3 diagram.py
