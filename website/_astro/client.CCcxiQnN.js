export const c = (template, vars = {}) => {
  if (!template) return '';
  return Object.entries(vars).reduce(
    (str, [k, v]) => str.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v)),
    String(template)
  );
};

c.lang = (typeof document !== 'undefined' && document.documentElement && document.documentElement.lang) ? document.documentElement.lang : 'en';

c.plural = (num, one, many) => {
  const chosen = num === 1 ? one : many;
  return chosen.replace('{n}', typeof num === 'number' && num.toLocaleString ? num.toLocaleString() : String(num));
};

export const n = (val) => {
  return typeof val === 'number' && val.toLocaleString ? val.toLocaleString() : String(val);
};

export default { c, n };
