/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-new */
/* global ImageFile */

function CommitFile(file) {
  if ($('.image', file).length) {
    new gl.ImageFile(file);
  }
}

window.CommitFile = CommitFile;
