# Design: Briefly Daily Brief System Redesign
**Date**: 2026-01-06
**Status**: Validated

## Overview
Redesigning the `briefly` core to move from mocked services to a robust, Peekaboo-inspired CLI orchestration system. The goal is to provide a reliable "Daily Brief" by aggregating data from local CLI tools and external APIs, with built-in dependency management and intelligent synthesis.

## 1. Core Dependency Architecture
Introduces a `DependencyManager` to handle external CLI tools (`imsg`, `wacli`, `gog`, etc.).
- **Registry**: Metadata for each tool (name, check command, install command, description).
- **Just-in-Time Verification**: Services call `ensure(dependency:)` before execution.
- **Interactive Prompts**: In CLI mode, prompts user to install missing tools. In MCP mode, returns structured errors with instructions.

## 2. Interactive Setup & Authentication
A dedicated `briefly setup` command for guided onboarding.
- **Binary Verification**: Path checks.
- **Auto-Installation**: JIT and bulk installation options.
- **Auth Smoke Tests**: Verifies CLI tool authentication states.
- **Guided Auth**: Instructions for tools requiring manual login (e.g., `gog login`).

## 3. Data Flow & Shell Execution
- **ShellExecutor Actor**: A thread-safe actor for spawning processes, piping output, and capturing exit codes.
- **Service Pattern**: 
    1. Ensure dependency.
    2. Execute shell command.
    3. Parse output (JSON/Text).
    4. Validate and return data.

## 4. Peekaboo-Inspired Provider Model
Moving to a **Capability-Action** system.
- **Provider Protocol**: Defines `id`, `binaryName`, `checkCapability()`, and `perform(action:parameters:)`.
- **Action Results**: Detailed objects with `stdout`, `stderr`, `exitCode`, and state snapshots.
- **Smart Waiting**: Timeouts and retries based on tool readiness.

## 5. Synthesis & Research Loop
Two-pass orchestration for intelligence.
- **Pass 1**: Aggregate raw data and identify "Research Triggers" (names, companies, topics).
- **Pass 2**: Conduct web research via `brave-search` for triggers.
- **LLM Synthesis**: Combine raw data + research findings into a context-aware summary.
- **Output Formats**: Rich Markdown for history + SSML-optimized text for ElevenLabs voice generation.
- **Entity Cache**: Local JSON cache to avoid redundant research.
