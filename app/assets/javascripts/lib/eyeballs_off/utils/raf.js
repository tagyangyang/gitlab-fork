/* eslint-disable no-mixed-operators */
/**
 * Request Animation Frame shim
 *
 * The window.requestAnimationFrame() method
 * tells the browser that you wish to perform
 * an animation and requests that the browser
 * call a specified function to update an animation
 * before the next repaint.
 */
const nativeRaf = window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame;

const nativeCancel = window.cancelAnimationFrame ||
  window.webkitCancelAnimationFrame ||
  window.mozCancelAnimationFrame;

const shim = callback => window.setTimeout(callback, 1000 / 60);

const shimCancel = (timeoutId) => {
  window.clearTimeout(timeoutId);
};

export default nativeRaf && nativeRaf.bind(window) || shim;
export const cancel = nativeCancel && nativeCancel.bind(window) || shimCancel;
