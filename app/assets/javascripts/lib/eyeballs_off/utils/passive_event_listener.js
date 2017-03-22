/**
 * Tests for passive scroll support
 * Copied from https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md
 */
let supportsPassiveOption = false;
try {
  const opts = Object.defineProperty({}, 'passive', {
    get: () => {
      supportsPassiveOption = true;
    },
  });
  window.addEventListener('test', null, opts);
} catch (e) {
  /* */
}

/**
 * Attempts to add a passive scroll listener if possible,
 * otherwise adds a non-capture listeners
 */
export const addEventListener = (target, type, handler) => {
  let optionsOrCapture;

  if (supportsPassiveOption) {
    optionsOrCapture = { passive: true };
  } else {
    optionsOrCapture = false;
  }

  target.addEventListener(type, handler, optionsOrCapture);
};

export const removeEventListener = (target, type, handler) => {
  let optionsOrCapture;

  if (supportsPassiveOption) {
    optionsOrCapture = { passive: true };
  } else {
    optionsOrCapture = false;
  }

  target.removeEventListener(type, handler, optionsOrCapture);
};
