# AGENTS.md

This file is the live handoff guide for agents working on **这塘我包了**. Keep it current whenever implementation progress, architecture, balance assumptions, or verification steps change.

## Project Snapshot

- Engine: Godot 4.6.3, main scene `res://scenes/Main.tscn`.
- Game type: mobile-first fish pond contracting / risk decision game.
- Current stage: playable MVP loop in Godot UI with a designed homepage, safe-checkpoint continue/restart, procedural daily ponds, pond inspection, contract confirmation, post-contract choices, harvest simulation, settlement, fish-king special result, and next-place/day progression.
- UI copy pass completed for the first MVP loop: main menu, pond cards, inspection, contract confirmation, post-contract choices, transfer, one-net sale, work plans, and settlement now use clearer grounded Chinese business wording.
- Gameplay UI now follows one 1080 × 1920 hierarchy: global day/cash status at the top, page title below it, bounded or scrollable content in the middle, and visible actions that stay inside the authored canvas.
- Current README is minimal; treat this file as the primary working guide until README is expanded.
- `assets/ui/homepage.png` is the homepage artwork; `assets/ui/button_board.png` is the transparent wood-board texture used by both homepage buttons; `assets/ui/parchment_background.png` is the unified background for the pond list and other routed gameplay screens; `Design/Pond card/screen_transparent.png` is the cleaned blank-card derivative of `Design/Pond card/screen.png` used as the stretchable nine-patch texture; `Design/Pond Check/screen_clean.png` is the cleaned transparent paper dossier shared by pond detail and the post-contract choice page; `Design/Popup/popup_clean.png` is the cleaned transparent paper texture used by the responsive contract and transfer popups; `Design/Other Person/screen_clean.png` is the cleaned transparent transfer-buyer illustration.
- Result illustrations use cleaned transparent derivatives: `Design/Catch Fish King/screen_clean.png`, `Design/Earn More/screen_clean.png`, `Design/Earn Less/screen_clean.png`, `Design/Win More/screen_clean.png`, `Design/Win Less/screen_clean.png`, and `Design/Bankrupt/screen_clean.png`. Regenerate them from the matching `screen.png` sources with `python3 tools/clean_checkerboard_assets.py`.
- Other asset folders remain placeholders: `assets/ponds`, `assets/effects`, `assets/fish`.

## Current Implemented Flow

1. `scripts/main.gd` starts on the designed homepage. The first button shows “开始包塘” without a checkpoint and “继续包塘” with one; “重新开始” clears it and creates a fresh run.
2. `scripts/pond_list.gd` generates or reuses 3 ponds for the current day.
3. `scripts/pond_detail.gd` shows pond info, lets the player inspect with tools, and confirms whether the pond can be contracted.
4. `scripts/after_contract_choice.gd` lets the player transfer, sell one net, or enter a dedicated self-fishing page to choose a work plan.
5. `scripts/fishing_simulator.gd` rolls fish type, weight, income, and quality.
6. `scripts/action_resolver.gd` creates transfer and one-net opportunities based on harvest quality.
7. `scripts/settlement.gd` shows income/cost breakdown, fish details, fish-king presentation, and advances to the next day.
8. `scripts/game_state.gd` carries the session state across screens and resets per-round state at the right transitions.

## Core Architecture

- `data/*.json` are the balance/source tables. Prefer adding tunable values here before hardcoding more constants in scripts.
- `data/balance_rules.json` owns detailed formula knobs for pond generation, inspection thresholds, fishing odds, market offers, and simulation presets.
- `scripts/data_loader.gd` is the shared JSON loader and path registry.
- `scripts/balance_rules.gd` is the shared helper for reading balance rule dictionaries.
- `scripts/game_state.gd` owns mutable run state, cash changes, round reset, contracting, settlement totals, and day advancement.
- `scripts/save_system.gd` owns `user://save_game.json` persistence and stores only safe pond-list checkpoints: day, cash, and the current day's stable pond offers.
- `scripts/ui_controller.gd` is the only screen router. Add new scene transitions here rather than scattering scene replacement logic.
- `scripts/pond_generator.gd` creates daily pond offers and hidden pond qualities.
- `scripts/inspection_system.gd` turns hidden pond values into fuzzy player-facing signals.
- `scripts/fishing_simulator.gd` resolves fishing results and fish income.
- `scripts/action_resolver.gd` resolves market opportunities after fishing.
- `scripts/balance_simulator.gd` runs headless multi-run strategy simulations for ROI, bankrupt rate, cash percentiles, and fish-king exposure.
- `scripts/ui_kit.gd` owns the shared mobile-first UI frame: phone-safe panel margins, compact card/button/message styles, chips, and screen label roles.
- `scripts/ui_kit.gd` also owns the authored 1080 × 1920 design constants plus shared top-status, page-title, and modal-title styling.
- `scripts/ui_kit.gd` also owns the shared in-page modal layer: bounded paper cards, full-screen input-blocking masks, resize-safe centering, and scroll protection for oversized popup content.
- `tools/balance-lab/` is a static local web tuning console for adjusting `data/balance_rules.json` knobs and running browser-side simulations.
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
- Full/drain work cost is dynamic: `max(2000, current pond quote_price * 20%)`.
- Non-final self-fishing results use a blocking illustration popup: fish king overrides the result art; otherwise positive per-net profit uses Earn More and zero/negative per-net profit uses Earn Less.
- Final settlement art uses Bankrupt when cash is below 3000; otherwise fish king overrides the normal result art, then positive net profit uses Win More and zero/negative net profit uses Win Less.
- `full` / `drain` is final and should go to settlement.
- `low` and `standard` can be repeated while cash allows.
- Selling one net can happen at most once per round.
- The post-contract player-facing choices should not include an abandon / "认亏走人" option; use transfer as the exit path.
- Choosing "自己下网" opens a dedicated work-plan page: the original transfer/sell/self-fishing buttons are hidden, and the three work plans share the available page height equally.
- Settlement net profit currently excludes the already-deducted contract fee and reports it separately as "承包费：已在承包时扣除".
- Continue restores the latest pond-list checkpoint; incomplete inspection, contract, and harvest actions are intentionally not persisted.
- Restart deletes the existing checkpoint before creating a fresh run.

## Current Balance Tables

- `data/game_balance.json`
  - `initial_cash`: 30000
  - `min_working_capital`: 1000
  - `ponds_per_day`: 3
  - work costs: low 500, standard 1200
  - full/drain work cost: max 2000 or 20% of current pond quote
- `data/tools.json`
  - `observe`: free, low accuracy
  - `fish_finder`: 300
  - `master`: 1000
- `data/fish_types.json`
  - `small_fish`, `normal_fish`, `big_fish`, `fish_king`
- `data/pond_types.json`
  - `artificial_pond`, `old_pond`, `reservoir_pond`
- `data/balance_rules.json`
  - pond generation formula knobs, inspection thresholds, fishing weights, market offer odds, and simulation strategy presets
  - `pond_generation.pond_type_roi_targets`: gross fish-stock ROI bands by pond type, excluding inspection/work costs:
    - `artificial_pond`: low-risk / low-volatility, -10% to +30%
    - `old_pond`: mid-risk / mid-volatility, -30% to +50%
    - `reservoir_pond`: high-risk / high-volatility, -50% to +80%
  - `pond_generation.min_quote`: 4000, keeping fixed drain cost from dominating tiny ponds.
  - `pond_generation.profile_roi_bands`: maps surplus / break-even / loss pond profiles into high / middle / low positions inside each pond type's ROI band.
  - `scripts/balance_simulator.gd` prints `STRATEGY_ECONOMY` for player-path cost/revenue breakdown and `POND_TYPE_GROSS_ROI` for pond-type band verification.

## Development Rules

- Use GDScript and the existing Godot UI structure unless there is a clear reason to change direction.
- Preserve Chinese player-facing copy unless intentionally revising UX tone.
- Do not edit `.uid` files by hand.
- Do not commit `.godot/`, `.DS_Store`, or generated platform exports.
- When changing a scene script, check the matching `.tscn` node paths before renaming nodes.
- Prefer reusing `FishPoolUIKit` / `scripts/ui_kit.gd` for panel, card, button, chip, and label styling before adding one-off scene styles.
- Keep screen layouts mobile-first: narrow safe margins, scroll long content, short card copy, and large bottom-priority touch targets.
- Treat 1080 × 1920 as the authored UI canvas; align dynamic card text to painted artwork at that logical resolution and let Godot scale the canvas for devices.
- Keep every routed gameplay page in this order: global run status, page title, content, then operable actions. Keep every custom popup in this order: title, bounded/scrollable body, then operable actions.
- Put global run values such as day and player cash at the top of each screen before the page title or local pond/result details.
- Keep economic changes data-driven where practical.
- Keep random mechanics readable and bounded with `clampf`, `clampi`, or explicit min/max logic.
- Keep persistence in `scripts/save_system.gd`; do not put file I/O inside `GameState` calculation methods.

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

For balance tuning, run the simulator:

```bash
godot --headless --log-file /private/tmp/fish_pool_balance_sim.log --path . --script res://scripts/balance_simulator.gd -- --runs=1000 --days=12
```

Or open the local web tuning console:

```bash
python3 -m http.server 8766
# http://127.0.0.1:8766/tools/balance-lab/
```

If the headless check crashes while opening `user://logs` inside a restricted sandbox, rerun the same command with permission to write Godot's user log directory. A clean project load should print the Godot version and exit with code 0.

For gameplay/UI changes, also run the project in the Godot editor or player and manually verify:

- Homepage uses `assets/ui/homepage.png` and shows the wood-board continue/start button above “重新开始” at the bottom.
- “开始包塘” / “继续包塘” restores saved day/cash/pond offers when a checkpoint exists and otherwise starts fresh.
- “重新开始” clears the old checkpoint and starts from configured initial cash/day.
- Pond list shows 3 ponds.
- Pond list uses `assets/ui/parchment_background.png`, with “今日鱼塘” plus plain day and cash text at the top.
- Pond cards use `Design/Pond card/screen_transparent.png`, which removes the baked checkerboard fringe from the original `screen.png` while preserving its artwork.
- Pond-card content is centered for legibility: centered pond name, three horizontal tags, age/depth on one row, and centered water and rumor text.
- The quote is a highlighted horizontal badge at the upper right; “进塘验货” is a standard high-contrast red button with white text.
- At the 1080 × 1920 design resolution, each pond card is 540 logical pixels tall so the three daily cards fill the available vertical space on one screen.
- Pond detail uses the cropped transparent `Design/Pond Check/screen_clean.png` dossier as its information-card background; inspection actions use standard `FishPoolUIKit` buttons and no hand-drawn button textures.
- At 1080 × 1920, pond detail uses 70 px horizontal card margins, separate top status/card/bottom-action zones, and a bottom safe area; the card-internal inspection region scrolls independently when needed.
- Each inspection result appears only beneath its matching button; the inspection list scrolls inside the paper card so multiple expanded results cannot overflow the card or cover the bottom actions.
- Backtracking from pond detail preserves the same day's ponds.
- Each inspection tool deducts the expected cash and cannot be reused.
- Contract confirmation blocks insufficient remaining working capital.
- Contract confirmation uses `Design/Popup/popup_clean.png`, stays centered, and resizes with the game window without stretching its paper border.
- All confirmation popups use an opaque-input modal overlay with a dark mask; popup cards remain inside a 24 px viewport safe area and oversized body content scrolls instead of expanding the card.
- Contract and transfer popups both visibly retain title, scroll-safe content, and accept/cancel actions at 1080 × 1920.
- The post-contract choice page uses `Design/Pond Check/screen_clean.png` as its paper dossier background.
- “自己下网” switches to a dedicated page state with a return control and three equal-height work-plan buttons; the original bottom choice buttons must not remain visible.
- “转包脱手” opens a centered responsive popup using `Design/Popup/popup_clean.png`; a full-screen dim mask blocks the underlying page while open, and the offer appears above the cleaned buyer illustration and the speech bubble “兄弟一场，把这塘包给我”, with accept/reject actions at the bottom.
- After contracting, low/standard/full work buttons reflect available cash.
- Non-final harvest can create market opportunities and continue the round.
- Full harvest or transfer reaches settlement.
- "下一地方" advances the internal day counter, resets round-only state, and generates new ponds.
- Fish-king result displays the special panel without breaking settlement totals.
- Non-final self-fishing results show the cleaned Fish King / Earn More / Earn Less illustration popup and keep underlying actions blocked until dismissed.
- Settlement shows the cleaned Bankrupt / Fish King / Win More / Win Less illustration selected from the final cash and net-profit rules above.

## Known Gaps / Next Likely Work

- README still needs a real product/game overview.
- A deterministic balance simulator exists, but its strategies are first-pass proxies and need more design review before tuning against them.
- Save/load currently covers safe pond-list checkpoints only; active mid-round state is not resumed.
- No meta progression, tutorial, or end condition exists yet.
- Visual assets are placeholders; current UI is mostly native Godot controls with first-pass grounded Chinese MVP copy.
- Balance has not yet been tuned against the simulator output across many design passes.
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
