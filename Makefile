# Binary name
BINARY=hfdownloader

# Get version from main.go
VERSION=$(shell grep '^const VERSION' main.go | sed -E 's/.*= *"([^"]+)".*/\1/')

# Version components for bumping
MAJOR=$(shell echo $(VERSION) | cut -d. -f1)
MINOR=$(shell echo $(VERSION) | cut -d. -f2)  
PATCH=$(shell echo $(VERSION) | cut -d. -f3)

# Build directories
BUILD_DIR=bin
BUILD_TMP_DIR=$(BUILD_DIR)/.tmp

# Platform and architecture detection
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Detect OS
ifeq ($(UNAME_S),Linux)
    OS=linux
    INSTALL_PATH=/usr/local/bin
endif
ifeq ($(UNAME_S),Darwin)
    OS=darwin
    INSTALL_PATH=/usr/local/bin
endif

# Detect architecture
ifeq ($(UNAME_M),x86_64)
    ARCH=amd64
endif
ifeq ($(UNAME_M),amd64)
    ARCH=amd64
endif
ifeq ($(UNAME_M),arm64)
    ARCH=arm64
endif
ifeq ($(UNAME_M),aarch64)
    ARCH=arm64
endif

# Set GOOS and GOARCH for local builds
GOOS=$(OS)
GOARCH=$(ARCH)

# Go build flags
LDFLAGS=-ldflags "-s -w"
GO_BUILD=CGO_ENABLED=0 go build $(LDFLAGS)

# Local build settings
BUILD_TARGET=$(BUILD_DIR)/$(OS)/$(BINARY)$(if $(filter amd64,$(ARCH)),,_$(ARCH))

# Default target
.PHONY: all
all: clean macos linux
#windows

# Smart build for current platform and architecture
.PHONY: build
build: version | $(BUILD_DIR)
	@echo "Building for $(OS)/$(ARCH)..."
	mkdir -p $(BUILD_DIR)/$(OS)
	GOOS=$(OS) GOARCH=$(ARCH) $(GO_BUILD) -o "$(BUILD_TARGET)" main.go
	@echo "Built $(BUILD_TARGET)"

# Smart install for current platform
.PHONY: install
install: build
	@echo "Installing $(BUILD_TARGET) to $(INSTALL_PATH)..."
	@if [ -w "$(INSTALL_PATH)" ]; then \
		cp "$(BUILD_TARGET)" "$(INSTALL_PATH)/$(BINARY)"; \
		echo "Installed to $(INSTALL_PATH)/$(BINARY)"; \
	else \
		echo "Require sudo privileges to install to $(INSTALL_PATH)"; \
		sudo cp "$(BUILD_TARGET)" "$(INSTALL_PATH)/$(BINARY)"; \
		echo "Installed to $(INSTALL_PATH)/$(BINARY)"; \
	fi

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

# Version bumping functions
define bump_version
	@echo "Bumping version from $(VERSION) to $(1)"
	@sed -i.bak 's/const VERSION = ".*"/const VERSION = "$(1)"/' main.go && rm main.go.bak
	@echo "$(1)" > VERSION
	@echo "Updated to version $(1)"
endef

# Semantic version bump targets
.PHONY: bump-major
bump-major:
	$(call bump_version,$(shell echo $$(($(MAJOR)+1)).0.0))

.PHONY: bump-minor  
bump-minor:
	$(call bump_version,$(MAJOR).$(shell echo $$(($(MINOR)+1))).0)

.PHONY: bump-patch
bump-patch:
	$(call bump_version,$(MAJOR).$(MINOR).$(shell echo $$(($(PATCH)+1))))

# Aliases for convenience
.PHONY: bump
bump: bump-patch

.PHONY: major
major: bump-major

.PHONY: minor
minor: bump-minor

.PHONY: patch  
patch: bump-patch

# Release targets (bump + build + tag)
.PHONY: release-major
release-major: bump-major all tag

.PHONY: release-minor
release-minor: bump-minor all tag

.PHONY: release-patch  
release-patch: bump-patch all tag

.PHONY: release
release: release-patch

# Git tagging
.PHONY: tag
tag:
	@echo "Creating git tag v$(VERSION)..."
	@git add main.go VERSION
	@git commit -m "Bump version to $(VERSION)" || true
	@git tag -a "v$(VERSION)" -m "Release version $(VERSION)"
	@echo "Created tag v$(VERSION)"

# Build for macOS (both AMD64 and ARM64)
.PHONY: macos
macos: version | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/darwin
	GOOS=darwin GOARCH=amd64 $(GO_BUILD) -o "$(BUILD_DIR)/darwin/$(BINARY)_amd64" main.go
	GOOS=darwin GOARCH=arm64 $(GO_BUILD) -o "$(BUILD_DIR)/darwin/$(BINARY)_arm64" main.go
	@echo "Built for macOS (AMD64, ARM64)"

# Build for Linux (both AMD64 and ARM64)
.PHONY: linux
linux: version | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/linux
	GOOS=linux GOARCH=amd64 $(GO_BUILD) -o "$(BUILD_DIR)/linux/$(BINARY)" main.go
	GOOS=linux GOARCH=arm64 $(GO_BUILD) -o "$(BUILD_DIR)/linux/$(BINARY)_arm64" main.go
	@echo "Built for Linux (AMD64, ARM64)"

# Legacy install targets (deprecated - use 'install' instead)
.PHONY: install-macos
install-macos:
	@echo "DEPRECATED: Use 'make install' instead"
	@$(MAKE) install

.PHONY: install-linux
install-linux:
	@echo "DEPRECATED: Use 'make install' instead"
	@$(MAKE) install

.PHONY: install-linux-arm
install-linux-arm:
	@echo "DEPRECATED: Use 'make install' instead"
	@$(MAKE) install

# Run tests
.PHONY: test
test:
	go test -v ./...

# Show system information
.PHONY: info
info:
	@echo "System Information:"
	@echo "  OS: $(OS) ($(UNAME_S))"
	@echo "  Architecture: $(ARCH) ($(UNAME_M))"
	@echo "  Build target: $(BUILD_TARGET)"
	@echo "  Install path: $(INSTALL_PATH)"
	@echo "  Version: $(VERSION)"

# Show help
.PHONY: help
help:
	@echo "HuggingFace Downloader Makefile"
	@echo ""
	@echo "Smart targets (automatically detect platform/arch):"
	@echo "  build    - Build for current platform ($(OS)/$(ARCH))"
	@echo "  install  - Build and install for current platform"
	@echo ""
	@echo "Multi-platform targets:"
	@echo "  all      - Build for all platforms (default)"
	@echo "  macos    - Build for macOS (AMD64, ARM64)"
	@echo "  linux    - Build for Linux (AMD64, ARM64)"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean    - Remove build artifacts"
	@echo "  test     - Run tests"
	@echo "  version  - Update VERSION file"
	@echo "  info     - Show system information"
	@echo "  help     - Show this help"
	@echo ""
	@echo "Legacy targets (deprecated):"
	@echo "  install-macos, install-linux, install-linux-arm"
