#
##

# more than 1M pulls so use this
HUGO_REPO ?= jojomi
# kalkegg works
#repo ?= klakegg
HUGO_NAME ?= hugo
#ver ?= 0.74.3
#run ?= docker run --rm -it -v $$(pwd):/src
# https://github.com/jojomi/docker-hugo
# HUGO_WATCH means keep runnig
# without it, will just create the static files
run ?= docker run --rm -v $$(pwd):/src -e HUGO_WATCH=1
HUGO_VER ?= 0.76
HUGO_IMAGE ?= "$(HUGO_REPO)/$(HUGO_NAME):$(HUGO_VER)"
port ?= 1313
theme_org ?= budparr
theme ?= gohugo-theme-ananke


## hugo: make the the site
.PHONY: hugo
hugo:
	$(run)

## hugo-server: run the site
# Use this line for kalkegg
#$(run) -p $(port):$(port) "$(HUGO_IMAGE)" server
.PHONY: hugo-server
hugo-server:
	$(run) -p $(port):$(port) "$(HUGO_IMAGE)"

## hugo-new: create a new site
.PHONY: hugo-new
hugo-new:
	$(run) $(HUGO_IMAGE) new site .

## hugo-theme: add a theme
.PHONY: hugo-theme
hugo-theme:
	git submodule add "https://github.com/$(theme_org)/$(theme)" "themes/$(theme)" || true
	grep "$(theme)" config.toml || echo "theme = \"$(theme)\"" >> config.toml

## hugo-post: New blog post
.PHONY: hugo-post
hugo-post:
	$(run) $(image) new posts/$

## netlify: initialize netlify cli and link it to current repo
# https://cli.netlify.com/getting-started
.PHONY: netlify
netlify:
	netlify link
	netlify env:set GIT_LFS_ENABLED true
