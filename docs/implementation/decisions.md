# Implementation Decisions

*This document permanently records implementation decisions that affect the project, complementing the initial Architecture document.*

## 2026-08-01: Progressive Dependency Management
**Decision**: Adopt progressive dependency management instead of installing all roadmap-defined packages in Phase 0.
**Reason**: Reduces initial project bloat and clarifies the exact architectural moment each package is required.
**Alternatives Considered**: Adding all dependencies in Phase 0 as initially written in the roadmap.
**Impact**: Dependencies (like `sqflite`, `pdf`, `archive`) will be installed iteratively in the specific phases where they are first needed.

## 2026-08-01: Avoid Placeholder Files
**Decision**: Do not create empty architectural placeholder directories or files.
**Reason**: Keeps the project tree clean and meaningful. Empty files add noise to the repository.
**Alternatives Considered**: Creating the complete `lib/` tree with empty files during Phase 0.
**Impact**: Directories and files will only be created when they have actual implementation code inside them.
