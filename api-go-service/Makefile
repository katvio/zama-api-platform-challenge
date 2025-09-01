# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
BINARY_NAME=server
BINARY_PATH=./cmd/server

# Build information
VERSION ?= 1.0.0
COMMIT ?= $(shell git rev-parse --short HEAD)
BUILD_TIME ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS=-ldflags "-w -s -X main.version=$(VERSION) -X main.commit=$(COMMIT)"

# Docker parameters
DOCKER_IMAGE=zama-api-service
DOCKER_TAG ?= latest

.PHONY: all build clean test coverage run deps docker-build docker-run help

all: clean deps test build

## Build the application
build:
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME) $(BINARY_PATH)

## Clean build artifacts
clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

## Run tests
test:
	$(GOTEST) -v ./...

## Run tests with race detection
test-race:
	$(GOTEST) -race -v ./...

## Run tests with coverage
coverage:
	$(GOTEST) -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out -o coverage.html

## Run the application locally
run:
	$(GOCMD) run $(BINARY_PATH)/main.go

## Download dependencies
deps:
	$(GOMOD) download
	$(GOMOD) tidy

## Lint the code (requires golangci-lint)
lint:
	golangci-lint run

## Format the code
fmt:
	$(GOCMD) fmt ./...

## Vet the code
vet:
	$(GOCMD) vet ./...

## Run security scan (requires gosec)
security:
	gosec ./...

## Build Docker image
docker-build:
	docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) .

## Run Docker container
docker-run:
	docker run -p 8080:8080 --rm $(DOCKER_IMAGE):$(DOCKER_TAG)

## Run Docker container with environment variables
docker-run-dev:
	docker run -p 8080:8080 --rm \
		-e LOG_LEVEL=debug \
		-e ENVIRONMENT=development \
		$(DOCKER_IMAGE):$(DOCKER_TAG)

## Build and run locally
dev: build
	./$(BINARY_NAME)

## Run with live reload (requires air: go install github.com/cosmtrek/air@latest)
dev-watch:
	air

## Install development tools
install-tools:
	go install github.com/cosmtrek/air@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

## Run benchmarks
bench:
	$(GOTEST) -bench=. -benchmem ./...

## Generate mocks (if using mockery)
mocks:
	@echo "Mock generation not configured yet"

## Check for outdated dependencies
deps-check:
	$(GOCMD) list -u -m all

## Update dependencies
deps-update:
	$(GOMOD) get -u ./...
	$(GOMOD) tidy

## Display help
help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
