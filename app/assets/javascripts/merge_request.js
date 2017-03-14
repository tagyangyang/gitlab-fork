/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, quotes, no-underscore-dangle, one-var, one-var-declaration-per-line, consistent-return, dot-notation, quote-props, comma-dangle, object-shorthand, max-len, prefer-arrow-callback */
/* global MergeRequestTabs */

require('vendor/jquery.waitforimages');
require('./task_list');
require('./gl_lightbox');
require('./merge_request_tabs');

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

  this.MergeRequest = (function() {
    function MergeRequest(opts) {
      // Initialize MergeRequest behavior
      //
      // Options:
      //   action - String, current controller action
      //
      this.opts = opts != null ? opts : {};
      this.submitNoteForm = bind(this.submitNoteForm, this);
      this.$el = $('.merge-request');
      this.$lightbox = $('.lightbox');
      this.$('.show-all-commits').on('click', (function(_this) {
        return function() {
          return _this.showAllCommits();
        };
      })(this));
      this.initTabs();
      this.initMRBtnListeners();
      this.initCommitMessageListeners();
      if ($("a.btn-close").length) {
        this.taskList = new gl.TaskList({
          dataType: 'merge_request',
          fieldName: 'description',
          selector: '.detail-page-description',
          onSuccess: (result) => {
            document.querySelector('#task_status').innerText = result.task_status;
            document.querySelector('#task_status_short').innerText = result.task_status_short;
          }
        });
      }
    }

    // Local jQuery finder
    MergeRequest.prototype.$ = function(selector) {
      return this.$el.find(selector);
    };

    MergeRequest.prototype.initTabs = function() {
      if (window.mrTabs) {
        window.mrTabs.unbindEvents();
      }
      window.mrTabs = new gl.MergeRequestTabs(this.opts);
    };

    MergeRequest.prototype.showAllCommits = function() {
      this.$('.first-commits').remove();
      return this.$('.all-commits').removeClass('hide');
    };

    MergeRequest.prototype.initMRBtnListeners = function() {
      var _this;
      _this = this;
      return $('a.btn-close, a.btn-reopen').on('click', function(e) {
        var $this, shouldSubmit;
        $this = $(this);
        shouldSubmit = $this.hasClass('btn-comment');
        if (shouldSubmit && $this.data('submitted')) {
          return;
        }
        if (shouldSubmit) {
          if ($this.hasClass('btn-comment-and-close') || $this.hasClass('btn-comment-and-reopen')) {
            e.preventDefault();
            e.stopImmediatePropagation();
            return _this.submitNoteForm($this.closest('form'), $this);
          }
        }
      });
    };

    MergeRequest.prototype.submitNoteForm = function(form, $button) {
      var noteText;
      noteText = form.find("textarea.js-note-text").val();
      if (noteText.trim().length > 0) {
        form.submit();
        $button.data('submitted', true);
        return $button.trigger('click');
      }
    };

    MergeRequest.prototype.initCommitMessageListeners = function() {
      $(document).on('click', 'a.js-with-description-link', function(e) {
        var textarea = $('textarea.js-commit-message');
        e.preventDefault();

        textarea.val(textarea.data('messageWithDescription'));
        $('.js-with-description-hint').hide();
        $('.js-without-description-hint').show();
      });

      $(document).on('click', 'a.js-without-description-link', function(e) {
        var textarea = $('textarea.js-commit-message');
        e.preventDefault();

        textarea.val(textarea.data('messageWithoutDescription'));
        $('.js-with-description-hint').show();
        $('.js-without-description-hint').hide();
      });
    };

    return MergeRequest;
  })();
}).call(window);
