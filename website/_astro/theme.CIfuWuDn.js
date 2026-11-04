const STORAGE_KEY = 'aktiviti-theme';

export const c = () => {
  try {
    return localStorage.getItem(STORAGE_KEY) || 'system';
  } catch {
    return 'system';
  }
};

export const i = () => {
  const current = c();
  if (current === 'dark') return true;
  if (current === 'light') return false;
  return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
};

function applyTheme(val) {
  const isDark = val === 'dark' || (val === 'system' && window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);
  document.documentElement.classList.toggle('dark', isDark);
  document.documentElement.setAttribute('data-theme', val);
  document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
}

export const a = (val) => {
  try {
    localStorage.setItem(STORAGE_KEY, val);
  } catch {}
  applyTheme(val);
  document.dispatchEvent(new CustomEvent('themechange', { detail: val }));
};

export const f = () => {
  const next = i() ? 'light' : 'dark';
  a(next);
};

if (typeof window !== 'undefined') {
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (c() === 'system') {
        applyTheme('system');
        document.dispatchEvent(new CustomEvent('themechange', { detail: 'system' }));
      }
    });
  }
  applyTheme(c());
}

export default { c, i, a, f };
