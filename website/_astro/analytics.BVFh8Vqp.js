// Export names matching minified Astro bundle expectations:
// L as k: current deal { amount, cap, remaining }
export const L = { amount: 15, cap: 50, remaining: 50 };

// B as N: regular price
export const B = 39;

// r as K: deal active check
export const r = () => true;

// a as v: api url
export const a = 'https://api.aktiviti.app';

// P as D: product id
export const P = 'pro_01';

// Y as J: maintenance months
export const Y = 12;

// b as V: 1-year update price
export const b = 9;

// c as C: price tiers
export const c = [
  { amount: 5, count: 1000 },
  { amount: 15, count: 500 },
  { amount: 19, count: 500 },
  { amount: 25, count: 500 },
  { amount: 39 }
];

// d as L: next price tier
export const d = { amount: 19 };

// t as h: tracking function
export const t = (event, data) => {
  try {
    if (window.dataLayer) window.dataLayer.push({ event, ...data });
  } catch {}
  return true;
};

// C as j: thanks url
export const C = '/thanks';

// S as Z: base url
export const S = '';

// q as T: price calculator
export const q = (macs, amount) => {
  const m = Number(macs) || 1;
  const unit = Number(amount) || 15;
  const pricingTable = {
    1: { total: unit, regular: 39 },
    2: { total: 25, regular: 78 },
    5: { total: 55, regular: 195 },
    10: { total: 99, regular: 390 },
    25: { total: 199, regular: 975 }
  };
  return pricingTable[m] || { total: m * unit, regular: m * 39 };
};

// M as z: mac count options
export const M = [1, 2, 5, 10, 25];

// e as Q: paddle token
export const e = 'live_token';

// F as X: bundles
export const F = [
  { slug: 'fore', name: 'Fore Plus', price: 49 },
  { slug: 'fore-all', name: 'Fore Insider', price: 99 }
];

// p as ee: get placement
export const p = (btn) => btn?.dataset?.track || 'cta';

// f as te: support email
export const f = 'support@aktiviti.app';

// v as ae: paddle checkout items generator
export const v = (macs, price) => [{ priceId: 'pri_aktiviti_lifetime', quantity: Number(macs) || 1 }];

// g as ne: success url
export const g = '/thanks';

export default {
  L, B, r, a, P, Y, b, c, d, t, C, S, q, M, e, F, p, f, v, g
};
