/* eslint-disable comma-dangle, max-len, no-useless-return, no-param-reassign, max-len */
/* global Api */

import TemplateSelector from '../blob/template_selector';

((global) => {
  class IssuableTemplateSelector extends TemplateSelector {
    constructor(...args) {
      super(...args);
      this.projectPath = this.dropdown.data('project-path');
      this.namespacePath = this.dropdown.data('namespace-path');
      this.issuableType = this.$dropdownContainer.data('issuable-type');
      this.titleInput = $(`#${this.issuableType}_title`);

      const initialQuery = {
        name: this.dropdown.data('selected')
      };

      if (initialQuery.name) this.requestFile(initialQuery);

      $('.reset-template', this.dropdown.parent()).on('click', () => {
        this.setInputValueToTemplateContent();
      });

      $('.no-template', this.dropdown.parent()).on('click', () => {
        this.currentTemplate.content = '';
        this.setInputValueToTemplateContent();
        $('.dropdown-toggle-text', this.dropdown).text('Choose a template');
      });
    }

    requestFile(query) {
      this.startLoadingSpinner();
      Api.issueTemplate(this.namespacePath, this.projectPath, query.name, this.issuableType, (err, currentTemplate) => {
        this.currentTemplate = currentTemplate;
        if (err) return; // Error handled by global AJAX error handler
        this.stopLoadingSpinner();
        this.setInputValueToTemplateContent();
      });
      return;
    }

    setInputValueToTemplateContent() {
      // `this.setEditorContent` sets the value of the description input field
      // to the content of the template selected.
      if (this.titleInput.val() === '') {
        // If the title has not yet been set, focus the title input and
        // skip focusing the description input by setting `true` as the
        // `skipFocus` option to `setEditorContent`.
        this.setEditorContent(this.currentTemplate, { skipFocus: true });
        this.titleInput.focus();
      } else {
        this.setEditorContent(this.currentTemplate, { skipFocus: false });
      }
      return;
    }
  }

  global.IssuableTemplateSelector = IssuableTemplateSelector;
})(window.gl || (window.gl = {}));
