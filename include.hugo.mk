SHELL = bash

##
HUGO_REPO ?= richt
# kalkegg works
#repo ?= klakegg
HUGO_IMAGE ?= hugo
#ver ?= 0.74.3
#run ?= docker run --rm -it -v $$(pwd):/src
# https://github.com/jojomi/docker-hugo
# HUGO_WATCH means keep running
# without it, will just create the static files
HUGO_DOCKER ?= docker run --rm -v $$(pwd):/src
HUGO_VER ?= 0.81
HUGO_IMAGE ?= "$(HUGO_REPO)/$(HUGO_IMAGE):$(HUGO_VER)"
## export HUGO_FORCE=--force: to force hugo installation
HUGO_FORCE ?=
## export HUGO_PORT=1313: to change port
HUGO_PORT ?= 1313
## export HUGO_THEME_ORG=themefisher: to change theme github org
HUGO_THEME_ORG ?= themefisher
## export HUGO_THEME=parsa_hugo: to change theme
HUGO_THEME ?= parsa-hugo
# Note no https here but it is the path after that
HUGO_THEME_PATH ?= github.com/$(HUGO_THEME_ORG)/$(HUGO_THEME)

# this requires variables from include.mk to work like GIT_ORG and name
GIT_PATH ?= github.com/$(GIT_ORG)/$(name)

## export HUGO_ENV=docker: to run in docker
## unset HUGO_ENV: to run bare metal
HUGO_ENV ?= 
ifeq ($(HUGO_ENV),docker)
	HUGO_RUN = $(HUGO_DOCKER) $(HUGO_IMAGE)
else
	HUGO_RUN = hugo
endif

## 


## hugo: make the site
.PHONY: hugo
hugo:
	$(HUGO_RUN)

## hugo-server: run the site
# Use this line for kalkegg
#$(run) -p $(HUGO_PORT):$(HUGO_PORT) "$(HUGO_IMAGE)" server
.PHONY: hugo-server
hugo-server:
ifeq ($(HUGO_ENV),docker)
	$(HUGO_DOCKER) -e HUGO_WATCH=1 -it -p $(HUGO_PORT):$(HUGO_PORT) "$(HUGO_IMAGE)"
else
	hugo server
endif

## hugo-new: create a new site
.PHONY: hugo-new
hugo-new:
ifneq ($(HUGO_FORCE),)
	@echo even with $(HUGO_FORCE) need to remove some files
	rm -rf layouts content archetypes themes static data config.toml
endif
	$(run) $(HUGO_IMAGE) hugo new site . $(HUGO_FORCE)

# https://www.hugofordevelopers.com/articles/master-hugo-modules-managing-themes-as-modules/
# https://discourse.gohugo.io/t/hugo-modules-for-dummies/20758
# by convention we turn the entire repo into a module
## hugo-theme: Get a HUGO_THEME as module
.PHONY: hugo-theme
hugo-theme:
	if ! grep -q "$(GIT_PATH)" go.mod; then \
		$(HUGO_RUN) mod init "$(GIT_PATH)"; \
	fi
	if ! grep -q "$(HUGO_THEME_PATH)" config.toml; then \
		echo "[[module.imports]]" >> config.toml; \
		echo "path = \"$(HUGO_THEME_PATH)\"" >> config.toml; \
	fi
	cp $(GIT_PATH)/ExampleSite

## hugo-mod: get latest go modules and add to repo
.PHONY: hugo-mod
hugo-mod:
	$(HUGO_RUN) mod get -u ./...
	$(HUGO_RUN) mod vendor

## hugo-theme-sm: add a submodule theme (deprecated)
.PHONY: hugo-theme-sm
hugo-theme-sm:
	git submodule add "https://github.com/$(HUGO_THEME_ORG)/$(HUGO_THEME)" "themes/$(HUGO_THEME)" || true
	grep "$(HUGO_THEME)" config.toml || echo "HUGO_THEME = \"$(HUGO_THEME)\"" >> config.toml

## hugo-post: New blog post
.PHONY: hugo-post
hugo-post:
	$(HUGO_RUN) new posts/$

## netlify: initialize netlify cli and link it to current repo
# https://cli.netlify.com/getting-started
.PHONY: netlify
netlify:
	netlify logout
	netlify login
	if [[ -d .netlify ]]; then netlify link; else netlify init; fi
	netlify env:set GIT_LFS_ENABLED true

	netlify open
