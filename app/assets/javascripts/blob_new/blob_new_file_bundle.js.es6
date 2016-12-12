/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, vars-on-top, no-unused-vars, no-undef, no-new, padded-blocks, max-len */
/*= require_tree . */

(function() {
  $(function() {
    let url = $('.js-new-file-blob-form').data('relative-url-root');

    url += $('.js-new-file-blob-form').data('assets-prefix');

    const blob = new NewFileBlob(url);
    new NewCommitForm($('.js-new-file-blob-form'));
  });

}).call(this);
