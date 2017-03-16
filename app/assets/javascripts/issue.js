/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, no-underscore-dangle, one-var-declaration-per-line, object-shorthand, no-unused-vars, no-new, comma-dangle, consistent-return, quotes, dot-notation, quote-props, prefer-arrow-callback, max-len */
/* global Flash */

import NewMergeRequestDropdown from './create_merge_request_dropdown';

require('./flash');
require('~/lib/utils/text_utility');
require('vendor/jquery.waitforimages');
require('./task_list');

class Issue {
  constructor() {
    if ($('a.btn-close').length) {
      this.taskList = new gl.TaskList({
        dataType: 'issue',
        fieldName: 'description',
        selector: '.detail-page-description',
        onSuccess: (result) => {
          document.querySelector('#task_status').innerText = result.task_status;
          document.querySelector('#task_status_short').innerText = result.task_status_short;
        }
      });
      Issue.initIssueBtnEventListeners();
    }
    Issue.initMergeRequests();
    Issue.initRelatedBranches();

    const wrapperEl = document.querySelector('.create-merge-request-dropdown-wrap');
    if (wrapperEl) {
      new NewMergeRequestDropdown(wrapperEl);
    }
  }

  static initIssueBtnEventListeners() {
    var issueFailMessage;
    issueFailMessage = 'Unable to update this issue at this time.';
    return $('a.btn-close, a.btn-reopen').on('click', function(e) {
      var $this, isClose, shouldSubmit, url;
      e.preventDefault();
      e.stopImmediatePropagation();
      $this = $(this);
      isClose = $this.hasClass('btn-close');
      shouldSubmit = $this.hasClass('btn-comment');
      if (shouldSubmit) {
        Issue.submitNoteForm($this.closest('form'));
      }
      $this.prop('disabled', true);
      url = $this.attr('href');
      return $.ajax({
        type: 'PUT',
        url: url,
        error: function(jqXHR, textStatus, errorThrown) {
          var issueStatus;
          issueStatus = isClose ? 'close' : 'open';
          return new Flash(issueFailMessage, 'alert');
        },
        success: function(data, textStatus, jqXHR) {
          if ('id' in data) {
            $(document).trigger('issuable:change');
            let total = Number($('.issue_counter').text().replace(/[^\d]/, ''));
            if (isClose) {
              $('a.btn-close').addClass('hidden');
              $('a.btn-reopen').removeClass('hidden');
              $('div.status-box-closed').removeClass('hidden');
              $('div.status-box-open').addClass('hidden');
              total -= 1;
            } else {
              $('a.btn-reopen').addClass('hidden');
              $('a.btn-close').removeClass('hidden');
              $('div.status-box-closed').addClass('hidden');
              $('div.status-box-open').removeClass('hidden');
              total += 1;
            }
            $('.issue_counter').text(gl.text.addDelimiter(total));
          } else {
            new Flash(issueFailMessage, 'alert');
          }
          return $this.prop('disabled', false);
        }
      });
    });
  }

  static submitNoteForm(form) {
    var noteText;
    noteText = form.find("textarea.js-note-text").val();
    if (noteText.trim().length > 0) {
      return form.submit();
    }
  }

  static initMergeRequests() {
    var $container;
    $container = $('#merge-requests');
    return $.getJSON($container.data('url')).error(function() {
      return new Flash('Failed to load referenced merge requests', 'alert');
    }).success(function(data) {
      if ('html' in data) {
        return $container.html(data.html);
      }
    });
  }

  static initRelatedBranches() {
    var $container;
    $container = $('#related-branches');
    return $.getJSON($container.data('url')).error(function() {
      return new Flash('Failed to load related branches', 'alert');
    }).success(function(data) {
      if ('html' in data) {
        return $container.html(data.html);
      }
    });
  }
}

export default Issue;
