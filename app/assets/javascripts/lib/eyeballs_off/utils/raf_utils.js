import raf, { cancel } from './raf';

/* Animation-frame frequency debounce */
export const debounce = (fn, context) => {
  let existing;
  return () => {
    if (existing) cancel(existing);

    existing = raf(() => {
      existing = undefined;
      fn.call(context);
    });
  };
};

/* Only allow one instantiation per animation frame, on the trailing edge */
export const throttle = (fn, context) => {
  let existing;

  return () => {
    if (existing) return;
    existing = raf(() => {
      existing = undefined;
      fn.call(context);
    });
  };
};

/* Perform an operation on each animation frame for the specified duration */
export const intervalUntil = (fn, ms) => {
  const until = Date.now() + ms;
  function next() {
    fn();
    if (Date.now() < until) {
      raf(next);
    }
  }
  raf(next);
};
