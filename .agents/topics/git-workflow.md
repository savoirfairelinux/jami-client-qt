# Rules
- Never force-push to `main` or `master`
- Never skip commit hooks (`--no-verify`)
- We work with gerrit, so it's okay to amend a commit that has already been pushed
- Never reset or restore files without explicit instruction
- Do not create branches, tags, or releases unless asked
- Do not push to remote unless asked
- Do not rebase unless asked

# Branching
Trunk-based development. Work directly on `main` or `master` for small changes;
use worktree branches for larger work, and merge them back to `main` or `master` when done.
