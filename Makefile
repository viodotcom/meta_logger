.DEFAULT_GOAL := help

VERSION_FILE := mix.exs
VERSION := $(shell sed -En "s/^.*@version \"([0-9]*\\.[0-9]*\\.[0-9]*)\"*/\\1/p" ${VERSION_FILE})

BLUE_COLOR := \033[0;34m
DEFAULT_COLOR := \033[0;39m
DIM_COLOR := \033[0;2m
YELLOW_COLOR := \033[0;33m

.PHONY: build
build: ## Compile the project
	@mix compile

.PHONY: cleanup
cleanup: ## Removes all the dependencies and build artifacts
	@mix deps.clean --all --build && mix clean --build

.PHONY: credo
credo: ## Check style guide
	@mix credo --strict

.PHONY: dialyzer
dialyzer: ## Check types
	@mix dialyzer --halt-exit-status

.PHONY: format
format: ## Check code format
	@mix format --check-formatted

.PHONY: full-test
full-test: format credo dialyzer test ## Perform code format, style guide check, type checking and test

.PHONY: help
help: ## Print this help
	@printf "MetaLogger ${VERSION}\n"
	@awk -F ':|##' '/^[^\t].+?:.*?##/ { printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF }' $(MAKEFILE_LIST)

.PHONY: install
install: ## Install dependencies
	@mix local.hex --force && \
		mix local.rebar --force && \
		mix deps.get

.PHONY: publish
publish: ## Publishes to Hex
	@mix hex.publish

MAJOR := $(shell echo "${VERSION}" | cut -d . -f1)
MINOR := $(shell echo "${VERSION}" | cut -d . -f2)
PATCH := $(shell echo "${VERSION}" | cut -d . -f3)
README_FILE := README.md
CHANGELOG_FILE := CHANGELOG.md
DATE := $(shell date +"%Y-%m-%d")
REPO_NAME := meta_logger
REPO := https:\/\/github.com\/FindHotel\/${REPO_NAME}\/compare

.PHONY: release
release: ## Bumps the version and creates the new tag
	@printf e "${BLUE_COLOR}The current version is:${DEFAULT_COLOR} ${VERSION}" && \
	  read -r -p "Do you want to release a [major|minor|patch]: " TYPE && \
	  case "$$TYPE" in \
	  "major") \
	    MAJOR=$$((${MAJOR}+1)); \
	    MINOR="0"; \
	    PATCH="0"; \
	    NEW_VERSION="$$MAJOR.$$MINOR.$$PATCH" \
	    ;; \
	  "minor") \
	    MINOR=$$((${MINOR}+1)); \
	    PATCH="0" && \
	    NEW_VERSION="${MAJOR}.$$MINOR.$$PATCH" \
	    ;; \
	  "patch") \
	    PATCH=$$((${PATCH}+1)); \
	    NEW_VERSION="${MAJOR}.${MINOR}.$$PATCH" \
	    ;; \
	  *) \
	    printf "\\n${YELLOW_COLOR}Release canceled!\n"; \
	    exit 0 \
	    ;; \
	  esac && \
	  printf "${BLUE_COLOR}The new version is:${DEFAULT_COLOR} $$NEW_VERSION\n" && \
	  printf "\t${DIM_COLOR}Updating ${VERSION_FILE} version${DEFAULT_COLOR}\n" && \
	  perl -p -i -e "s/@version \"${VERSION}\"/@version \"$$NEW_VERSION\"/g" ${VERSION_FILE} && \
	  printf "\t${DIM_COLOR}Updating ${README_FILE} version${DEFAULT_COLOR}\n" && \
	  perl -p -i -e "s/:meta_logger, \"~> ${VERSION}\"/:meta_logger, \"~> $$NEW_VERSION\"/g" ${README_FILE} && \
	  printf "\t${DIM_COLOR}Updating ${CHANGELOG_FILE} version${DEFAULT_COLOR}\n" && \
	  perl -p -i -e "s/## \[Unreleased\]/## \[Unreleased\]\\n\\n## \[$$NEW_VERSION\] - ${DATE}/g" ${CHANGELOG_FILE} && \
	  perl -p -i -e "s/${REPO}\/${VERSION}...HEAD/${REPO}\/$$NEW_VERSION...HEAD/g" ${CHANGELOG_FILE} && \
	  perl -p -i -e "s/...HEAD/...HEAD\\n\[$$NEW_VERSION\]: ${REPO}\/${VERSION}...$$NEW_VERSION/g" ${CHANGELOG_FILE} && \
	  printf "\t${DIM_COLOR}Recording changes to the repository${DEFAULT_COLOR}\n" && \
	  git add ${VERSION_FILE} ${README_FILE} ${CHANGELOG_FILE} && \
	  git commit -m "Bump to $$NEW_VERSION" > /dev/null && \
	  printf "\t${DIM_COLOR}Creating release tag${DEFAULT_COLOR}\n" && \
	  git tag -a -m "" $$NEW_VERSION && \
	  printf "\n${BLUE_COLOR}If everything's ok, push the changes to updstream!${DEFAULT_COLOR}\n"

.PHONY: test
test: ## Run tests
	mix test --cover
