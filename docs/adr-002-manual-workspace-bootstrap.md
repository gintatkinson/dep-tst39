# Architectural Decision Record: Manual Workspace Construction (Bypassing Bootstrap due to Issue #65)

## Status
Approved

## Context
The standard development pipeline mandates that all downstream workspaces (e.g., the Flutter environment under `app_flutter/`) be initialized using the `bootstrap_downstream.py` script. This script is responsible for copy-seeding upstream scaffolding, layout configurations, and basic test files to ensure baseline conformance.

## Problem
During the initialization phase, the `bootstrap_downstream.py` script was found to have a critical defect (detailed in **GitHub Issue #65**), preventing it from successfully copying directory structures or resolving file permissions in the target workspace on macOS. 

## Decision
Instead of waiting for an upstream fix for `bootstrap_downstream.py`, the team decided to bypass the bootstrapping script and manually configure the Flutter workspace from scratch. 

## Conformance & Integration Steps Taken:
1. **Manual Scaffolding**: Initialized a clean Flutter project structure matching the upstream directory layout.
2. **Re-implementation of Core Configurations**: Ported and configured the necessary build settings, `pubspec.yaml` dependency constraints, and `analysis_options.yaml` strict lint rules.
3. **Manual Component Realization**: Re-implemented the mandated baseline components (such as the resizable Split Workspace, the Breadcrumbs widget, and the Property Grid layout) to mirror the upstream layout schema (`logical-layout.json`).
4. **Validation Cleared**: All manually configured files were verified via `verify_model_coverage.py` and `flutter test` to ensure they meet the 100% compliance gate.
