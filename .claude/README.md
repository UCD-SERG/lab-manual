# `.claude/`

Project-level Claude Code config for this repo.

## `skills/` → shared skills via the `.ai-config` submodule

`skills` is a **symlink** to `../.ai-config/skills`, the `skills/` directory of
the [`d-morrison/ai-config`](https://github.com/d-morrison/ai-config) repo,
which is vendored here as a git submodule at `.ai-config` (see `.gitmodules`).

This makes those reusable skills available as **project skills** to:

- local Claude Code CLI sessions opened on this repo, and
- the `@claude` GitHub Actions bot (`.github/workflows/claude.yml`), which loads
  skills from `.claude/skills/` in the checked-out repo. The workflow's checkout
  step uses `submodules: recursive` so the submodule is populated in CI.

### Populating the submodule after cloning

A plain `git clone` leaves the submodule empty and the symlink dangling. Run:

```sh
git submodule update --init --recursive
```

(or clone with `git clone --recurse-submodules`).

### Updating to a newer ai-config

The submodule is pinned to a specific `ai-config` commit. To bump it:

```sh
git -C .ai-config fetch origin
git -C .ai-config checkout origin/main
git add .ai-config
git commit -m "Bump .ai-config submodule"
```

## `shared/` guidance fragments transcluded into the book

The submodule also carries `ai-config`'s `shared/` directory: small,
single-topic guidance fragments (coding style, writing style, PR/agent
workflow) that this book transcludes with `{{< include
.ai-config/shared/<topic>.md >}}`. The fragment is the single source of truth,
shared with `ai-config`'s own `CLAUDE.md`, so the guidance is edited once and
appears in both places.

Because the render now depends on the submodule, the Quarto build workflows
(`publish.yml`, `preview.yml`) check out submodules too --- not just the
`@claude` workflows. Render locally only after
`git submodule update --init --recursive`.
