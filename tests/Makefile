.DEFAULT_GOAL := help

.PHONY: help
help:  ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort -k 1,1 | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## build webui container
	@docker-compose build --pull

.PHONY: start
start: ## start webui container
	@docker-compose up -d --build

.PHONY: test
test: ## test the project
	@docker-compose run --rm webui sh -c "black --check . && flake8 && pytest ./tests.py -vv"

.PHONY: shell
shell: ## start bash in the webui container
	@docker-compose run --rm webui bash

.PHONY: release-notes
release-notes: ## generate release notes
	@semantic-release version --noop -D version_source=tag
	@semantic-release changelog --noop --unreleased -D version_source=tag

.PHONY: dummy-video
dummy-video: ## generate dummy video file
	@ffmpeg -f lavfi -i color=color=black -f lavfi -i anullsrc=cl=mono:r=48000 -i ./environment/test_media/metadata -t 10 ./environment/test_media/dummy.mp4
