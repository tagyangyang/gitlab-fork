const PREVIEW_CLASS = 'preview-mode';
const HIDDEN_CLASS = 'hidden';

export default class TemplatePreview {
  constructor(mediator) {
    this.mediator = mediator;
    this.cachedFile = null;
    this.cachedFilename = null;
    this.unconfirmedFile = null;
    this.unconfirmedFilename = null;
    this.storeDomReferences();
  }

  storeDomReferences() {
    this.$confirmBox = $('.apply-template-preview');
    this.$applyBtn = this.$confirmBox.find('.apply-template');
    this.$cancelBtn = this.$confirmBox.find('.cancel-template');
    this.$submitBtn = $('.js-commit-button');
    this.$editorPane = $('.ace_content');
    this.$editorTextArea = $('ace_text-input');
    this.$dropdownToggleBtns = $('.dropdown-menu-toggle');
    this.$filenameInput = $('.js-file-path-name-input');
    this.$fileButtons = $('.file-buttons');
  }

  enablePreviewMode() {
    this.$submitBtn.prop('disabled', true);
    this.mediator.editor.setReadOnly(true);
    this.$editorPane.addClass(PREVIEW_CLASS);
    this.$confirmBox.removeClass(HIDDEN_CLASS);

    this.$dropdownToggleBtns.prop('disabled', true);
    this.$filenameInput.prop('disabled', true);
    this.$fileButtons.addClass(HIDDEN_CLASS);

    this.$applyBtn.on('click', () => this.apply());
    this.$cancelBtn.on('click', () => this.cancel());
  }

  disablePreviewMode() {
    this.$submitBtn.prop('disabled', false);
    this.mediator.editor.setReadOnly(false);
    this.$editorPane.removeClass(PREVIEW_CLASS);
    this.$confirmBox.addClass(HIDDEN_CLASS);
    this.$dropdownToggleBtns.prop('disabled', false);
    this.$filenameInput.prop('disabled', false);
    this.$fileButtons.removeClass(HIDDEN_CLASS);
  }

  confirm({ unconfirmedFile, currentFile, unconfirmedFilename, currentFilename }) {
    this.cachedFile = currentFile;
    this.unconfirmedFile = unconfirmedFile;
    this.cachedFilename = currentFilename;
    this.unconfirmedFilename = unconfirmedFilename;
    this.enablePreviewMode();
    this.mediator.setFilename(unconfirmedFilename);
    this.mediator.setEditorContent(this.unconfirmedFile);
  }

  cancel() {
    this.disablePreviewMode();
    this.mediator.setEditorContent(this.cachedFile);
    this.mediator.setFilename(this.cachedFilename);
    this.destroy();
  }

  apply() {
    this.disablePreviewMode();
    this.destroy();
  }

  destroy() {
    this.cachedFile = null;
    this.unconfirmedFile = null;
    this.$applyBtn.off();
    this.$cancelBtn.off();
  }
}

