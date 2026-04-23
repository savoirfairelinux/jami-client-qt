# Scope
- Only change what the task requires
- Do not refactor surrounding code unless it directly blocks the task
- Do not add features, flags, or configurability beyond what is asked
- Do not add comments or docstrings to code you did not change

# Tests
- Attempt Test-Driven Development (TDD) when possible; especially for new features or bug fixes
- Update tests when changing tested logic
- Do not delete tests unless the covered behavior is removed

# Docs
- Update docs when changing public interfaces or user-facing behavior
- Do not update docs for internal refactors

# Dependencies
- Prefer CMake fetch content over git submodules; follow the rules in `contrib_tools.cmake`
- Note that the ability to build offline is critical, so system dependency support is important

# Validation
- Validate only at system boundaries (user input, external APIs, file I/O)
