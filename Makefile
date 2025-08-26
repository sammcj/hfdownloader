# Binary name
BINARY=hfdownloader

# Get version from main.go
VERSION=$(shell grep '^const VERSION' main.go | sed -E 's/.*= *"([^"]+)".*/\1/')

# Build directories
BUILD_DIR=bin
BUILD_TMP_DIR=$(BUILD_DIR)/.tmp

# Go build flags
LDFLAGS=-ldflags "-s -w"
GO_BUILD=CGO_ENABLED=0 go build $(LDFLAGS)

# Default target
.PHONY: all
all: clean macos linux
#windows

# Create build directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Clean build artefacts
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

# Update VERSION file
.PHONY: version
version:
	@echo "$(VERSION)" > VERSION
	@echo "Version: $(VERSION)"

# Build for macOS (both AMD64 and ARM64)
.PHONY: macos
macos: version | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/macos
	GOOS=darwin GOARCH=arm64 $(GO_BUILD) -o "$(BUILD_DIR)/macos/$(BINARY)" main.go
	@echo "Built for macOS (AMD64, ARM64)"

# Build for Linux AMD64
.PHONY: linux
linux: version | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/linux
	GOOS=linux GOARCH=amd64 $(GO_BUILD) -o "$(BUILD_DIR)/linux/$(BINARY)" main.go
	GOOS=linux GOARCH=arm64 $(GO_BUILD) -o "$(BUILD_DIR)/linux/$(BINARY)_arm64" main.go
	@echo "Built for Linux (AMD64)"

# Install locally
# TODO: refactor this to a single command
.PHONY: install-macos
install-macos: macos
	cp "$(BUILD_DIR)/macos/$(BINARY)" /usr/local/bin/$(BINARY)
	@echo "Installed to /usr/local/bin/$(BINARY)"

.PHONY: install-linux
install-linux: linux
	cp "$(BUILD_DIR)/linux/$(BINARY)" /usr/local/bin/$(BINARY)
	@echo "Installed to /usr/local/bin/$(BINARY)"

.PHONY: install-linux-arm
install-linux-arm: linux
	cp "$(BUILD_DIR)/linux/$(BINARY)_arm64" /usr/local/bin/$(BINARY)
	@echo "Installed to /usr/local/bin/$(BINARY)"

# Run tests
.PHONY: test
test:
	go test -v ./...

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all      - Build for all platforms (default)"
	@echo "  clean    - Remove build artifacts"
	@echo "  darwin   - Build for macOS (ARM64)"
	@echo "  linux    - Build for Linux (AMD64, ARM64)"
	@echo "  install-macos  - Install locally"
	@echo "  install-linux  - Install locally"
	@echo "  install-linux-arm  - Install locally"
	@echo "  test     - Run tests"
	@echo "  version  - Show current version"
	@echo "  help     - Show this help"
