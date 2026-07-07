# AGENTS.md

This file is the live handoff guide for agents working on **这塘我包了**. Keep it current whenever implementation progress, architecture, balance assumptions, or verification steps change.

## Project Snapshot

- Engine: Godot 4.6.3, main scene `res://scenes/Main.tscn`.
- Game type: mobile-first fish pond contracting / risk decision game.
- Current stage: playable MVP logic is restored beneath a new `CanvasLayer/MainUI` and themed full-rect `UIRoot` shell. The homepage now has a game-first graybox hierarchy with a replaceable title sign, pond visual placeholder, and primary/secondary actions; the four routed gameplay scenes remain one-to-one with the original flow while their layouts are being modernized.
- UI copy pass completed for the first MVP loop: main menu, pond cards, inspection, contract confirmation, post-contract choices, transfer, one-net sale, work plans, and settlement now use clearer grounded Chinese business wording.
- Gameplay UI now follows one 1080 × 1920 hierarchy: global day/cash status at the top, page title below it, bounded or scrollable content in the middle, and visible actions that stay inside the authored canvas.
- Current README is minimal; treat this file as the primary working guide until README is expanded.
- The first P0 art batch is now wired into the homepage and pond list. `Main.tscn` uses `assets/background/bg_game.png`, `assets/ui/title_sign.png`, `assets/animations/fish_pond_spritesheet.png` (animated 24-frame 5×5 sheet via `SpriteSheetAnimator` at 12 FPS), and `assets/buttons/button_primary.png` / `button_secondary.png`. `scripts/pond_list.gd` uses per-type `assets/ponds/pond_card_bg_*.png` and `assets/ponds/pond_thumb_*.png`.
- The first P1 art batch is now wired into the post-contract choice page and settlement page. `scripts/after_contract_choice.gd` uses `assets/effects/net_method_*.png` for the three work-plan cards, `assets/effects/catch_result_visual.png` for the harvest-result modal banner, and `assets/decorations/buyer_transfer_placeholder.png` for the transfer-offer buyer avatar. `scripts/settlement.gd` uses `assets/effects/settlement_visual.png` as the scorecard header illustration.
- Fish-type icons from `assets/fish/fish_*.png` are now rendered inline next to each catch row in both the harvest-result modal and the final settlement scorecard.
- The P2 art batch is now wired into the remaining gameplay pages and popups. `scripts/pond_detail.gd` uses per-method `assets/ui/inspection_method_card_*.png` backgrounds and badge textures. `scripts/popup_manager.gd` uses `assets/ui/contract_dialog_bg.png` / `assets/ui/transfer_dialog_bg.png`, `assets/ui/balance_highlight_bg.png`, `assets/ui/status_box_bg.png`, and `assets/buttons/button_accept.png` / `button_danger_confirm.png`. `scripts/after_contract_choice.gd` uses `assets/ui/owned_pond_card_bg.png`, `action_card_bg.png`, `net_option_card_bg.png`, `transfer_dialog_bg.png`, `speech_bubble.png`, `offer_price_badge.png`, `status_box_bg.png`, `profit_loss_badge.png`, and `assets/ponds/owned_pond_visual.png`. `scripts/settlement.gd` uses `assets/ui/settlement_card_bg.png`, `profit_loss_badge.png`, and `assets/buttons/button_accept.png`. `scripts/settlement_history.gd` uses `assets/ui/record_header_bg.png`, `record_card_bg.png`, `balance_highlight_bg.png`, and `assets/buttons/button_accept.png`. `scripts/pond_list.gd` uses `assets/ui/price_badge.png` and `assets/buttons/pond_action_button.png`.
- All routed gameplay pages now have their P0/P1/P2 texture slots filled and the P2 nine-patch margins have been verified in 1080×1920, 720×1280, and 540×960.
- `tools/ui_flow_smoke_test.gd` has been updated to match the texture pass: old "self-drawn placeholder" assertions are replaced with texture-existence checks, the `find_child("NetOptionCard_*")` wildcard bug is fixed, and null guards are added around buttons/cards to prevent a single failure from crashing the whole run.
- Headless smoke test result: `UI_FLOW_TEST_OK`. All UI flow assertions pass. The only runtime warnings are sandbox-blocked writes to `user://save_game.json` and `user://settlement_history.json`, which do not affect UI validation.
- Asset compression pass completed: removed 3 unused images (`assets/ui/button_board.png`, `homepage.png`, `parchment_background.png`) and losslessly compressed all referenced PNGs. Total `assets/` reduction: ~5.3 MB (19.7 MB → 14.4 MB). All preload paths unchanged. Verified with `godot --headless --path . --quit`, `ui_flow_smoke_test.gd`, and `settlement_history_smoke_test.gd`.

## Current Implemented Flow

- `scripts/main.gd` starts on the designed homepage. The first button shows “开始包塘” without a checkpoint and “继续包塘” with one; “重新开始” clears it and creates a fresh run.
- The homepage uses `Background` as an independent full-screen `TextureRect` with `assets/background/bg_game.png`. `HomeScreen/SafeArea` divides the page into `TopArea`, `MainVisualArea`, and `BottomActionArea`; the title sign, pond visual, and primary/secondary buttons now use their P0 textures.
- `scripts/pond_placeholder.gd` is no longer attached to the homepage; `PondMainVisual` is a `TextureRect` driven by `SpriteSheetAnimator` using `assets/animations/fish_pond_spritesheet.png` (5×5 grid, 24 frames, 12 FPS).
- `UIRoot` fills the viewport, ignores mouse input, and applies `themes/UI_Theme.tres` for inherited styling.
- `UIRoot` runs `scripts/UI_Manager.gd` on ready to apply the shared theme recursively, remove selected per-control overrides, and add a 2 px black outline to every `Label`.
- `scripts/pond_list.gd` generates or reuses 3 ponds for the current day.
- `scripts/pond_detail.gd` presents inspection as three data-driven clue cards with P2 `assets/ui/inspection_method_card_*.png` backgrounds and `inspection_cost_badge.png` / `inspection_used_badge.png` labels, updates cash and cumulative inspection spend, separates each unlocked result into a conclusion and detail, and owns explicit give-up / contract confirmations rendered through `PopupManager`. After a confirmed contract, the popup closes, the game routes immediately to `AfterContractChoice`, and that new page plays a full-screen `ContractEntryDimOverlay` + `ContractEntryAnimationOverlay` (`assets/animations/contract_confirmation_spritesheet.png`, 5×5 grid, 24 frames, 12 FPS, non-looping) above the “塘已经包下” page before releasing actions.
- `scripts/after_contract_choice.gd` preserves transfer, one-net sale, and self-fishing/work-plan logic; its transfer offer modal uses P2 `assets/ui/transfer_dialog_bg.png`, `assets/ui/speech_bubble.png`, `assets/ui/offer_price_badge.png`, and the P1 `assets/decorations/buyer_transfer_placeholder.png` buyer avatar.
- `scripts/after_contract_choice.gd` also renders the one-net sale quote as a compact modal with P2 `assets/ui/transfer_dialog_bg.png` and `assets/ui/offer_price_badge.png`; accepting shows a success banner between the latest net result and action section.
- `scripts/after_contract_choice.gd` also owns the dedicated self-net decision page and one-net result modal. The owned-pond card uses `assets/ui/owned_pond_card_bg.png` and `assets/ponds/owned_pond_visual.png`; action cards use `assets/ui/action_card_bg.png`; the three net options use P2 `assets/ui/net_option_card_bg.png` plus P1 `assets/effects/net_method_*.png` textures, cost badges, consequence copy, and a separate confirmation for final drain settlement. When any net option is selected, a full-screen `FishingWorkDimOverlay` (60% black mask) + `FishingWorkAnimationOverlay` (`assets/animations/fishing_work_spritesheet.png`, 6×4 grid, 24 frames, 12 FPS, non-looping) plays on the current page before the result modal appears.
- `scripts/settlement.gd` renders the final pond scorecard dynamically from `GameState`: P1 `assets/effects/settlement_visual.png` header illustration, P2 `assets/ui/settlement_card_bg.png` section cards, `assets/ui/profit_loss_badge.png` profit/loss highlight, `assets/buttons/button_accept.png` next-day button, prominent final profit/loss, pond summary, income section with inline fish-type icons, expense section, and final ledger formula.
- `scripts/settlement_history.gd` renders the persistent ledger newest-first with day/cash status, P2 `assets/ui/balance_highlight_bg.png` summary bar, `assets/ui/record_header_bg.png` expandable headers, `assets/ui/record_card_bg.png` record bodies, and `assets/buttons/button_accept.png` bottom action.
- `scripts/pond_list.gd` generates or reuses 3 ponds for the current day, with per-type P0 pond card backgrounds/thumbnails, P2 `assets/ui/price_badge.png` quote badge, and `assets/buttons/pond_action_button.png` action button.

## Core Architecture

- `data/*.json` are the balance/source tables. Prefer adding tunable values here before hardcoding more constants in scripts.
- `data/balance_rules.json` owns detailed formula knobs for pond generation, inspection thresholds, fishing odds, market offers, and simulation presets.
- `scripts/data_loader.gd` is the shared JSON loader and path registry.
- `scripts/balance_rules.gd` is the shared helper for reading balance rule dictionaries.
- `scripts/game_state.gd` owns mutable run state, cash changes, round reset, contracting, settlement totals, and day advancement.
- `scripts/save_system.gd` owns `user://save_game.json` persistence and stores only safe pond-list checkpoints: day, cash, and the current day's stable pond offers.
- `scripts/save_system.gd` also owns the separate version-2 `user://settlement_history.json` ledger. It normalizes version-1 records, recalculates income/expense totals from canonical line items, and keeps completed history when restart clears the checkpoint. Settlement records are cached in-memory (`_settlement_records_cache` / `_settlement_records_cache_valid`) so opening the history page only reads the file on the first access or after a new record is written; subsequent calls return a deep copy from cache. `record_settlement()` refreshes the cache after a successful write, and `clear_settlement_history_cache()` is exposed for test/debug invalidation without touching the file.
- `scripts/ui_controller.gd` is the only screen router. Add new scene transitions here rather than scattering scene replacement logic.
- `scripts/pond_generator.gd` creates daily pond offers and hidden pond qualities.
- `scripts/inspection_system.gd` turns hidden pond values into fuzzy player-facing signals.
- `scripts/fishing_simulator.gd` resolves fishing results and fish income.
- `scripts/action_resolver.gd` resolves market opportunities after fishing.
- `scripts/balance_simulator.gd` runs headless multi-run strategy simulations for ROI, bankrupt rate, cash percentiles, and fish-king exposure.
- `scripts/popup_manager.gd` is registered as the `PopupManager` autoload. It owns the global layer-100 `CanvasLayer` popup base, full-screen `DimOverlay`, full-screen `ModalCenter`, centered `ConfirmContractDialog`, compact bill rows, status box, cancel/confirm buttons, and confirm-button debounce for global confirmation dialogs.
- `scripts/ui_kit.gd` owns the shared mobile-first UI frame: phone-safe panel margins, compact card/button/message styles, chips, and screen label roles.
- `scripts/ui_kit.gd` also owns the authored 1080 × 1920 design constants plus shared top-status, page-title, and modal-title styling.
- `scripts/ui_kit.gd` defines the shared information hierarchy: 24 px minimum readable text, 27 px body text, 31 px section text, 32 px highlighted values, and 44 px page titles on the 1080 × 1920 canvas.
- `scripts/ui_kit.gd` also owns the shared in-page modal layer: bounded paper cards, full-screen input-blocking masks, resize-safe centering, and scroll protection for oversized popup content.
- `scripts/pond_thumb_placeholder.gd` is no longer used by pond cards; `PondThumb` is a `TextureRect` using per-type `assets/ponds/pond_thumb_*.png`.
- `scenes/Main.tscn` is the active entry scene. Its `CanvasLayer/MainUI` root owns a full-rect themed `UIRoot`, while `UIRoot/GameRoot` retains the original homepage and `ScreenContainer` routing contract expected by `scripts/main.gd`.
- `scripts/UI_Manager.gd` is attached to `UIRoot` and enforces inherited theme usage plus the global `Label` outline pass when the entry scene becomes ready.
- `themes/UI_Theme.tres` uses `fonts/ZCOOL_KuaiLe/ZCOOLKuaiLe-Regular.ttf` as the global default font at 28 px; child controls inherit it unless a layout intentionally specifies a larger hierarchy role.
- `scripts/UI_Manager.gd` also watches controls added later by `UIController` or runtime card/modal construction, reapplies the shared theme, and removes legacy local color/style overrides without changing control logic.
- `scenes/PondList.tscn`, `scenes/PondDetail.tscn`, `scenes/AfterContractChoice.tscn`, and `scenes/Settlement.tscn` preserve their original script node contracts but now use container-driven 1080 × 1920 layouts instead of absolute-position page content.
- `tools/balance-lab/` is a static local web tuning console for adjusting `data/balance_rules.json` knobs and running browser-side simulations.
- `scenes/*.tscn` hold the screen layouts. Keep node paths aligned with each script's `@onready` references.

## Important Gameplay Invariants

- Each day should offer 3 ponds.
- Daily ponds should remain stable while the player views/backtracks within the same day.
- The hidden value profile intentionally includes one surplus, one break-even, and one loss pond per day.
- Inspection should narrow uncertainty, not reveal exact hidden values.
- Each inspection tool can be used once per pond round.
- Paid inspection spend is not refunded when the player gives up the pond; giving up after paid inspection requires confirmation.
- Contracting deducts the pond quote immediately.
- The player cannot contract if the remaining cash would be below `min_working_capital`.
- Work plans must require available cash before applying harvest results.
- Full/drain work cost is dynamic: `max(2000, current pond quote_price * 20%)`.
- Non-final self-fishing results use a blocking text/result popup; underlying actions remain blocked until it is dismissed.
- Final settlement preserves bankrupt, fish-king, profit/loss titles and details without loading result illustrations during the layout-only pass.
- `full` / `drain` is final and should go to settlement.
- `low` and `standard` can be repeated while cash allows.
- Selling one net can happen at most once per round.
- The post-contract player-facing choices should not include an abandon / "认亏走人" option; use transfer as the exit path.
- The post-contract choice page is now the “已承包鱼塘管理页”: top status shows day/cash, the header reads “塘已经包下”, the compact owned-pond card shows pond name plus current total invested, revenue, and profit/loss, while detailed ledger rows live in the folded ledger section below actions.
- On the post-contract management page, use calculated ledger variables from `GameState` rather than vague copy such as “塘口账面”; current total invested is contract total cost + inspection spend + work cost + transport cost, and current profit/loss is revenue - total invested.
- On the post-contract management page, “继续下网/自己下网”, “转包脱手”, and “卖一网” are ActionCards with title, consequence copy, status, and button; continuing to net is the primary action, transfer is secondary stop-loss, and “卖一网” stays disabled with “暂无买家” until fish-result data creates an offer.
- The transfer offer popup must compute its bill from state variables: current cash, contract total cost, inspection spend, work cost, transport cost, revenue, and offer price. It shows current total invested, offer price, transfer profit/loss with status text, and cash after accepting; the accept button states the gain/loss and loss-making transfers require a second confirmation.
- Choosing "自己下网" opens a dedicated net-method decision page: the original transfer/sell/self-fishing buttons are hidden, the three work plans appear as scrollable cards with self-drawn method placeholders, and the return control stays fixed below the list.
- Final settlement net profit includes every income and cost for the pond: fish sales, one-net sale, transfer income, contract fee, inspection costs, and work costs. The contract fee, inspection fee, and work cost are paid when they happen; settlement only displays and records the final ledger, so costs are not deducted twice.
- Entering a final settlement records it once with a record ID, local settlement time, pond/day/method, catch details, canonical income/cost line items, calculated totals/net profit, and ending cash.
- “今日鱼塘” exposes “包塘记录” at the upper right; the history page supports empty and populated states, summarizes total ponds/cumulative profit/current cash, and expands/collapses full settlement details per record.
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
  - `fish_finder`: 650 (mid-tier info tool; gap from master widened by noisier selection to reward skill investment)
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
  - Latest 1000×12 balance pass (seed 20260619): strategy gap widened — master is clearly the best path, mid-tier info play is near break-even, no-info play bleeds.
    - `random_no_inspection`: ~-78% avg ROI, ~67% bankrupt rate (punishing baseline)
    - `basic_stop_loss`: ~-16% avg ROI, 0% bankrupt rate (slow defensive bleed for no-info play)
    - `fish_finder_estimate_stop_loss` (mid-tier probe): ~-5% avg ROI, ~25% bankrupt rate, near break-even with wider variance
    - `master_estimate_stop_loss`: ~+15% avg ROI, ~29% bankrupt rate, top-skill path (p75 final cash ~56k)
  - Design intent: skill investment pays off clearly; master is the growth engine, fish_finder is a safety net, basic/random punish neglect of information.
  - Key tuning levers in this pass:
    - `data/balance_rules.json` `market.one_net.estimated_value_ratio`: 0.115 → 0.12 (pushes master into clear +EV territory while keeping no-info play negative)
    - `data/balance_rules.json` `fish_finder_estimate_stop_loss` noise: widened to 0.60–1.40 to pull mid-tier away from master
    - `data/tools.json` `fish_finder.cost`: 650 (unchanged from prior pass)

## Development Rules

- Use GDScript and the existing Godot UI structure unless there is a clear reason to change direction.
- Preserve Chinese player-facing copy unless intentionally revising UX tone.
- Do not edit `.uid` files by hand.
- Do not commit `.godot/`, `.DS_Store`, or generated platform exports.
- When changing a scene script, check the matching `.tscn` node paths before renaming nodes.
- Prefer reusing `FishPoolUIKit` / `scripts/ui_kit.gd` for panel, card, button, chip, and label styling before adding one-off scene styles.
- Keep screen layouts mobile-first: narrow safe margins, scroll long content, short card copy, and large bottom-priority touch targets.
- Treat 1080 × 1920 as the authored UI canvas; align dynamic card text to painted artwork at that logical resolution and let Godot scale the canvas for devices.
- Keep every routed gameplay page in this order: global run status, page title outside the framed card, page-specific card content, then operable actions. Keep every custom popup in this order: title, highlighted decision/result summary when applicable, bounded/scrollable body, then operable actions.
- Use shared label roles instead of one-off typography. Important prices, estimates, and profit/loss values use `style_highlight_label`; supporting copy uses the secondary text role. Do not render player-facing text below `FishPoolUIKit.FONT_MIN`.
- Use `primary` for the decisive action, `secondary` for normal in-flow choices, and `ghost` for back/cancel/decline actions so secondary operations remain visibly distinct without leaving the paper-and-ink visual language.
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

Automated full-flow smoke test:

```bash
HOME=/private/tmp/fish_pool_test_home godot --headless --log-file /private/tmp/fish_pool_ui_flow_smoke.log --path . --script res://tools/ui_flow_smoke_test.gd
```

Settlement-history persistence and foldout test:

```bash
HOME=/private/tmp/fish_pool_history_test_home godot --headless --log-file /private/tmp/fish_pool_history_smoke.log --path . --script res://tools/settlement_history_smoke_test.gd
```

- Homepage loads P0 textures: `assets/background/bg_game.png` as the full-screen background, `assets/ui/title_sign.png` behind the title label, `assets/ui/pond_main_visual.png` in the main visual area, and `assets/buttons/button_primary.png` / `button_secondary.png` for the action buttons.
- Homepage text remains rendered by Godot labels; verify title/subtitle/button text is readable over the new artwork at 540 × 960, 720 × 1280, and 1080 × 1920.
- “开始包塘” / “继续包塘” restores saved day/cash/pond offers when a checkpoint exists and otherwise starts fresh.
- “重新开始” clears the old checkpoint and starts from configured initial cash/day.
- Pond list shows 3 ponds.
- Pond list uses native themed controls only, with separate day/cash values and “包塘记录” inside a game-status bar, followed by the “今日鱼塘” decision header and guidance copy.
- Pond cards use per-type `assets/ponds/pond_card_bg_*.png` as a full-card background and per-type `assets/ponds/pond_thumb_*.png` as the left thumbnail; the price badge and action button remain native themed controls for now.
- Every pond card uses the same generated component structure: thumbnail texture, pond name and price badge, three compact tags, a three-column stat grid, rumor copy, and one full-width primary action.
- Verify each pond type maps to the correct card background and thumbnail, and that text remains readable over the new backgrounds at all target resolutions.
- If a pond quote exceeds current cash, its price badge switches to warning styling and its disabled action reads “钱不够”.
- At the 1080 × 1920 design resolution, each pond card is 500 logical pixels tall; a bottom spacer keeps the last card from ending hard against the scroll boundary.
- Pond detail uses native themed cards and buttons with no hand-drawn textures.
- Pond detail uses a fixed bottom decision bar and one scrollable content column containing a pond summary card, three clue-purchase cards, and a contract-cost summary; no external texture is loaded.
- Pond detail top status shows day, current cash, and cumulative inspection spend; paid inspection updates both cash and spend immediately without allowing a second charge.
- Unused inspection cards show method, price, short purpose, and a clue-purchase action; used cards switch to a readable beige state with an `已验` badge plus a prominent conclusion and supporting detail.
- Pond detail decision summary shows inspection spend, contract price, post-contract cash, and the need to reserve fishing, draining, fish-truck, and transport costs.
- Pond detail bottom actions read `放弃此塘` and `承包 XXXX 元`; paid give-up and all contract actions use the global `PopupManager.show_confirm(...)` blocking confirmation dialog.
- At 1080 × 1920, pond detail uses 52 px safe horizontal margins with separate top-status, page-header, scrollable-content, and fixed bottom-decision zones.
- Pond detail, post-contract choice/work-plan, and settlement titles sit outside their framed cards between the global status and page content; pond names and result details remain inside the card.
- Each inspection result appears only inside its matching clue card; the full content column scrolls so expanded results cannot cover the fixed bottom decisions.
- Backtracking from pond detail preserves the same day's ponds.
- Each inspection tool deducts the expected cash and cannot be reused.
- Contract confirmation is a compact native themed bill dialog: current cash, non-refundable inspection spend, negative pond price, optional contract extra cost, total contract deduction, remaining cash, and minimum working capital are all rendered from `GameState.get_contract_preview()` plus `inspection_cost_total`.
- `GameState.get_contract_preview()` is the source of truth for `contract_extra_cost`, `contract_total_cost`, `remaining_after_contract`, `min_working_capital`, `recommended_working_capital`, and the confirm button deduction text; final contract mutation deducts `contract_total_cost`.
- Contract confirmation blocks insufficient remaining working capital, disables the primary confirm button as `钱不够`, and rechecks funds on accept before mutating state.
- Contract confirmation uses the global `PopupManager` CanvasLayer at layer 100, a full-screen input-blocking `DimOverlay`, and a full-screen `ModalCenter` that centers the native themed `ConfirmContractDialog` independently of page content.
- All confirmation popups use an opaque-input modal overlay with a dark mask; popup cards remain inside a 24 px viewport safe area and oversized body content scrolls instead of expanding the card.
- Contract and transfer popups both visibly retain title, highlighted decision value, scroll-safe content, and accept/cancel actions at 1080 × 1920; the harvest-result popup lists the catch by fish type with weight, unit price, subtotal, and total fish income, then highlights per-net profit/loss above its dismiss action.
- Pond detail, post-contract choice/work-plan, and settlement use the same native framed page card with no large paper-sticker texture.
- “自己下网” switches to a dedicated page state with a mini owned-pond ledger and three scrollable net-option cards; “返回处置选择” remains fixed at the bottom and the original choice buttons must not remain visible.
- The default post-contract management page shows the compact OwnedPondCard first, then LatestNetResultCard when at least one non-final net has been collected, then ActionSection, then LedgerAccordion.
- After the first self-fishing result, the post-contract page prioritizes latest-net summary before operations: method, fish income, work cost, and this-net profit/loss. The cumulative “塘口累计账” stays in LedgerAccordion below ActionSection, defaults collapsed, and remains expanded only after the player manually opens it.
- After a successful “卖一网”, the post-contract page hides the sell-one-net action card, shows `SellOneNetResultBanner` below `LatestNetResultCard`, and explains current revenue as fish income plus one-net income when both are present.
- “转包脱手” first opens a global confirmation dialog, then the centered responsive native offer popup; “自己下网” first opens a global cost confirmation dialog, then the work-plan page.
- After contracting, low/standard/full work buttons reflect available cash.
- Non-final harvest can create market opportunities and continue the round.
- Full harvest or transfer reaches settlement.
- "下一地方" advances the internal day counter, resets round-only state, and generates new ponds.
- Fish-king result displays the special panel without breaking settlement totals.
- Non-final self-fishing results show a blocking text/result popup until dismissed.
- Settlement shows the correct bankrupt / fish-king / profit / loss state without illustration textures, and the scorecard separates summary, income, expense, and final ledger sections.
- Every settlement route, including transfer, shows one final pond scorecard with fish income by type, other income, all costs, total income, total cost, net result, and ending cash.
- Final settlement writes one persistent history record; “包塘记录” keeps it across restart, recomputes every displayed total from ledger line items, and remains scroll-safe at 540 × 960, 720 × 1280, and 1080 × 1920.
- The automated full-flow smoke test checks the one-net sale quote modal, self-adaptive modal height, cash-after-accept copy, success banner, revenue-source breakdown, and hidden sold-state action card.

## Lightweight Animation System

- `scripts/ui_kit.gd` owns shared Tween helpers: `animate_page_entry`, `apply_button_click_feedback`, `animate_emphasis`, `animate_pop_in`, `animate_shine`, `spawn_sparkles`.
- `FishPoolUIKit.animations_enabled` is a static bool that auto-disables in headless mode (`DisplayServer.get_name() == "headless"`); no manual toggling needed for tests.
- Button click feedback is applied automatically by `scripts/UI_Manager.gd` via `apply_button_click_feedback` in its recursive theme pass; every `Button` inside `UIRoot` gets a 0.05s scale-down + 0.12s bounce-back on press.
- Page transitions: `scripts/ui_controller.gd` calls `animate_page_entry` after instantiation — 48 px rightward slide + alpha 0→1 over 0.18 s, no crossfade.
- Settlement emphasis: `scripts/settlement.gd` scales the final `profit_highlight_label` 1.08×→1.0 bonus bounce; `spawn_sparkles` fires 28 gold/green/red one-shot `CPUParticles2D` around the profit header or fish-king panel.
- Harvest result modal: `scripts/after_contract_choice.gd` emphasis-bounces the title and fires sparkles around `CatchVisual` (fish king) or `harvest_result_label` (standard) when the modal opens.
- Sell-one-net success banner: `_set_banner_visible` applies `animate_pop_in` (scale 0.92→1 + alpha fade) and a brief modulate shine on the banner title.
- Transfer accept: a fire-and-forget `animate_shine` on the offer-highlight label before closing the dialog and transitioning to settlement.
- All animations are fire-and-forget or deferred; no `await` blocks the core game loop. In headless all helpers return null / skip immediately.

## Known Gaps / Next Likely Work

- README still needs a real product/game overview.
- A deterministic balance simulator exists, but its strategies are first-pass proxies and need more design review before tuning against them.
- Save/load currently covers safe pond-list checkpoints only; active mid-round state is not resumed.
- No meta progression, tutorial, or end condition exists yet.
- First P0 art batch is integrated; remaining screens (pond detail, post-contract choice, settlement, history) still use native themed controls and await their art pass.
- Balance has received a third simulator-tuned pass: master ~+15% and fish_finder ~-5% create a clear skill gradient; no-info play still bleeds; no strategy is a stable farm due to bankruptcy risk.
- The simulator's strategy selection uses a noisy hidden-value ratio rather than modeling real inspection accuracy; `tools.json` accuracy values are not yet consumed by `inspection_system.gd` or the simulator. When accuracy is wired in, re-verify that master stays ahead of fish_finder and neither becomes a farm.
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
