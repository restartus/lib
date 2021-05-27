#
##
## Docker command v2 uses docker-compose if docker_compose.yaml exists
## -------
# Remember makefile *must* use tabs instead of spaces so use this vim line
# requires include.mk
#
# The makefiles are self documenting, you use two leading for make help to produce output

# YOu will want to change these depending on the image and the org
repo ?= "richt"
name ?= "$$(basename $(PWD))"
SHELL := /usr/bin/env bash
DOCKER_COMPOSE_YML ?= docker-compose.yml
DOCKER_USER ?= docker
DEST_DIR ?= /home/$(DOCKER_USER)/data
# https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile
SRC_DIR ?= $(CURDIR)/data
# -v is deprecated
# volumes ?= -v "$$(readlink -f "./data"):$(DEST_DIR)"
volumes ?= --mount "type=bind,source=$(SRC_DIR),target=$(DEST_DIR)"
flags ?=

Dockerfile ?= Dockerfile
#
# Uses m4 for includes so Dockerfile.m4 are processed this way
# since docker does not support a macro language
# https://www3.physnet.uni-hamburg.de/physnet/Tru64-Unix/HTML/APS32DTE/M4XXXXXX.HTM
# Assumes GNU M4 is installed
# https://github.com/moby/moby/issues/735
# If you want preprocessing just create a Dockerfile.m4
Dockerfile.m4 ?= $(Dockerfile).m4
# http://www.scottmcpeak.com/autodepend/autodepend.html
# The leading dash means if the precendts don't exist then don't complain
## docker: pull docker image and builds locally along with tag with git sha
-$(Dockerfile): $(Dockerfile.m4)
	m4 <"$(Dockerfile.m4)" >"$(Dockerfile)"

image ?= $(repo)/$(name)
container := $(name)
build_path ?= .
MAIN ?= $(name).py
DOCKER_ENV ?= docker
CONDA_ENV ?= $(name)
# https://github.com/moby/moby/issues/7281

# pip packages that can also be installed by conda
PIP ?=
# pip packages that cannot be conda installed
PIP_ONLY ?=

docker_flags ?= --build-arg "DOCKER_USER=$(DOCKER_USER)" \
				--build-arg "DEST_DIR=$(DEST_DIR)" \
				--build-arg "NB_USER=$(DOCKER_USER)" \
				--build-arg "ENV=$(DOCKER_ENV)" \
				--build-arg "PYTHON=$(PYTHON)" \
				--build-arg "PIP=$(PIP)" \
				--build-arg "PIP_ONLY=$(PIP_ONLY)" \
# main.py includes streamlit code that only runs when streamlit invoked
# --restart=unless-stopped  not needed now


.PHONY: docker
docker: $(Dockerfile)
	if [[ -r  "$(DOCKER_COMPOSE_YML)" ]]; then \
		docker-compose -f $(DOCKER_COMPOSE_YML) build --pull \
					$(docker_flags); \
		docker-compose push; \
	else \
		docker build --pull \
					$(docker_flags) \
					 -f "$(Dockerfile)" \
					 -t "$(image)" \
					 $(build_path) ; \
		docker tag $(image) $(image):$$(git rev-parse HEAD) ; \
		docker push $(image) ;\
	fi

## docker-lint: run the linter against the docker file
.PHONY: docker-lint
docker-lint: $(Dockerfile)
	if [[ -r $((DOCKER_COMPOSE_YML)) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" config; \
	else \
		dockerfilelint $(Dockerfile); \
	fi

## docker-test: run tests for pip file
.PHONY: dockertest
docker-test:
	@echo PIP=$(PIP)
	@echo PIP_ONLY=$(PIP_ONLY)
	@echo PYTHON=$(PYTHON)

## push: after a build will push the image up
.PHONY: push
push:
	# need to push and pull to make sure the entire cluster has the right images
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compuse -f "$(DOCKER_COMPOSE_YML)" push; \
	else \
		docker push $(image); \
	fi

# for those times when we make a change in but the Dockerfile does not notice
# In the no cache case do not pull as this will give you stale layers
## no-cache: build docker image with no cache
.PHONY: no-cache
no-cache: $(Dockerfile)
	if [[ -e $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" build \
			$(docker_flags) \
			--build-arg NB_USER=$(DOCKER_USER); \
	else \
		docker build --pull --no-cache \
			$(docker_flags) \
			--build-arg NB_USER=$(DOCKER_USER) -f $(Dockerfile) -t $(image) $(build_path); \
		docker push $(image); \
	fi

# bash -c means the first argument is run and then the next are set as the $1,
# to it and not that you use awk with the \$ in double quotes
for_containers = bash -c 'for container in $$(docker ps -qa --filter name="$$0"); \
						  do \
						  	docker $$1 "$$container" $$2 $$3 $$4 $$5 $$6 $$7 $$8 $$9; \
						  done'

# we use https://stackoverflow.com/questions/12426659/how-to-extract-last-part-of-string-in-bash
# Because of quoting issues with awk
# bash -c uses $0 for the first argument
docker_run = bash -c ' \
	last=$$(docker ps --format "{{.Names}}" | rev | cut -d "-" -f 1 | sort -r | head -n1) ; \
	docker run $$0 \
		--name $(container)-$$((last+1)) \
		$(volumes) $(flags) $(image) $$@;\
	sleep 4; \
	docker logs $(container)-$$((last+1))'

## stop: halts all running containers (deprecated)
.PHONY: stop
stop:
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" down \
	; else \
		$(for_containers) $(container) stop > /dev/null && \
		$(for_containers) $(container) "rm -v" > /dev/null \
	; fi

## pull: pulls the latest image
.PHONY: pull
pull:
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" pull; \
	else \
		docker pull $(image); \
	fi

## run [args]: stops all the containers and then runs in the background
##             if there are flags than to a make -- run --flags [args]
# https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run
# Hack to allow parameters after run only works with GNU make
# Note no indents allowed for ifeq
# This commented out does not work if MAKECMDGOALS
# include real targets like 'run'
#ifeq (exec,$(firstword $(MAKECMDGOALS)))
## use the rest of the goals as arguments
#RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
## and create phantom targets for all those args
#$(eval $(RUN_ARGS):;@:)
#endif

# https://stackoverflow.com/questions/30137135/confused-about-docker-t-option-to-allocate-a-pseudo-tty
# docker run flags
# -i interactive connects the docker stdin to the terminal stdin
#    to exit the container send a CTRL-D to the stdin. This is used to run
#    and then exit like a shell command
# -t terminal means that the input is a terminal (and is useless without -i)
# -it this is almost always used together. commands like ls treat things
#     differently if they are not readl terminals so this works like a shell
# -dt runs but connects the stdin and stdout so logging works
#
# https://www.tecmint.com/run-docker-container-in-background-detached-mode/
# -d run in detached mode so it runs in the background and output goes
#    to the terminal if -t is set or it goes to the log otherwise
#  docker attach will reconnect it to the foreground.
# -rm remove the container when it exits


## run: Run the docker container in the background (for web apps like Jupyter)
.PHONY: run
run: stop
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" up --detached \
	; else \
		$(docker_run) -dt $(cmd) \
	; fi

## exec: Run docker in foreground and then exit (treat like any Unix command)
##       if you need to pass arguments down then use the form
# note no --re needed we automaticaly do this and need for logs
#
.PHONY: exec
exec: stop
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" up \
	; else \
		$(docker_run) -t $(cmd) \
	; fi

## shell: run the interactive shell in the container
# https://gist.github.com/mitchwongho/11266726
# Need entrypoint to make sure we get something interactive
.PHONY: shell
shell:
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose -f "$(DOCKER_COMPOSE_YML)" run "$(DOCKER_COMPOSE_MAIN)" /bin/bash; \
	else \
		docker pull $(image); \
		docker run -it \
			--entrypoint /bin/bash \
			--rm $(volumes) $(flags) $(image); \
	fi

## resume: keep running an existing container
.PHONY: resume
resume:
	if [[ -r $(DOCKER_COMPOSE_YML) ]]; then \
		docker-compose start; \
	else \
		docker start -ai $(container); \
	fi

# Note we say only the type file because otherwise it tries to delete $(docker_data) itself
## prune: Save some space on docker
.PHONY: prune
prune:
	docker system prune --volumes
