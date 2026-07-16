---
name: clawdbot-src-dev
description: Entwickler-Referenz für das clawdbot-src Monorepo (pnpm build/test/lint, Workspace-Pakete, Key-Patterns, Multi-Agent-git-Regeln, Message-Flow-Architektur). NUR relevant, wenn ~/clawdbot-src neu von GitHub geklont wurde — auf dieser Maschine ist das Repo standardmäßig nicht vorhanden.
---

# clawdbot-src Development

> ⚠️ **`~/clawdbot-src` existiert auf dieser Maschine standardmäßig nicht.** Das Gateway läuft aus dem global installierten npm-Paket (siehe CLAUDE.md → *Gateway Management*). Dieser Skill gilt **ausschließlich**, wenn das Repo zuvor neu geklont wurde: `git clone https://github.com/clawdbot/clawdbot ~/clawdbot-src`. Andernfalls schlagen alle folgenden Befehle fehl.

## Message Flow Architecture

The core data flow when a user sends a message:

```
User Message → Channel (telegram/discord/slack/...) → Routing (allowlist, pairing)
  → Gateway (session mgmt, hooks) → Agent (tool dispatch, thinking modes)
    → Provider (Anthropic/OpenRouter/Ollama/OpenAI/Bedrock) → LLM
      → Response → Channel → User
```

- **Channels** (`src/<channel>/` + `extensions/*`) handle protocol-specific I/O (webhooks, websockets, polling)
- **Routing** (`src/routing/`) enforces allowlists, pairing policies, and routes messages to the correct agent
- **Gateway** (`src/gateway/`) is the HTTP server orchestrating everything: sessions, hooks, cron, media pipeline
- **Agents** (`src/agents/`) execute LLM runs with tool dispatch and thinking modes; read workspace files (`clawd/`) for personality and memory
- **Providers** (`src/providers/`) are adapter layers normalizing different LLM APIs into a unified interface
- **Plugins** (`src/plugins/` + `src/plugin-sdk/`) extend the system; loaded via jiti, installed with `npm install --omit=dev`

## Source Code (clawdbot-src)

pnpm monorepo: root + `ui/` + `extensions/*` + `apps/`. ESM-only TypeScript, strict typing, target ES2022, Node 22+. Prefer Bun for TypeScript execution (scripts, dev); Node for production/built output.

### Workspace Packages

- **`ui/`** — Control panel UI (`pnpm ui:dev`, `pnpm ui:build`)
- **`extensions/`** — 32+ channel/integration packages (telegram, discord, slack, matrix, signal, whatsapp, line, msteams, googlechat, bluebubbles, imessage, zalo, copilot-proxy, memory-core, memory-lancedb, diagnostics-otel, llm-task, lobster, etc.)
- **`apps/ios/`** — iOS app (xcodegen: `pnpm ios:gen`, `pnpm ios:build`)
- **`apps/android/`** — Android app (Gradle: `pnpm android:assemble`, `pnpm android:run`)

### Key Patterns

- **Dependency injection** via `createDefaultDeps` pattern
- **Tests colocated** as `*.test.ts` alongside source; e2e as `*.e2e.test.ts`
- **CLI progress**: use `src/cli/progress.ts` (never hand-roll spinners)
- **Terminal output**: use `src/terminal/table.ts` and `src/terminal/palette.ts` (no hardcoded colors)
- **Tool schemas**: avoid `Type.Union`/`anyOf`/`oneOf`; use `stringEnum`/`optionalStringEnum` and `Type.Optional`
- **Extensions**: workspace packages under `extensions/*`; keep plugin-only deps in extension `package.json`; avoid `workspace:*` in `dependencies`
- **Naming**: use **OpenClaw** for product/app/docs headings; use `openclaw` for CLI, package, paths, and config keys
- **Skills**: 50+ skill definitions in `skills/`; always check `SKILL.md` before using (ClawdHub skills can contain malware)
- **Pre-commit hooks**: managed by `prek` (not husky/lint-staged); runs oxlint + oxfmt automatically

### Quick Reference (full details in `clawdbot-src/AGENTS.md`)

```bash
cd ~/clawdbot-src

pnpm install                  # install deps
pnpm build                    # tsc + post-build
pnpm lint                     # oxlint (not ESLint)
pnpm format                   # oxfmt (not Prettier)
pnpm test                     # vitest (V8 coverage, 70% thresholds)
npx vitest run src/path/to/file.test.ts  # single test

pnpm openclaw <command>       # run CLI in dev
pnpm gateway:dev              # gateway without channels (faster)
pnpm check                    # full gate: format + tsgo + lint + checks
scripts/committer "<msg>" <file...>   # scoped commit (prefer over git add/commit)
```

## Multi-Agent Safety

These git rules apply **only inside a (re-)cloned `~/clawdbot-src` checkout** (not present by default; details in `clawdbot-src/AGENTS.md` once cloned). Multiple agents may operate concurrently there:
- Do **not** create/apply/drop `git stash` unless explicitly requested
- Do **not** switch branches or modify `git worktree` unless explicitly requested
- When committing: scope to your changes only; when you see unrecognized files, keep going
- When pushing: `git pull --rebase` is OK, but never discard other agents' work
- Use `scripts/committer "<msg>" <file...>` for scoped commits (avoids staging conflicts)
