const CONTROL_GROUPS = [
  {
    title: "鱼塘生成",
    controls: [
      ["报价低档最小", "pond_generation.quote_tiers.quarter.ratio_min", 0.1, 0.5, 0.01],
      ["报价低档最大", "pond_generation.quote_tiers.quarter.ratio_max", 0.1, 0.5, 0.01],
      ["报价高档最小", "pond_generation.quote_tiers.high.ratio_min", 0.4, 1.2, 0.01],
      ["报价高档最大", "pond_generation.quote_tiers.high.ratio_max", 0.4, 1.2, 0.01],
      ["赚塘价值倍率下限", "pond_generation.value_profiles.surplus.hidden_value_factor.0", 0.8, 2.0, 0.01],
      ["亏塘价值倍率上限", "pond_generation.value_profiles.loss.hidden_value_factor.1", 0.3, 1.2, 0.01],
      ["鱼王价值权重", "pond_generation.hidden_value.fish_king_weight", 1000, 18000, 250]
    ]
  },
  {
    title: "验塘与老师傅",
    controls: [
      ["大鱼高信号阈值", "inspection.big_thresholds.high", 0.2, 0.7, 0.01],
      ["鱼王强信号阈值", "inspection.king_thresholds.strong", 0.05, 0.3, 0.01],
      ["便宜阈值", "inspection.price_thresholds.cheap", 0.6, 1.1, 0.01],
      ["偏贵阈值", "inspection.price_thresholds.expensive", 0.9, 1.5, 0.01],
      ["老师傅中心误差下限", "inspection.master_value_estimate.center_min", 0.5, 1.0, 0.01],
      ["老师傅中心误差上限", "inspection.master_value_estimate.center_max", 1.0, 1.6, 0.01],
      ["老师傅策略选塘噪声下限", "simulation.strategies.master_estimate_stop_loss.selection_noise_min", 0.5, 1.0, 0.01],
      ["老师傅策略选塘噪声上限", "simulation.strategies.master_estimate_stop_loss.selection_noise_max", 1.0, 1.8, 0.01]
    ]
  },
  {
    title: "捕鱼",
    controls: [
      ["省着下网强度", "fishing.plan_power.low", -0.8, 0.3, 0.01],
      ["正常作业强度", "fishing.plan_power.standard", -0.3, 0.5, 0.01],
      ["抽干强度", "fishing.plan_power.full", 0.0, 1.2, 0.01],
      ["省着下网规模", "fishing.plan_catch_scale.low", 0.3, 1.2, 0.01],
      ["抽干规模", "fishing.plan_catch_scale.full", 0.8, 3.0, 0.01],
      ["基础小鱼权重", "fishing.base_weights.small_fish", 10, 80, 1],
      ["基础鱼王权重", "fishing.base_weights.fish_king", 0.1, 12, 0.1],
      ["鱼王最小重量", "fishing.weights.fish_king.min", 10, 120, 1],
      ["鱼王最大重量", "fishing.weights.fish_king.max", 60, 260, 1]
    ]
  },
  {
    title: "市场机会",
    controls: [
      ["转包折价下限", "market.transfer.value_lerp_min", 0.4, 1.2, 0.01],
      ["转包溢价上限", "market.transfer.value_lerp_max", 0.7, 1.8, 0.01],
      ["转包随机下限", "market.transfer.random_min", 0.4, 1.0, 0.01],
      ["转包随机上限", "market.transfer.random_max", 1.0, 1.8, 0.01],
      ["一网承包价占比下限", "market.one_net.quote_ratio_min", 0.02, 0.4, 0.01],
      ["一网承包价占比上限", "market.one_net.quote_ratio_max", 0.05, 0.6, 0.01],
      ["转包基础概率", "market.opportunities.transfer_base", 0.0, 0.8, 0.01],
      ["卖一网基础概率", "market.opportunities.one_net_base", 0.0, 0.8, 0.01]
    ]
  }
];

const fishTypes = [
  { id: "small_fish", name: "小鱼", min_value: 10, max_value: 10 },
  { id: "normal_fish", name: "普通鱼", min_value: 15, max_value: 15 },
  { id: "big_fish", name: "大鱼", min_value: 20, max_value: 20 },
  { id: "fish_king", name: "鱼王", min_value: 100, max_value: 100 }
];

const pondTypes = [
  { id: "artificial_pond", name: "人工塘", big_fish_modifier: 0.9, fish_king_modifier: 0.7, difficulty_modifier: 0.8 },
  { id: "old_pond", name: "老塘", big_fish_modifier: 1.2, fish_king_modifier: 1.1, difficulty_modifier: 1.1 },
  { id: "reservoir_pond", name: "水库塘", big_fish_modifier: 1.4, fish_king_modifier: 1.5, difficulty_modifier: 1.3 }
];

const gameBalance = {
  initial_cash: 10000,
  min_working_capital: 1000,
  ponds_per_day: 3,
  low_work_cost: 500,
  standard_work_cost: 1200,
  full_work_min_cost: 2000,
  full_work_quote_ratio: 0.2
};

let defaultRules;
let rules;

const controlsEl = document.querySelector("#controls");
const rowsEl = document.querySelector("#resultRows");
const jsonOutput = document.querySelector("#jsonOutput");
const statusText = document.querySelector("#statusText");
const canvas = document.querySelector("#cashChart");
const chart = canvas.getContext("2d");

init();

async function init() {
  defaultRules = await fetch("../../data/balance_rules.json").then((res) => res.json());
  rules = clone(defaultRules);
  buildControls();
  runSimulation();
  document.querySelector("#runButton").addEventListener("click", runSimulation);
  document.querySelector("#resetButton").addEventListener("click", () => {
    rules = clone(defaultRules);
    buildControls();
    runSimulation();
  });
  document.querySelector("#exportButton").addEventListener("click", () => {
    jsonOutput.value = JSON.stringify(rules, null, 2);
    jsonOutput.focus();
  });
  document.querySelector("#copyButton").addEventListener("click", async () => {
    jsonOutput.value = JSON.stringify(rules, null, 2);
    await navigator.clipboard.writeText(jsonOutput.value);
    statusText.textContent = "已复制";
  });
}

function buildControls() {
  controlsEl.innerHTML = "";
  CONTROL_GROUPS.forEach((group) => {
    const section = document.createElement("section");
    section.className = "control-group";
    section.innerHTML = `<h2>${group.title}</h2>`;
    group.controls.forEach(([label, path, min, max, step]) => {
      const row = document.createElement("div");
      row.className = "slider-row";
      const value = Number(getPath(rules, path));
      row.innerHTML = `
        <label>${label}<input type="range" min="${min}" max="${max}" step="${step}" value="${value}" data-path="${path}"></label>
        <input type="number" min="${min}" max="${max}" step="${step}" value="${formatValue(value)}" data-path="${path}">
      `;
      row.querySelectorAll("input").forEach((input) => {
        input.addEventListener("input", (event) => {
          const next = Number(event.target.value);
          setPath(rules, path, next);
          row.querySelectorAll("input").forEach((peer) => {
            if (peer !== event.target) peer.value = event.target.value;
          });
          scheduleRun();
        });
      });
      section.appendChild(row);
    });
    controlsEl.appendChild(section);
  });
  jsonOutput.value = JSON.stringify(rules, null, 2);
}

let runTimer = null;
function scheduleRun() {
  clearTimeout(runTimer);
  statusText.textContent = "参数已改";
  runTimer = setTimeout(runSimulation, 220);
}

function runSimulation() {
  const runs = readNumber("#runsInput");
  const maxDays = readNumber("#daysInput");
  const seed = readNumber("#seedInput");
  statusText.textContent = "计算中";
  const strategies = rules.simulation.strategies;
  const summaries = Object.keys(strategies).map((name) => simulateStrategy(name, strategies[name], runs, maxDays, seed));
  renderResults(summaries);
  jsonOutput.value = JSON.stringify(rules, null, 2);
  statusText.textContent = "已更新";
}

function simulateStrategy(name, strategy, runs, maxDays, seed) {
  const rois = [];
  const cashValues = [];
  const daysValues = [];
  let bankrupt = 0;
  let fishKingRuns = 0;
  for (let i = 0; i < runs; i += 1) {
    const result = simulateRun(strategy, maxDays, seed + i * 7919);
    const finalCash = result.finalCash;
    cashValues.push(finalCash);
    daysValues.push(result.survivedDays);
    rois.push((finalCash - gameBalance.initial_cash) / gameBalance.initial_cash);
    if (result.survivedDays < maxDays) bankrupt += 1;
    if (result.hadFishKing) fishKingRuns += 1;
  }
  rois.sort((a, b) => a - b);
  cashValues.sort((a, b) => a - b);
  return {
    name,
    avgRoi: average(rois),
    medianRoi: percentile(rois, 0.5),
    p25: percentile(cashValues, 0.25),
    p50: percentile(cashValues, 0.5),
    p75: percentile(cashValues, 0.75),
    bankruptRate: bankrupt / runs,
    avgDays: average(daysValues),
    fishKingRate: fishKingRuns / runs,
    cashValues
  };
}

function simulateRun(strategy, maxDays, seed) {
  const state = makeState();
  let hadFishKing = false;
  let survivedDays = 0;
  for (let day = 1; day <= maxDays; day += 1) {
    const pondRng = makeRng(seed + day * 101);
    const resolverRng = makeRng(seed + day * 313);
    const ponds = generateDailyPonds(day, state.cash, pondRng);
    const inspectionCost = strategy.inspection_cost || 0;
    if (inspectionCost > 0 && !pay(state, inspectionCost)) break;
    const pond = selectPond(strategy, ponds.filter((item) => canContract(state, item)), seed + day * 577);
    if (!pond || !contract(state, pond)) break;
    playRound(strategy, state, resolverRng);
    hadFishKing = hadFishKing || state.catchDetails.some((item) => item.id === "fish_king" && item.weight_jin > 0);
    survivedDays = day;
    resetRound(state);
  }
  return { finalCash: state.cash, survivedDays, hadFishKing };
}

function generateDailyPonds(day, cash, rng) {
  const profiles = shuffle(["surplus", "break_even", "loss"], rng);
  const tiers = ["quarter", "half", "high"];
  return Array.from({ length: gameBalance.ponds_per_day }, (_, index) => generatePond(day, index, profiles[index % profiles.length], tiers[Math.min(index, tiers.length - 1)], cash, rng));
}

function generatePond(day, index, valueProfile, quoteTier, cash, rng) {
  const type = pick(pondTypes, rng);
  const physical = generatePhysicalProfile(type.id, quoteTier, rng);
  const pg = rules.pond_generation;
  const ageFactor = clamp(physical.age_years / pg.age_factor_divisor, pg.factor_min, pg.factor_max);
  const profile = getValueProfile(valueProfile, rng);
  const difficultyRule = pg.difficulty;
  const bigRule = pg.big_fish_chance;
  const kingRule = pg.fish_king_chance;
  const difficulty = round2((type.difficulty_modifier + ageFactor * difficultyRule.age_weight + physical.depth_factor * difficultyRule.depth_weight + randRange(rng, difficultyRule.random_min, difficultyRule.random_max)) * profile.difficulty_factor);
  const big = round2(clamp((bigRule.base + ageFactor * bigRule.age_weight + physical.value_factor * bigRule.physical_weight + type.big_fish_modifier * bigRule.type_weight) * profile.big_fish_factor, bigRule.min, bigRule.max));
  const king = round2(clamp((kingRule.base + ageFactor * kingRule.age_weight + physical.depth_factor * kingRule.depth_weight + type.fish_king_modifier * kingRule.type_weight) * profile.fish_king_factor, kingRule.min, kingRule.max));
  const hidden = calculateHiddenValue(type.id, physical.age_years, big, king, profile.hidden_value_factor * physical.value_factor, rng);
  const quote = calculateQuote(cash, quoteTier, physical.value_factor, rng);
  return {
    id: `day_${day}_pond_${index + 1}`,
    pond_type: type.id,
    value_profile: valueProfile,
    quote_tier: quoteTier,
    age_years: physical.age_years,
    quote_price: quote,
    hidden_value: hidden,
    big_fish_chance: big,
    fish_king_chance: king,
    difficulty
  };
}

function generatePhysicalProfile(typeId, quoteTier, rng) {
  const pg = rules.pond_generation;
  const tier = pg.quote_tiers[quoteTier] || pg.quote_tiers.default;
  const area = pick(tier.area_labels, rng);
  const depth = randRange(rng, tier.depth_min, tier.depth_max);
  const age = clampInt(generateAge(typeId, rng), tier.age_min, tier.age_max);
  const depthRule = pg.depth_factor;
  const depthFactor = clamp((depth - depthRule.offset) / depthRule.divisor, depthRule.min, depthRule.max);
  const ageFactor = clamp(age / pg.age_factor_divisor, pg.factor_min, pg.factor_max);
  const physicalRule = pg.physical_value_factor;
  const areaFactor = pg.area_factors[area] ?? pg.area_factors["中塘"];
  const valueFactor = clamp(physicalRule.base + areaFactor * physicalRule.area_weight + depthFactor * physicalRule.depth_weight + ageFactor * physicalRule.age_weight, physicalRule.min, physicalRule.max);
  return { age_years: age, depth_factor: depthFactor, value_factor: valueFactor };
}

function generateAge(typeId, rng) {
  const ranges = rules.pond_generation.age_ranges_by_type;
  const pair = ranges[typeId] || ranges.default;
  return randInt(rng, pair[0], pair[1]);
}

function getValueProfile(valueProfile, rng) {
  const profile = rules.pond_generation.value_profiles[valueProfile];
  return {
    hidden_value_factor: randRange(rng, profile.hidden_value_factor[0], profile.hidden_value_factor[1]),
    difficulty_factor: randRange(rng, profile.difficulty_factor[0], profile.difficulty_factor[1]),
    big_fish_factor: randRange(rng, profile.big_fish_factor[0], profile.big_fish_factor[1]),
    fish_king_factor: randRange(rng, profile.fish_king_factor[0], profile.fish_king_factor[1])
  };
}

function calculateHiddenValue(typeId, age, big, king, profileFactor, rng) {
  const h = rules.pond_generation.hidden_value;
  const bonusPair = h.type_bonus[typeId] || h.type_bonus.default;
  const base = randInt(rng, h.base_min, h.base_max);
  const typeBonus = randInt(rng, bonusPair[0], bonusPair[1]);
  const chanceBonus = Math.floor(big * h.big_fish_weight + king * h.fish_king_weight);
  const ageBonus = age * randInt(rng, h.age_bonus_min, h.age_bonus_max);
  return Math.max(h.min, Math.floor((base + typeBonus + chanceBonus + ageBonus) * profileFactor));
}

function calculateQuote(cash, quoteTier, physicalFactor, rng) {
  const pg = rules.pond_generation;
  const tier = pg.quote_tiers[quoteTier] || pg.quote_tiers.default;
  const ratio = randRange(rng, tier.ratio_min, tier.ratio_max);
  let adjusted = ratio * clamp(physicalFactor, pg.quote_physical_factor_min, pg.quote_physical_factor_max);
  adjusted = clamp(adjusted, tier.adjusted_min, tier.adjusted_max);
  const quote = Math.round((cash * adjusted) / pg.quote_rounding) * pg.quote_rounding;
  if (cash < pg.min_quote) return cash;
  return clampInt(Math.max(pg.min_quote, quote), pg.min_quote, cash);
}

function playRound(strategy, state, rng) {
  for (const planId of strategy.plans) {
    const cost = getWorkCost(state, planId);
    if (!pay(state, cost)) return;
    const result = generateHarvestResult(state.currentPond, planId, cost, rng);
    applyHarvest(state, result, cost);
    if (result.is_final) return;
    const opportunities = generateOpportunities(state.currentPond, result, rng);
    if (opportunities.transfer_offer && result.quality <= strategy.accept_transfer_quality_below) {
      state.transferIncome = opportunities.transfer_offer.income;
      state.cash += opportunities.transfer_offer.income;
      return;
    }
    if (strategy.accept_one_net && opportunities.one_net_offer && !state.soldOneNet) {
      state.soldOneNet = true;
      state.oneNetIncome = opportunities.one_net_offer.income;
      state.cash += opportunities.one_net_offer.income;
    }
  }
}

function generateHarvestResult(pond, planId, workCost, rng) {
  const mainFish = rollFishType(pond, planId, rng);
  const catchDetails = generateCatchDetails(pond, planId, mainFish.id, rng);
  const fishIncome = catchDetails.reduce((sum, item) => sum + item.income, 0);
  return {
    work_cost: workCost,
    fish_income: fishIncome,
    catch_details: catchDetails,
    is_final: planId === "drain" || planId === "full",
    quality: getQuality(mainFish.id, fishIncome, workCost),
    fish_result_id: mainFish.id
  };
}

function rollFishType(pond, planId, rng) {
  const f = rules.fishing;
  const difficulty = Math.max(pond.difficulty, f.min_difficulty);
  const power = f.result_power;
  const planPower = f.plan_power[planId] ?? f.plan_power.default;
  const bigBonus = clamp(pond.big_fish_chance - power.big_chance_baseline, power.big_bonus_min, power.big_bonus_max);
  const kingBonus = clamp(pond.fish_king_chance - power.king_chance_baseline, power.king_bonus_min, power.king_bonus_max);
  const difficultyPenalty = clamp((difficulty - power.difficulty_baseline) * power.difficulty_weight, power.difficulty_penalty_min, power.difficulty_penalty_max);
  const resultPower = planPower + bigBonus + kingBonus - difficultyPenalty;
  const weights = clone(f.base_weights);
  if (resultPower >= 0) {
    for (const [id, rule] of Object.entries(f.positive_weight_adjustments)) {
      let next = weights[id] + resultPower * rule.delta;
      if ("min" in rule) next = Math.max(rule.min, next);
      if ("max" in rule) next = Math.min(rule.max, next);
      weights[id] = next;
    }
  } else {
    const badPower = Math.abs(resultPower);
    for (const [id, rule] of Object.entries(f.negative_weight_adjustments)) {
      let next = weights[id] + badPower * rule.delta;
      if ("min" in rule) next = Math.max(rule.min, next);
      if ("max" in rule) next = Math.min(rule.max, next);
      weights[id] = next;
    }
  }
  return pickWeighted(fishTypes, weights, rng);
}

function generateCatchDetails(pond, planId, mainFishId, rng) {
  const f = rules.fishing;
  const difficultyRule = f.difficulty_scale;
  const difficulty = Math.max(pond.difficulty, f.min_difficulty);
  const difficultyScale = clamp(difficultyRule.base - (difficulty - difficultyRule.difficulty_baseline) * difficultyRule.difficulty_weight, difficultyRule.min, difficultyRule.max);
  const catchScale = (f.plan_catch_scale[planId] ?? f.plan_catch_scale.default) * difficultyScale;
  return fishTypes.map((fish) => {
    const weight = rollWeight(fish.id, mainFishId, catchScale, rng);
    let unitPrice = randInt(rng, fish.min_value, fish.max_value);
    if (fish.id === "fish_king" && weight > 0) {
      const integrity = randInt(rng, f.fish_king_integrity.min, f.fish_king_integrity.max);
      if (integrity < f.fish_king_integrity.premium_threshold) unitPrice = 20;
    }
    return { id: fish.id, weight_jin: weight, unit_price: unitPrice, income: weight * unitPrice };
  });
}

function rollWeight(fishId, mainFishId, scale, rng) {
  const w = rules.fishing.weights[fishId];
  let weight = 0;
  if (fishId === "small_fish") {
    weight = randRange(rng, w.min, w.max) * scale;
    if (mainFishId === "small_fish") weight *= randRange(rng, w.main_multiplier_min, w.main_multiplier_max);
  }
  if (fishId === "normal_fish" && (["normal_fish", "big_fish", "fish_king"].includes(mainFishId) || rng() <= w.extra_chance)) {
    weight = randRange(rng, w.min, w.max) * scale;
  }
  if (fishId === "big_fish") {
    if (["big_fish", "fish_king"].includes(mainFishId)) weight = randRange(rng, w.min, w.max) * scale;
    else if (rng() <= w.extra_chance) weight = randRange(rng, w.extra_min, w.extra_max) * scale;
  }
  if (fishId === "fish_king" && mainFishId === "fish_king") weight = randInt(rng, w.min, w.max);
  return snapWeight(weight, w.unit);
}

function generateOpportunities(pond, result, rng) {
  const m = rules.market;
  const o = m.opportunities;
  let transferChance = clamp(o.transfer_base + result.quality * o.transfer_quality_weight, o.transfer_min, o.transfer_max);
  let oneNetChance = clamp(o.one_net_base + result.quality * o.one_net_quality_weight, o.one_net_min, o.one_net_max);
  if (result.quality < o.bad_quality_threshold) {
    transferChance = clamp(transferChance + o.bad_transfer_bonus, o.bad_transfer_min, o.bad_transfer_max);
    oneNetChance *= o.bad_one_net_multiplier;
  }
  return {
    transfer_offer: rng() <= transferChance ? generateTransfer(pond, result, rng) : null,
    one_net_offer: rng() <= oneNetChance ? generateOneNet(pond, result, rng) : null
  };
}

function generateTransfer(pond, result, rng) {
  const t = rules.market.transfer;
  const valueFactor = clamp(pond.hidden_value / Math.max(pond.quote_price, 1), t.value_factor_min, t.value_factor_max);
  const resultFactor = clamp(1 + result.quality * t.quality_weight, t.result_factor_min, t.result_factor_max);
  const randomFactor = randRange(rng, t.random_min, t.random_max);
  const offer = Math.round((pond.quote_price * lerp(t.value_lerp_min, t.value_lerp_max, valueFactor / t.value_factor_max) * resultFactor * randomFactor) / t.rounding) * t.rounding;
  return { income: Math.max(t.min_income, offer) };
}

function generateOneNet(pond, result, rng) {
  const n = rules.market.one_net;
  const heat = clamp(1 + result.quality * n.quality_weight, n.heat_factor_min, n.heat_factor_max);
  const income = Math.round(((pond.quote_price * randRange(rng, n.quote_ratio_min, n.quote_ratio_max)) + (pond.hidden_value * randRange(rng, n.hidden_ratio_min, n.hidden_ratio_max))) * heat / n.rounding) * n.rounding;
  return { income: Math.max(n.min_income, income) };
}

function selectPond(strategy, contractable, seed) {
  if (!contractable.length) return null;
  const rng = makeRng(seed);
  if (strategy.selection === "lowest_quote") return [...contractable].sort((a, b) => a.quote_price - b.quote_price)[0];
  if (strategy.selection === "best_hidden_value_ratio_with_noise") {
    let best = contractable[0];
    let bestScore = -Infinity;
    for (const pond of contractable) {
      const noise = randRange(rng, strategy.selection_noise_min ?? 0.82, strategy.selection_noise_max ?? 1.18);
      const score = (pond.hidden_value * noise) / Math.max(pond.quote_price, 1);
      if (score > bestScore) {
        best = pond;
        bestScore = score;
      }
    }
    return best;
  }
  return pick(contractable, rng);
}

function makeState() {
  return {
    cash: gameBalance.initial_cash,
    currentPond: null,
    inspectionCostTotal: 0,
    oneNetIncome: 0,
    transferIncome: 0,
    workCost: 0,
    fishIncome: 0,
    catchDetails: [],
    soldOneNet: false
  };
}

function resetRound(state) {
  state.currentPond = null;
  state.inspectionCostTotal = 0;
  state.oneNetIncome = 0;
  state.transferIncome = 0;
  state.workCost = 0;
  state.fishIncome = 0;
  state.catchDetails = [];
  state.soldOneNet = false;
}

function canContract(state, pond) {
  return state.cash - pond.quote_price >= gameBalance.min_working_capital;
}

function contract(state, pond) {
  if (!canContract(state, pond)) return false;
  state.cash -= pond.quote_price;
  state.currentPond = clone(pond);
  return true;
}

function pay(state, amount) {
  if (state.cash < amount) return false;
  state.cash -= amount;
  return true;
}

function getWorkCost(state, planId) {
  if (planId === "low") return gameBalance.low_work_cost;
  if (planId === "full" || planId === "drain") return Math.max(gameBalance.full_work_min_cost, Math.round(state.currentPond.quote_price * gameBalance.full_work_quote_ratio));
  return gameBalance.standard_work_cost;
}

function applyHarvest(state, result, cost) {
  state.workCost += cost;
  state.fishIncome += result.fish_income;
  state.cash += result.fish_income;
  state.catchDetails = mergeCatchDetails(state.catchDetails, result.catch_details);
}

function mergeCatchDetails(existing, next) {
  const byId = new Map(existing.map((item) => [item.id, { ...item }]));
  next.forEach((item) => {
    const current = byId.get(item.id);
    if (!current) byId.set(item.id, { ...item });
    else {
      current.weight_jin += item.weight_jin;
      current.income += item.income;
      current.unit_price = item.unit_price;
    }
  });
  return [...byId.values()];
}

function getQuality(fishId, income, cost) {
  const q = rules.fishing.quality_scores[fishId] || rules.fishing.quality_scores.default;
  const ratio = (income - cost) / Math.max(cost, 1);
  return clamp(q.base + ratio * q.profit_weight, q.min, q.max);
}

function renderResults(summaries) {
  rowsEl.innerHTML = summaries.map((item) => `
    <tr>
      <td>${labelStrategy(item.name)}</td>
      <td class="${item.avgRoi >= 0 ? "good" : "bad"}">${percent(item.avgRoi)}</td>
      <td>${percent(item.medianRoi)}</td>
      <td>${money(item.p25)}</td>
      <td>${money(item.p50)}</td>
      <td>${money(item.p75)}</td>
      <td>${percent(item.bankruptRate)}</td>
      <td>${item.avgDays.toFixed(2)}</td>
      <td>${percent(item.fishKingRate)}</td>
    </tr>
  `).join("");
  document.querySelector("#randomRoi").textContent = percent(findSummary(summaries, "random_no_inspection").avgRoi);
  document.querySelector("#basicRoi").textContent = percent(findSummary(summaries, "basic_stop_loss").avgRoi);
  document.querySelector("#masterRoi").textContent = percent(findSummary(summaries, "master_estimate_stop_loss").avgRoi);
  drawCashChart(summaries);
  renderInsights(summaries);
}

function drawCashChart(summaries) {
  const width = canvas.width;
  const height = canvas.height;
  chart.clearRect(0, 0, width, height);
  chart.fillStyle = "#fffaf0";
  chart.fillRect(0, 0, width, height);
  const maxCash = Math.max(1, ...summaries.flatMap((item) => [item.p75, item.p50, item.p25]));
  const colors = ["#9e2d22", "#1f6f4a", "#245a77"];
  summaries.forEach((item, index) => {
    const y = 58 + index * 82;
    chart.fillStyle = "#e8dcc1";
    chart.fillRect(150, y, 650, 18);
    chart.fillStyle = colors[index];
    const x25 = 150 + (item.p25 / maxCash) * 650;
    const x75 = 150 + (item.p75 / maxCash) * 650;
    const x50 = 150 + (item.p50 / maxCash) * 650;
    chart.fillRect(x25, y - 10, Math.max(2, x75 - x25), 38);
    chart.fillRect(x50 - 2, y - 18, 4, 54);
    chart.fillStyle = "#17211b";
    chart.font = "22px Georgia";
    chart.fillText(labelStrategy(item.name), 22, y + 18);
    chart.font = "16px Avenir Next";
    chart.fillText(`${money(item.p25)} / ${money(item.p50)} / ${money(item.p75)}`, 812, y + 18);
  });
}

function renderInsights(summaries) {
  const random = findSummary(summaries, "random_no_inspection");
  const master = findSummary(summaries, "master_estimate_stop_loss");
  const basic = findSummary(summaries, "basic_stop_loss");
  const lines = [];
  if (random.avgRoi < -0.5) lines.push("随机不验塘亏损超过 -50%，当前惩罚偏重。");
  if (random.avgRoi > -0.3) lines.push("随机不验塘亏损低于 -30%，可能太容易刷。");
  if (master.avgRoi > -0.03) lines.push("老师傅策略接近正收益，注意稳定套利风险。");
  if (master.avgRoi < basic.avgRoi) lines.push("老师傅代理没有优于基础止损，可能是信息成本或选塘噪声过高。");
  if (basic.bankruptRate > 0.8) lines.push("基础止损破产率很高，玩家可能过早失去操作空间。");
  if (!lines.length) lines.push("当前结果落在较健康的测试区间，可以继续看单项参数影响。");
  document.querySelector("#insights").innerHTML = lines.map((line) => `<li>${line}</li>`).join("");
}

function findSummary(summaries, name) {
  return summaries.find((item) => item.name === name) || summaries[0];
}

function labelStrategy(name) {
  return {
    random_no_inspection: "随机不验塘",
    basic_stop_loss: "基础止损",
    master_estimate_stop_loss: "老师傅代理"
  }[name] || name;
}

function makeRng(seed) {
  let state = seed >>> 0;
  return function rng() {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

function randRange(rng, min, max) {
  return min + rng() * (max - min);
}

function randInt(rng, min, max) {
  return Math.floor(randRange(rng, min, max + 1));
}

function pick(array, rng) {
  return array[Math.min(array.length - 1, Math.floor(rng() * array.length))];
}

function pickWeighted(items, weights, rng) {
  const total = items.reduce((sum, item) => sum + (weights[item.id] || 0), 0);
  let roll = rng() * total;
  for (const item of items) {
    roll -= weights[item.id] || 0;
    if (roll <= 0) return item;
  }
  return items[items.length - 1];
}

function shuffle(array, rng) {
  const next = [...array];
  for (let i = next.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rng() * (i + 1));
    [next[i], next[j]] = [next[j], next[i]];
  }
  return next;
}

function snapWeight(weight, unit) {
  if (weight <= 0) return 0;
  return Math.max(unit, Math.round(weight / unit) * unit);
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function clampInt(value, min, max) {
  return Math.floor(clamp(value, min, max));
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function round2(value) {
  return Math.round(value * 100) / 100;
}

function percentile(values, p) {
  if (!values.length) return 0;
  return values[Math.min(values.length - 1, Math.max(0, Math.round((values.length - 1) * p)))];
}

function average(values) {
  if (!values.length) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function getPath(object, path) {
  return path.split(".").reduce((current, key) => current?.[key], object);
}

function setPath(object, path, value) {
  const parts = path.split(".");
  const last = parts.pop();
  const target = parts.reduce((current, key) => current[key], object);
  target[last] = value;
}

function readNumber(selector) {
  return Number(document.querySelector(selector).value);
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function formatValue(value) {
  return Number.isInteger(value) ? String(value) : value.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
}

function percent(value) {
  return `${(value * 100).toFixed(1)}%`;
}

function money(value) {
  return `¥${Math.round(value).toLocaleString("zh-CN")}`;
}
