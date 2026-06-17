---
name: git-development-workflow
description: Project Git workflow standards for focused commits, Conventional Commit messages, branch naming, and precise staging. Use when Codex or any agent needs to inspect Git status, create a branch, stage changes, split unrelated edits, write a commit message, or create a commit in this repository.
---

# Git Development Workflow

Use this skill whenever a task involves Git history, staging, branches, or commits in this project.

## Workflow

1. Inspect the worktree before changing Git state:
   - Run `git status --short --branch`.
   - Identify unrelated existing changes and leave them untouched.
   - If a file contains both task-related and unrelated changes, use precise staging.

2. Keep each commit focused:
   - Commit one logical change at a time.
   - Do not combine unrelated features, fixes, refactors, docs, or tooling changes.
   - Prefer multiple small commits over one mixed commit.

3. Stage deliberately:
   - Stage only files or hunks that belong to the current logical change.
   - Use `git add <path>` for files wholly owned by the change.
   - Use `git add -p <path>` when only some hunks should be staged.
   - Avoid `git add .` unless every changed file is intentionally part of the same commit.

4. Write commit messages in this format:

```text
<type>: <short description>

[optional body]

[optional footer]
```

Common types:

- `feat`: user-visible feature
- `fix`: bug fix
- `docs`: documentation-only change
- `style`: formatting or style change with no logic impact
- `refactor`: code restructuring without feature or bug fix
- `test`: tests only
- `chore`: build, tooling, repository maintenance

Keep the subject concise and specific. Use a body when it helps explain non-obvious context, notable implementation choices, or issue links.

5. Use branch names that show intent:

- `feature/<name>` for feature work
- `fix/<problem>` for bug fixes
- `release/<version>` for release preparation
- `dev/<name>/<topic>` for personal development

When merging completed feature branches into the main branch, prefer `git merge --no-ff <branch>` when preserving branch history is useful.

## Commit Checklist

Before `git commit`:

- Confirm the staged diff with `git diff --cached --stat` and, when needed, `git diff --cached`.
- Confirm no unrelated files are staged.
- Choose the commit type from the actual staged change.
- Use a single focused subject, for example `docs: add git development workflow skill`.

After `git commit`:

- Run `git status --short --branch`.
- Report the commit hash and note any remaining unstaged or untracked changes.
