const PREVIEW_CLASS = 'preview-mode';
const HIDDEN_CLASS = 'hidden';

export default class FileTemplatePreview {
  constructor(mediator) {
    this.mediator = mediator;
    this.cachedFile = null;
    this.unconfirmedFile = null;
    this.storeDomReferences();
  }

  storeDomReferences() {
    this.$confirmBox = $('.apply-template-preview');
    this.$applyBtn = this.$confirmBox.find('.apply-template');
    this.$cancelBtn = this.$confirmBox.find('.cancel-template');
    this.$submitBtn = $('.js-commit-button');
    this.$editorPane = $('.ace_content');
  }

  enablePreviewMode() {
    this.$submitBtn.prop('disabled', true);
    this.$editorPane.addClass(PREVIEW_CLASS);
    this.$confirmBox.removeClass(HIDDEN_CLASS);

    this.$applyBtn.on('click', () => this.apply());
    this.$cancelBtn.on('click', () => this.cancel());
  }

  disablePreviewMode() {
    this.$submitBtn.prop('disabled', false);
    this.$editorPane.removeClass(PREVIEW_CLASS);
    this.$confirmBox.addClass(HIDDEN_CLASS);
  }

  confirm({ unconfirmedFile, currentFile }) {
    this.cachedFile = currentFile;
    this.unconfirmedFile = unconfirmedFile;

    this.enablePreviewMode();
    this.mediator.setEditorContent(this.unconfirmedFile);
  }

  cancel() {
    this.mediator.setEditorContent(this.cachedFile);
    this.disablePreviewMode();
  }

  apply() {
    this.disablePreviewMode();
  }

  destroy() {
    this.$applyBtn.off();
    this.$cancelBtn.off();
  }
}

