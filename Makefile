.PHONY: all build run test clean setup install check format lint help models verify

# Colors for output
GREEN := \033[0;32m
BLUE := \033[0;34m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
all: build

# Build the project
build:
	@echo "$(BLUE)🔨 Building briefly...$(NC)"
	@swift build -c release
	@echo "$(GREEN)✅ Build complete!$(NC)"

# Build for development (debug)
build-dev:
	@echo "$(BLUE)🔨 Building briefly (debug)...$(NC)"
	@swift build
	@echo "$(GREEN)✅ Build complete!$(NC)"

# Run the CLI
run:
	@swift run briefly

# Run with arguments (usage: make run-args ARGS="brief --voice")
run-args:
	@swift run briefly $(ARGS)

# Run tests
test:
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@swift test
	@echo "$(GREEN)✅ Tests complete!$(NC)"

# Clean build artifacts
clean:
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@rm -rf .build
	@echo "$(GREEN)✅ Clean complete!$(NC)

# Full clean (including models and venv)
clean-all: clean
	@echo "$(YELLOW)🧹 Cleaning models and Python environment...$(NC)"
	@rm -rf models
	@rm -rf .venv
	@echo "$(GREEN)✅ Full clean complete!$(NC)"

# Setup project (install dependencies, download models)
setup: submodules
	@echo "$(BLUE)🚀 Setting up briefly...$(NC)"
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh
	@echo "$(GREEN)✅ Setup complete!$(NC)"

# Update git submodules
submodules:
	@echo "$(BLUE)🔄 Updating submodules...$(NC)"
	@git submodule update --init --recursive
	@echo "$(GREEN)✅ Submodules updated!$(NC)"

# Install to system PATH
install: build
	@echo "$(BLUE)📦 Installing briefly to /usr/local/bin...$(NC)"
	@cp .build/release/briefly /usr/local/bin/briefly
	@echo "$(GREEN)✅ Installed! Run 'briefly --help' to get started.$(NC)"

# Uninstall from system PATH
uninstall:
	@echo "$(YELLOW)🗑️  Uninstalling briefly...$(NC)"
	@rm -f /usr/local/bin/briefly
	@echo "$(GREEN)✅ Uninstalled!$(NC)"

# Check project health
check: verify
	@echo "$(BLUE)🔍 Checking project health...$(NC)"
	@swift build 2>&1 | grep -q "error:" && (echo "$(RED)❌ Build errors found!$(NC)" && exit 1) || echo "$(GREEN)✅ No build errors$(NC)"
	@swift test 2>&1 | grep -q "Test Suite.*failed" && (echo "$(RED)❌ Tests failed!$(NC)" && exit 1) || echo "$(GREEN)✅ All tests pass$(NC)"
	@test -f .env && echo "$(GREEN)✅ .env file exists$(NC)" || echo "$(YELLOW)⚠️  .env file missing (run 'make setup')$(NC)"
	@test -d models/kokoro-82m && echo "$(GREEN)✅ Kokoro model found$(NC)" || echo "$(YELLOW)⚠️  Kokoro model missing (run 'make models')$(NC)"
	@test -d models/lfm-2.5-audio && echo "$(GREEN)✅ LFM 2.5 model found$(NC)" || echo "$(YELLOW)⚠️  LFM 2.5 model missing (run 'make models')$(NC)"
	@echo "$(GREEN)✅ Health check complete!$(NC)"

# Format code (using swift-format if available)
format:
	@echo "$(BLUE)🎨 Formatting code...$(NC)"
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format format --in-place --recursive Sources/ Tests/; \
		echo "$(GREEN)✅ Code formatted!$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  swift-format not found. Install with: brew install swift-format$(NC)"; \
	fi

# Lint code
lint:
	@echo "$(BLUE)🔍 Linting code...$(NC)"
	@swift build 2>&1 | grep -E "(error|warning):" || echo "$(GREEN)✅ No linting issues found!$(NC)"

# Download/verify local models
models:
	@echo "$(BLUE)📥 Checking local models...$(NC)"
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh --models-only
	@echo "$(GREEN)✅ Models ready!$(NC)"

# Verify installation
verify:
	@echo "$(BLUE)🔍 Verifying installation...$(NC)"
	@command -v swift >/dev/null 2>&1 || (echo "$(RED)❌ Swift not found. Install Xcode Command Line Tools.$(NC)" && exit 1)
	@swift --version | head -1
	@command -v python3 >/dev/null 2>&1 || (echo "$(RED)❌ Python 3 not found.$(NC)" && exit 1)
	@python3 --version
	@test -f .env && echo "$(GREEN)✅ .env file exists$(NC)" || echo "$(YELLOW)⚠️  .env file missing$(NC)"
	@echo "$(GREEN)✅ Verification complete!$(NC)"

# Start MCP server
mcp:
	@echo "$(BLUE)🚀 Starting MCP server...$(NC)"
	@swift run briefly mcp serve

# Generate today's brief
brief:
	@swift run briefly brief

# Generate brief with voice
brief-voice:
	@swift run briefly brief --voice

# Generate brief in JSON
brief-json:
	@swift run briefly brief --json

# Show help
help:
	@echo "$(BLUE)📋 briefly Makefile Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Setup & Installation:$(NC)"
	@echo "  make setup          - Run initial setup (dependencies, models, config)"
	@echo "  make install        - Build and install to /usr/local/bin"
	@echo "  make uninstall      - Remove from /usr/local/bin"
	@echo "  make verify         - Verify system requirements"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  make build          - Build release version"
	@echo "  make build-dev      - Build debug version"
	@echo "  make test           - Run tests"
	@echo "  make run            - Run briefly CLI"
	@echo "  make run-args       - Run with custom args (e.g., make run-args ARGS=\"brief --voice\")"
	@echo ""
	@echo "$(GREEN)Code Quality:$(NC)"
	@echo "  make check          - Run health checks"
	@echo "  make format         - Format code (requires swift-format)"
	@echo "  make lint           - Lint code"
	@echo ""
	@echo "$(GREEN)Models:$(NC)"
	@echo "  make models         - Download/verify local MLX models"
	@echo ""
	@echo "$(GREEN)Quick Commands:$(NC)"
	@echo "  make brief          - Generate today's brief"
	@echo "  make brief-voice    - Generate brief with voice"
	@echo "  make brief-json     - Generate brief in JSON format"
	@echo "  make mcp            - Start MCP server"
	@echo ""
	@echo "$(GREEN)Cleanup:$(NC)"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make clean-all      - Remove build artifacts, models, and venv"
	@echo ""
	@echo "$(GREEN)Help:$(NC)"
	@echo "  make help           - Show this help message"
