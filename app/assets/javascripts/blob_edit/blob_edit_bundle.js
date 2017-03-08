/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, vars-on-top, no-unused-vars, no-new, max-len */
/* global EditBlob */
/* global NewCommitForm */

const EditBlob = require('./edit_blob');

$(function() {
  const $editBlobForm = $('.js-edit-blob-form');

  const relativeUrlRoot = $editBlobForm.data('relative-url-root');
  const assetsPrefix = $editBlobForm.data('assets-prefix');
  const blobLanguage = $editBlobForm.data('blob-language');

  const assetsPath = relativeUrlRoot + assetsPrefix;
  const currentAction = $('.js-file-title').data('current-action');
  new EditBlob(assetsPath, blobLanguage, currentAction);
  new NewCommitForm($editBlobForm);
});
