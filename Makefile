.DEFAULT_GOAL := build

export GO111MODULE=on
export CGO_ENABLED=0
export VERSION=$(shell git describe --abbrev=0 --tags 2> /dev/null || echo "0.1.0")
export TAG=$VERSION
export BUILD=$(shell git rev-parse HEAD 2> /dev/null || echo "undefined")
BINARY=fox
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.Build=$(BUILD) -s -w"

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build
	go build $(LDFLAGS) -o $(BINARY) 

.PHONY: compressed
compressed: fullbuild
	upx --brute $(BINARY)

.PHONY: docker-nopack
docker-nopack: ## Build the docker image without packing binaries
	docker build -t $(BINARY)-nopack:latest -t $(BINARY)-nopack:$(BUILD) \
		--build-arg build=$(BUILD) --build-arg version=$(VERSION) \
		-f Dockerfile.nopack .

.PHONY: docker
docker: ## Build the docker image with packed binaries
	docker build -t $(BINARY):latest -t $(BINARY):$(BUILD) \
		--build-arg build=$(BUILD) --build-arg version=$(VERSION) \
		-f Dockerfile .

.PHONY: lint
lint: ## Runs the linter
	$(GOPATH)/bin/golangci-lint run --exclude-use-default=false

.PHONY: release
release: ## Create a new release on Github
	goreleaser

.PHONY: snapshot
snapshot: ## Create a new snapshot release
	goreleaser --snapshot --skip-publish --rm-dist

.PHONY: test
test: ## Run the test suite
	CGO_ENABLED=1 go test -race -coverprofile="coverage.txt" ./...

.PHONY: clean
clean: ## Remove the binary
	if [ -f $(BINARY) ] ; then rm $(BINARY) ; fi
	if [ -f coverage.txt ] ; then rm coverage.txt ; fi
