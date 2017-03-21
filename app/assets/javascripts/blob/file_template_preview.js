export default class FileTemplatePreview {
  constructor(mediator, file) {
    this.mediator = mediator;
    this.$applyBtn = $('apply-btn');
    this.$cancelBtn = $('cancel-btn');
    this.$confirmBox = $('.confirm-message-box');
    this.$submitBtn = $('the form submit btn');
    this.$editBtns = $('any buttons you can edit with');
    this.editorPane = $('.editor-pane');
    this.cachedFile = null;
    this.unconfirmedFile = null;
  }

  enablePreviewMode() {
    // disable all buttons
    // style editor pane background
    // set editor content to confirmedFile
    // all your dom stuff
  }

  disablePreviewMode() {
   // renable buttons
   // unstyle editor
  }

  confirm(unconfirmedFile, currentFile, callback) {
    this.cachedFile = currentFile;
    this.unconfirmedFile = unconfirmedFile;

    this.enablePreviewMode();

    $('apply-btn').on('click', () => this.apply(callback));
    $('cancel-btn').on('click', () => this.cancel(callback));
  }

  cancel(callback) {
    callback(false);
    this.disablePreviewMode();
  }

  apply(callback) {
    // tell mediator to apply template
    callback(true);
    this.disablePreviewMode();
 }

  destroy() {

  }
}