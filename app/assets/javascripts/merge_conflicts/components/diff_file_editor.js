/* eslint-disable comma-dangle, quote-props, no-useless-computed-key, object-shorthand, no-new, no-param-reassign, max-len */
/* global ace */
/* global Flash */

import Vue from 'vue';

const global = window.gl || (window.gl = {});

global.mergeConflicts = global.mergeConflicts || {};

global.mergeConflicts.diffFileEditor = Vue.extend({
  props: {
    file: Object,
    onCancelDiscardConfirmation: Function,
    onAcceptDiscardConfirmation: Function
  },
  data() {
    return {
      saved: false,
      loading: false,
      fileLoaded: false,
      originalContent: '',
    };
  },
  computed: {
    classObject() {
      return {
        'saved': this.saved,
        'is-loading': this.loading
      };
    }
  },
  watch: {
    ['file.showEditor'](val) {
      this.resetEditorContent();

      if (!val || this.fileLoaded || this.loading) {
        return;
      }

      this.loadEditor();
    }
  },
  mounted() {
    if (this.file.loadEditor) {
      this.loadEditor();
    }
  },
  methods: {
    loadEditor() {
      this.loading = true;

      $.get(this.file.content_path)
        .done((file) => {
          const content = this.$el.querySelector('pre');
          const fileContent = document.createTextNode(file.content);

          content.textContent = fileContent.textContent;

          this.originalContent = file.content;
          this.fileLoaded = true;
          this.editor = ace.edit(content);
          this.editor.$blockScrolling = Infinity; // Turn off annoying warning
          this.editor.getSession().setMode(`ace/mode/${file.blob_ace_mode}`);
          this.editor.on('change', () => {
            this.saveDiffResolution();
          });
          this.saveDiffResolution();
        })
        .fail(() => {
          new Flash('Failed to load the file, please try again.');
        })
        .always(() => {
          this.loading = false;
        });
    },
    saveDiffResolution() {
      this.saved = true;

      // This probably be better placed in the data provider
      this.file.content = this.editor.getValue();
      this.file.resolveEditChanged = this.file.content !== this.originalContent;
      this.file.promptDiscardConfirmation = false;
    },
    resetEditorContent() {
      if (this.fileLoaded) {
        this.editor.setValue(this.originalContent, -1);
      }
    },
    cancelDiscardConfirmation(file) {
      this.onCancelDiscardConfirmation(file);
    },
    acceptDiscardConfirmation(file) {
      this.onAcceptDiscardConfirmation(file);
    }
  }
});
