LAST_COMMIT_MSG := $(shell git log -1 --pretty=format:%B)

.PHONY: build deploy

build:
	jekyll build

deploy: build
	(cd _site && git add -A && git commit -m "$(LAST_COMMIT_MSG)" && git push)

