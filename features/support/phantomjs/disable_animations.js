/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, camelcase, no-param-reassign, quotes, prefer-template, no-new, comma-dangle, one-var, one-var-declaration-per-line, prefer-arrow-callback, no-else-return, no-unused-vars, padded-blocks, max-len */
var disableAnimationStyles = '-o-transition: none !important; ' +
  '-moz-transition: none !important; ' +
  '-ms-transition: none !important; ' +
  '-webkit-transition: none !important;' +
  'transition: none !important; ' +
  '-o-transform: none !important; ' +
  '-moz-transform: none !important; ' +
  '-ms-transform: none !important; ' +
  '-webkit-transform: none !important;' +
  'transform: none !important; ' +
  '-webkit-animation: none !important; ' +
  '-moz-animation: none !important; ' +
  '-o-animation: none !important; ' +
  '-ms-animation: none !important;' +
  'animation: none !important;';

window.onload = function disableCSSAnimationForTest() {
  var animationStyles = document.createElement('style');
  animationStyles.type = 'text/css';
  animationStyles.innerHTML = '* {' + disableAnimationStyles + '}';
  document.head.appendChild(animationStyles);
};
