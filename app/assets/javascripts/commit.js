/* eslint-disable func-names */
/* global CommitFile */

function Commit() {
  $('.files .diff-file').each(function () {
    return new CommitFile(this);
  });
}

window.Commit = Commit;
