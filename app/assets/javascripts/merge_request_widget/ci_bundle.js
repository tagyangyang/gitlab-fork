/* global merge_request_widget */

$(() => {
  /* TODO: This needs a better home, or should be refactored. It was previously contained
   * in a script tag in app/views/projects/merge_requests/widget/open/_accept.html.haml,
   * but Vue chokes on script tags and prevents their execution. So it was moved here
   * temporarily.
   * */

  $(document)
  .off('ajax:send', '.accept-mr-form')
  .on('ajax:send', '.accept-mr-form', () => {
    $('.accept-mr-form :input').disable();
  });

  $(document)
  .off('click', '.accept-merge-request')
  .on('click', '.accept-merge-request', () => {
    $('.js-merge-button, .js-merge-when-pipeline-succeeds-button').html('<i class="fa fa-spinner fa-spin"></i> Merge in progress');
  });

  $(document)
  .off('click', '.merge-when-pipeline-succeeds')
  .on('click', '.merge-when-pipeline-succeeds', () => {
    $('#merge_when_pipeline_succeeds').val('1');
  });

  $(document)
  .off('click', '.js-merge-dropdown a')
  .on('click', '.js-merge-dropdown a', (e) => {
    e.preventDefault();
    $(e.target).closest('form').submit();
  });
  if ($('.rebase-in-progress').length) {
    merge_request_widget.rebaseInProgress();
  } else if ($('.rebase-mr-form').length) {
    $(document)
    .off('ajax:send', '.rebase-mr-form')
    .on('ajax:send', '.rebase-mr-form', () => {
      $('.rebase-mr-form :input').disable();
    });

    $(document)
    .off('click', '.js-rebase-button')
    .on('click', '.js-rebase-button', () => {
      $('.js-rebase-button').html("<i class='fa fa-spinner fa-spin'></i> Rebase in progress");
    });
  } else {
    setTimeout(() => merge_request_widget.getMergeStatus(), 200);
  }
});
