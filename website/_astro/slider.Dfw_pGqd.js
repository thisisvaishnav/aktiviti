export const s = (root = document) => {
  if (!root || !root.querySelectorAll) return;
  const sliders = root.querySelectorAll('[data-slider]');
  sliders.forEach(slider => {
    const fill = slider.querySelector('i');
    const container = slider.closest('.flex') || slider.parentElement;
    const valueDisplay = container ? container.querySelector('[data-slider-value]') : null;

    const setVal = (pct) => {
      pct = Math.max(0, Math.min(100, Math.round(pct)));
      slider.dataset.slider = String(pct);
      if (fill) fill.style.width = `${pct}%`;
      if (valueDisplay) valueDisplay.textContent = `${pct}%`;
      slider.dispatchEvent(new CustomEvent('input', { detail: { value: pct }, bubbles: true }));
      slider.dispatchEvent(new CustomEvent('change', { detail: { value: pct }, bubbles: true }));
    };

    const initPct = parseFloat(slider.dataset.slider || '50');
    setVal(initPct);

    let isDragging = false;
    const onMove = (e) => {
      if (!isDragging) return;
      const rect = slider.getBoundingClientRect();
      const clientX = e.touches ? e.touches[0].clientX : e.clientX;
      const pct = ((clientX - rect.left) / rect.width) * 100;
      setVal(pct);
    };

    const onEnd = () => {
      if (isDragging) {
        isDragging = false;
        window.removeEventListener('pointermove', onMove);
        window.removeEventListener('pointerup', onEnd);
        window.removeEventListener('touchmove', onMove);
        window.removeEventListener('touchend', onEnd);
      }
    };

    const onStart = (e) => {
      isDragging = true;
      onMove(e);
      window.addEventListener('pointermove', onMove);
      window.addEventListener('pointerup', onEnd);
      window.addEventListener('touchmove', onMove, { passive: true });
      window.addEventListener('touchend', onEnd);
    };

    slider.addEventListener('pointerdown', onStart);
    slider.addEventListener('touchstart', onStart, { passive: true });
  });
};

export default { s };
