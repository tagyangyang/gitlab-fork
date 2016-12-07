/* eslint-disable func-names, space-before-function-paren, no-param-reassign, no-new, no-bitwise*/
/* global ace BlobGitignoreSelectors */
((window, $) => {
  const bind = function(fn, me) {
    return function(...args) {
      return fn.apply(me, args);
    };
  };

  window.NewFileBlob = window.NewFileBlob || class NewFileBlob {
    constructor(assetsPath) {
      this.editor = null;
      this.isSoftWrapped = false;
      this.assetsPath = assetsPath;
      this.previewableFileExtension = ['md', 'markdown', 'mdown'];

      this.$form = $('form');
      this.$fileContent = $('#file-content');
      this.$toggleButton = $('.soft-wrap-toggle');
      this.$newFileModeBar = $('.js-new-file-mode');
      this.$newFileModeLinks = this.$newFileModeBar.find('a');
      this.$newFileModePanes = $('.js-new-file-mode-pane');
      this.$filenameTextbox = $('.new-file-name');


      // class method bindings
      this.fileModeLinkClickHandler = bind(this.fileModeLinkClickHandler, this);
      this.filenameTextboxHandler = bind(this.filenameTextboxHandler, this);
      this.toggleSoftWrap = bind(this.toggleSoftWrap, this);
      this.submitForm = bind(this.submitForm, this);

      this.bindEvents();
      this.initEditor();
      this.initHelpers();
    }

    bindEvents() {
      this.$newFileModeLinks.click(this.fileModeLinkClickHandler);
      this.$toggleButton.click(this.toggleSoftWrap);
      this.$form.submit(this.submitForm);
      this.$filenameTextbox.on('input', _.debounce(this.filenameTextboxHandler, 300));
    }

    initEditor() {
      ace.config.set('modePath', `${this.assetsPath}/ace`);
      ace.config.loadModule('ace/ext/searchbox');
      this.editor = ace.edit('editor');
      this.editor.focus();
    }

    initHelpers() {
      new gl.BlobLicenseSelectors({ editor: this.editor });
      new BlobGitignoreSelectors({ editor: this.editor });
      new gl.BlobCiYamlSelectors({ editor: this.editor });
    }

    toggleSoftWrap(e) {
      e.preventDefault();
      this.isSoftWrapped = !this.isSoftWrapped;
      this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
      this.editor.getSession().setUseWrapMode(this.isSoftWrapped);
    }

    fileModeLinkClickHandler(e) {
      e.preventDefault();
      const $currentLink = $(e.target);
      const paneId = $currentLink.attr('href');
      const currentPane = this.$newFileModePanes.filter(paneId);
      this.$newFileModeLinks.parent().removeClass('active hover');
      $currentLink.parent().addClass('active hover');
      this.$newFileModePanes.hide();
      currentPane.fadeIn(200);
      if (paneId === '#preview') {
        this.$toggleButton.hide();

        return $.post($currentLink.data('preview-url'), {
          content: this.editor.getValue(),
        }, (response) => {
          currentPane.empty().append(response);
          return currentPane.syntaxHighlight();
        });
      }

      this.$toggleButton.show();
      this.editor.focus();
      return false;
    }

    filenameTextboxHandler(e) {
      const $node = $(e.target);
      const filename = $node.val();
      const extension = gl.utils.getFileExtension(filename);
      if (!(~this.previewableFileExtension.lastIndexOf(extension))) {
        this.$newFileModeBar.hide(100);
      } else {
        this.$newFileModeBar.show(300);
      }
    }

    submitForm() {
      return this.$fileContent.val(this.editor.getValue());
    }
  };
})(window, jQuery);
