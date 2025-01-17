ROOT_PROJECT_NAME := "hcc"
PROJECT_NAME := "tuba"
PKG_LIST := $(shell go list ${ROOT_PROJECT_NAME}/${PROJECT_NAME}/...)

.PHONY: all build clean gofmt goreport goreport_deb test coverage coverhtml lint

all: build

copy_dir: ## Copy project folder to GOPATH
	@mkdir -p $(GOPATH)/src/${ROOT_PROJECT_NAME}
	@rm -rf $(GOPATH)/src/${ROOT_PROJECT_NAME}/${PROJECT_NAME}
	@cp -Rp `pwd` $(GOPATH)/src/${ROOT_PROJECT_NAME}/${PROJECT_NAME}

lint_dep: ## Get the dependencies for golint
	@$(GOROOT)/bin/go get -u golang.org/x/lint/golint

lint: ## Lint the files
	@$(GOPATH)/bin/golint -set_exit_status ${PKG_LIST}

test: ## Run unittests
	@sudo -E $(GOROOT)/bin/go test -v ${PKG_LIST}

race: ## Run data race detector
	@sudo -E $(GOROOT)/bin/go test -race -v ${PKG_LIST}

coverage: ## Generate global code coverage report
	@sudo -E $(GOROOT)/bin/go test -v -coverprofile=coverage.out ${PKG_LIST}
	@$(GOROOT)/bin/go tool cover -func=coverage.out

coverhtml: coverage ## Generate global code coverage report in HTML
	@$(GOROOT)/bin/go tool cover -html=coverage.out

gofmt: ## Run gofmt for go files
	@find -name '*.go' -exec $(GOROOT)/bin/gofmt -s -w {} \;

goreport_dep: ## Get the dependencies for goreport
	@make lint_dep
	@$(GOROOT)/bin/go get -u github.com/gojp/goreportcard/cmd/goreportcard-cli
	@rm -f install.sh

goreport: goreport_dep ## Make goreport
	@git submodule sync --recursive
	@git submodule update --init --recursive
	@git --git-dir=$(PWD)/hcloud-badge/.git fetch --all
	@git --git-dir=$(PWD)/hcloud-badge/.git checkout feature/dev
	@git --git-dir=$(PWD)/hcloud-badge/.git pull origin feature/dev
	@./hcloud-badge/hcloud_badge.sh ${PROJECT_NAME}

build: ## Build the binary file
	@$(GOROOT)/bin/go build -o ${PROJECT_NAME} main.go

clean: ## Remove previous build
	@rm -f ${PROJECT_NAME}

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
