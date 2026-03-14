# TextCraft Makefile
# macOS Swift app build automation

.PHONY: all build clean generate run archive release install help

# Default target
all: build

# Project configuration
PROJECT_NAME := TextCraft
SCHEME := TextCraft
CONFIGURATION := Debug
BUILD_DIR := build
ARCHIVE_PATH := $(BUILD_DIR)/$(PROJECT_NAME).xcarchive
EXPORT_PATH := $(BUILD_DIR)/export
APP_BUNDLE := $(BUILD_DIR)/$(CONFIGURATION)/$(PROJECT_NAME).app

# Generate Xcode project from project.yml
generate:
	@echo "Generating Xcode project from project.yml..."
	@if command -v xcodegen >/dev/null 2>&1; then \
		xcodegen generate; \
	else \
		echo "Warning: xcodegen not installed. Install with: brew install xcodegen"; \
		echo "Skipping project generation (using existing TextCraft.xcodeproj)"; \
	fi

# Build the app
build: generate
	@echo "Building $(PROJECT_NAME)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR)/DerivedData \
		build
	@echo "Build complete: $(APP_BUNDLE)"

# Build release version
build-release: generate
	@echo "Building $(PROJECT_NAME) (Release)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/DerivedData \
		build
	@echo "Release build complete: $(BUILD_DIR)/Release/$(PROJECT_NAME).app"

# Run the app
run: build
	@echo "Running $(PROJECT_NAME)..."
	open $(APP_BUNDLE)

# Archive for distribution
archive: generate
	@echo "Creating archive..."
	@mkdir -p $(BUILD_DIR)
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		archive
	@echo "Archive created: $(ARCHIVE_PATH)"

# Export archive as .app bundle
export: archive
	@echo "Exporting archive..."
	@mkdir -p $(EXPORT_PATH)
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist exportOptions.plist || \
		(echo "Creating default exportOptions.plist..." && \
		echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>method</key><string>developer-id</string></dict></plist>' > exportOptions.plist && \
		xcodebuild -exportArchive \
			-archivePath $(ARCHIVE_PATH) \
			-exportPath $(EXPORT_PATH) \
			-exportOptionsPlist exportOptions.plist)
	@echo "Exported to: $(EXPORT_PATH)/"

# Create .dmg for distribution
dmg: export
	@echo "Creating DMG..."
	@if command -v create-dmg >/dev/null 2>&1; then \
		create-dmg \
			--volname "$(PROJECT_NAME)" \
			--window-pos 200 120 \
			--window-size 600 400 \
			--icon-size 100 \
			--app-drop-link 450 185 \
			"$(BUILD_DIR)/$(PROJECT_NAME).dmg" \
			"$(EXPORT_PATH)/$(PROJECT_NAME).app"; \
	else \
		hdiutil create -srcfolder "$(EXPORT_PATH)/$(PROJECT_NAME).app" \
			-volname "$(PROJECT_NAME)" \
			-fs HFS+ \
			-format UDZO \
			"$(BUILD_DIR)/$(PROJECT_NAME).dmg"; \
	fi
	@echo "DMG created: $(BUILD_DIR)/$(PROJECT_NAME).dmg"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	xcodebuild -project $(PROJECT_NAME).xcodeproj clean || true
	@echo "Clean complete"

# Deep clean (including generated project)
distclean: clean
	@echo "Deep cleaning (removing generated Xcode project)..."
	rm -rf $(PROJECT_NAME).xcodeproj
	@echo "Deep clean complete"

# Install dependencies (xcodegen)
install-deps:
	@echo "Checking dependencies..."
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "Installing xcodegen..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install xcodegen; \
		else \
			echo "Error: Homebrew not found. Please install Homebrew first: https://brew.sh"; \
			exit 1; \
		fi \
	else \
		echo "xcodegen already installed"; \
	fi

# Run tests
test: generate
	@echo "Running tests..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR)/DerivedData \
		test \
		-destination 'platform=macOS'

# Code format check (if swift-format is installed)
format-check:
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "Checking Swift formatting..."; \
		swift-format lint -r TextCraft/; \
	else \
		echo "swift-format not installed. Install with: brew install swift-format"; \
	fi

# Format code (if swift-format is installed)
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "Formatting Swift code..."; \
		swift-format -r -i TextCraft/; \
	else \
		echo "swift-format not installed. Install with: brew install swift-format"; \
	fi

# Show available targets
help:
	@echo "TextCraft Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build         - Build the app (Debug)"
	@echo "  make build-release - Build the app (Release)"
	@echo "  make run           - Build and run the app"
	@echo "  make generate      - Regenerate Xcode project from project.yml"
	@echo "  make archive       - Create archived build for distribution"
	@echo "  make export        - Export archive as .app bundle"
	@echo "  make dmg           - Create distributable .dmg file"
	@echo "  make clean         - Remove build artifacts"
	@echo "  make distclean     - Deep clean (remove build + Xcode project)"
	@echo "  make install-deps  - Install build dependencies (xcodegen)"
	@echo "  make test          - Run unit tests"
	@echo "  make format        - Format Swift code"
	@echo "  make format-check  - Check Swift code formatting"
	@echo "  make help          - Show this help message"
