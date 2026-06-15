# AGENTS.md

This file is the live handoff guide for agents working on **这塘我包了**. Keep it current whenever implementation progress, architecture, balance assumptions, or verification steps change.

## Project Snapshot

- Engine: Godot 4.6.3, main scene `res://scenes/Main.tscn`.
- Game type: mobile-first fish pond contracting / risk decision game.
- Current stage: playable MVP loop in Godot UI with procedural daily ponds, pond inspection, contract confirmation, post-contract choices, harvest simulation, settlement, fish-king special result, and next-day progression.
- Current README is minimal; treat this file as the primary working guide until README is expanded.
- Assets folders exist as placeholders only: `assets/ui`, `assets/ponds`, `assets/effects`, `assets/fish`.

## Current Implemented Flow

1. `scripts/main.gd` starts with a main menu, displays cash/day, and enters the pond list.
2. `scripts/pond_list.gd` generates or reuses 3 ponds for the current day.
3. `scripts/pond_detail.gd` shows pond info, lets the player inspect with tools, and confirms whether the pond can be contracted.
4. `scripts/after_contract_choice.gd` lets the player transfer, sell one net, fish manually, abandon, or choose a work plan.
5. `scripts/fishing_simulator.gd` rolls fish type, weight, income, and quality.
6. `scripts/action_resolver.gd` creates transfer and one-net opportunities based on harvest quality.
7. `scripts/settlement.gd` shows income/cost breakdown, fish details, fish-king presentation, and advances to the next day.
8. `scripts/game_state.gd` carries the session state across screens and resets per-round state at the right transitions.

## Core Architecture

- `data/*.json` are the balance/source tables. Prefer adding tunable values here before hardcoding more constants in scripts.
- `scripts/data_loader.gd` is the shared JSON loader and path registry.
- `scripts/game_state.gd` owns mutable run state, cash changes, round reset, contracting, settlement totals, and day advancement.
- `scripts/ui_controller.gd` is the only screen router. Add new scene transitions here rather than scattering scene replacement logic.
- `scripts/pond_generator.gd` creates daily pond offers and hidden pond qualities.
- `scripts/inspection_system.gd` turns hidden pond values into fuzzy player-facing signals.
- `scripts/fishing_simulator.gd` resolves fishing results and fish income.
- `scripts/action_resolver.gd` resolves market opportunities after fishing.
- `scenes/*.tscn` hold the screen layouts. Keep node paths aligned with each script's `@onready` references.

## Important Gameplay Invariants

- Each day should offer 3 ponds.
- Daily ponds should remain stable while the player views/backtracks within the same day.
- The hidden value profile intentionally includes one surplus, one break-even, and one loss pond per day.
- Inspection should narrow uncertainty, not reveal exact hidden values.
- Each inspection tool can be used once per pond round.
- Contracting deducts the pond quote immediately.
- The player cannot contract if the remaining cash would be below `min_working_capital`.
- Work plans must require available cash before applying harvest results.
- `full` / `drain` is final and should go to settlement.
- `low` and `standard` can be repeated while cash allows.
- Selling one net can happen at most once per round.
- Settlement net profit currently excludes the already-deducted contract fee and reports it separately as "承包费：已在承包时扣除".

## Current Balance Tables

- `data/game_balance.json`
  - `initial_cash`: 10000
  - `min_working_capital`: 1000
  - `ponds_per_day`: 3
  - work costs: low 500, standard 1200, full 2500
- `data/tools.json`
  - `observe`: free, low accuracy
  - `fish_finder`: 300
  - `master`: 800
- `data/fish_types.json`
  - `small_fish`, `normal_fish`, `big_fish`, `fish_king`
- `data/pond_types.json`
  - `artificial_pond`, `old_pond`, `reservoir_pond`

## Development Rules

- Use GDScript and the existing Godot UI structure unless there is a clear reason to change direction.
- Preserve Chinese player-facing copy unless intentionally revising UX tone.
- Do not edit `.uid` files by hand.
- Do not commit `.godot/`, `.DS_Store`, or generated platform exports.
- When changing a scene script, check the matching `.tscn` node paths before renaming nodes.
- Keep economic changes data-driven where practical.
- Keep random mechanics readable and bounded with `clampf`, `clampi`, or explicit min/max logic.
- If adding save/load, isolate persistence from `GameState` calculation methods so the existing screen flow remains testable.

## Git And Repository

- Canonical GitHub repository: `https://github.com/shawnlee6701/fishpond`.
- Local `origin` should point to `https://github.com/shawnlee6701/fishpond.git`.
- Commit all project code changes to this repository unless the user explicitly gives a different target.
- Default branch is currently `main`.
- Before committing, check `git status --short` and stage only files relevant to the task.
- After committing, push the branch to `origin` so GitHub stays current.

## Verification

Run these from the project root after meaningful changes:

```bash
godot --version
godot --headless --path . --quit
```

If the headless check crashes while opening `user://logs` inside a restricted sandbox, rerun the same command with permission to write Godot's user log directory. A clean project load should print the Godot version and exit with code 0.

For gameplay/UI changes, also run the project in the Godot editor or player and manually verify:

- Main menu shows starting cash and day.
- Pond list shows 3 ponds.
- Backtracking from pond detail preserves the same day's ponds.
- Each inspection tool deducts the expected cash and cannot be reused.
- Contract confirmation blocks insufficient remaining working capital.
- After contracting, low/standard/full work buttons reflect available cash.
- Non-final harvest can create market opportunities and continue the round.
- Full harvest, transfer, or abandon reaches settlement.
- Next day increments day, resets round-only state, and generates new ponds.
- Fish-king result displays the special panel without breaking settlement totals.

## Known Gaps / Next Likely Work

- README still needs a real product/game overview.
- No automated tests or deterministic simulation harness exists yet.
- No save/load, meta progression, tutorial, or end condition exists yet.
- Visual assets are placeholders; current UI is mostly native Godot controls.
- Balance has not been stress-tested across many simulated days.
- `game_balance.ponds_per_day` exists, but daily generation currently hardcodes 3 ponds in `PondGenerator`.
- Fish-king panel currently generates presentation weight/value at settlement time rather than reusing exact catch detail data.
- Main menu stats are not refreshed after returning from later screens because the current loop stays inside `ScreenContainer`.

## Live Update Requirement

Update this file immediately when:

- A new scene, major script, data table, or system is added.
- A gameplay invariant changes.
- Balance parameters or data ownership changes.
- Verification commands change.
- A known gap is completed or a new blocker appears.
- The current project stage moves beyond the MVP loop described above.

When updating, prefer short factual bullets over narrative. Future agents should be able to read this file first and continue without rediscovering the project from scratch.
