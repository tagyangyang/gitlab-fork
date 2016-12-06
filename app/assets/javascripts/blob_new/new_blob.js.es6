((window, $) => {
  const bind = function(fn, me) {
    return function() {
      return fn.apply(me, arguments);
    };
  };

  window.NewFileBlob = class NewFileBlob {
    constructor(assets_path) {
      this.editor = null;
      this.isSoftWrapped = false;
      this.assets_path = assets_path;

      this.$form = $('form');
      this.$fileContent = $("#file-content");
      this.$toggleButton = $('.soft-wrap-toggle');
      this.$newFileModeLinks = $('.js-new-file-mode a');
      this.$newFileModePanes = $('.js-new-file-mode-pane');

      // class method bindings
      this.fileModeLinkClickHandler = bind(this.fileModeLinkClickHandler, this);
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
    }

    initEditor() {
      ace.config.set("modePath", this.assets_path + "/ace");
      ace.config.loadModule("ace/ext/searchbox");
      this.editor = ace.edit("editor");
      this.editor.focus();
    }

    initHelpers() {
      new gl.BlobLicenseSelectors({
        editor: this.editor
      });
      new BlobGitignoreSelectors({
        editor: this.editor
      });
      new gl.BlobCiYamlSelectors({
        editor: this.editor
      });
    }

    toggleSoftWrap(e) {
      e.preventDefault();
      this.isSoftWrapped = !this.isSoftWrapped;
      this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
      this.editor.getSession().setUseWrapMode(this.isSoftWrapped);
    }

    fileModeLinkClickHandler(e) {
      e.preventDefault();
      const currentLink = $(e.target);
      const paneId = currentLink.attr("href");
      const currentPane = this.$newFileModePanes.filter(paneId);
      this.$newFileModeLinks.parent().removeClass("active hover");
      currentLink.parent().addClass("active hover");
      this.$newFileModePanes.hide();
      currentPane.fadeIn(200);
      if (paneId === "#preview") {
        this.$toggleButton.hide();

        return $.post(currentLink.data("preview-url"), {
          content: this.editor.getValue()
        }, function(response) {
          currentPane.empty().append(response);
          return currentPane.syntaxHighlight();
        });
      } else {
        this.$toggleButton.show();
        return this.editor.focus();
      }
    }

    submitForm(e) {
      return this.$fileContent.val(this.editor.getValue());
    };
  }
})(window, jQuery);