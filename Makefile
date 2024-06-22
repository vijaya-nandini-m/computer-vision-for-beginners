# reproducible project python environment
#
.ONESHELL: # use same shell as make when invoking shell commands

# define which python executable should be used to create the project environment
PYTHON ?= /opt/python/3.8/bin/python
# project name uses current project directory (this is the github repo name)
PROJECT ?= $(shell basename $(CURDIR))

# check that python executable works
PYTHON_VERSION := $(shell $(PYTHON) --version 2> /dev/null)
ifndef PYTHON_VERSION
$(error failed to find python executable as $(PYTHON) - set PYTHON env var to full path of python binary)
endif

venv: .venv/touchfile

.venv/touchfile: requirements.txt
	$(info [+] using $(PYTHON_VERSION))
	$(info [+] creating venv for $(PROJECT)...)
	test -d .venv || $(PYTHON) -m venv --prompt $(PROJECT) .venv
	. .venv/bin/activate
	$(info [+] installing pip and ipykernel...)
	pip install -U pip
	pip install ipykernel pipdeptree
	python -m ipykernel install --user --name=$(PROJECT)
	$(info [+] installing requirements...)
	pip install -Ur requirements.txt
	touch .venv/touchfile

build: venv ## build virtual environment and git config
	. .venv/bin/activate

freeze: venv ## takes snapshot of current python dependency versions and saves into requirements.txt, use pipdeptree to preserve top level dependencies
	. .venv/bin/activate
	pipdeptree -f --warn silence | grep -E '^[a-zA-Z0-9\-]+' > requirements.txt

clean: ## clean up virtual environment and Jupyter kernel
	. .venv/bin/activate
	jupyter kernelspec remove -f $(PROJECT)
	rm -rf .venv
	find -iname "*.pyc" -delete

list: ## list available Jupyter kernels
	. .venv/bin/activate
	jupyter kernelspec list

help: ## this help
	@ echo "REPRODUCIBLE PYTHON PROJECT ENVIRONMENT BUILD"
	@ echo ""
	@ echo "set PYTHON env var to full path for target python version project environment"
	@ echo ""
	@ echo "available targets:"
	@ echo ""
	@ awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_\-%]+:.*?## / {printf "\033[36m%-30s\033[0m \n > %s\n\n", $$1, $$2}' $(MAKEFILE_LIST)

setup-git: ## set up project specific git hooks
	chmod +x .git/hooks/pre-commit.sample | git config core.hooksPath .githooks

.DEFAULT_GOAL := help
