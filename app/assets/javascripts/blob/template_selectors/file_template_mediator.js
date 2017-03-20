// re: mediator pattern https://addyosmani.com/resources/essentialjsdesignpatterns/book/#mediatorpatternjavascript
/**
 *  TODO:
 *  - look at how the quicklink shortcut to templates work, and how this might change that
 *  - are there cases where we need to iterate over selected dropdowns (multiple of the same type on the same page?)
 *  - Need to write unit tests for FileTemplateMediator and FileTemplateSelector, and integration tests for UX changes
 *  - Get a better name than 'selector' -- review naming modeling throughout
 *  - Make sure type selector label gets updated when there's a pattern match
 */

/* eslint-disable class-methods-use-this */

const FileTemplateTypeSelector = require('./_template_type_selector');

const BlobCiYamlSelector = require('./_blob_ci_yaml_selectors');
const DockerfileSelector = require('./_blob_dockerfile_selectors');
const GitignoreSelector = require('./_blob_gitignore_selectors');
const LicenseSelector = require('./_blob_license_selectors');

export default class FileTemplateMediator {
  constructor({ editor, currentAction }) {
    this.editor = editor;
    this.currentAction = currentAction;
    this.$filenameInput = $('.js-file-path-name-input');
    this.templateSelectors = this.initTemplateSelectors();
    this.typeSelector = this.initTemplateTypeSelector();

    this.initDropdowns();
    this.listenForFilenameChanges();
    this.prepFileContentForSubmit();
    this.initAutosizeUpdateEvent();
  }

  initTemplateTypeSelector() {
    return new FileTemplateTypeSelector({
      mediator: this,
      selectors: this.templateSelectors.map((selector) => {
        return {
          name: selector.config.name,
          key: selector.config.key,
        };
      }),
    });
  }

  initTemplateSelectors() {
    return [
      BlobCiYamlSelector,
      DockerfileSelector,
      GitignoreSelector,
      LicenseSelector,
    ].map((TemplateSelector) => {
      return new TemplateSelector({
        mediator: this,
      });
    });
  }

  initDropdowns() {
    if (this.currentAction === 'create') {
      this.typeSelector.init();
      this.showTemplateTypeSelector();
    }

    if (this.currentAction === 'edit') {
      this.typeSelector.init();
      this.typeSelector.show();
      this.updateTemplateSelectorState($('#file_path').val());
    }
  }

  reportTypeSelection(item) {
    const selectedTypeSelector = this.findSelectorByKey(item.key);
    this.selectSelector(selectedTypeSelector);
  }

  showTemplateTypeSelector() {
    this.typeSelector.show();
  }

  selectSelector(selectedTypeSelector) {
    this.templateSelectors.forEach((selector) => {
      if (selector.$dropdown !== null) {
        selector.hide();
      }
    });
    if (!selectedTypeSelector.initialized) {
      selectedTypeSelector.init();
    }
    selectedTypeSelector.show();
  }

  confirmTemplateOverwrite() {

  }

  reportTemplateSelection(selector, query, data) {
    selector.loading();
    this.fetchFileTemplate(selector.config.endpoint, query, data)
      .then((file) => {
        this.setEditorContent(file);
        selector.loaded();
      })
      .catch((err) => {
        console.log('error while fetching template content.', err);
      });
  }

  listenForFilenameChanges() {
    $('#file_path, #file_name').on('keyup blur', (e) => {
      const inputString = e.target.value;
      this.updateTemplateSelectorState(inputString);
    });
  }

  updateTemplateSelectorState(inputString) {
    this.templateSelectors.forEach((selector) => {
      const match = selector.config.pattern.test(inputString);
      if (match) {
        this.reportTypeSelection(selector.config);
        this.updateTypeSelectorState(selector.config.name);
      }
    });
  }

  updateTypeSelectorState(name) {
    this.typeSelector.$dropdown.find('.dropdown-toggle-text').text(name);
  }

  fetchFileTemplate(apiCall, query, data) {
    return new Promise((resolve) => {
      const resolveFile = file => resolve(file);

      if (!data) {
        apiCall(query, resolveFile);
      } else {
        apiCall(query, data, resolveFile);
      }
    });
  }

  setEditorContent(file, { skipFocus } = {}) {
    if (!file) return;

    const newValue = file.content;

    this.editor.setValue(newValue, 1);

    if (!skipFocus) this.editor.focus();

    if (this.editor instanceof jQuery) {
      this.editor.get(0).dispatchEvent(this.autosizeUpdateEvent);
    }
  }

  findSelectorByKey(key) {
    return this.templateSelectors.find((selector) => {
      return selector.config.key === key;
    });
  }

  initAutosizeUpdateEvent() {
    this.autosizeUpdateEvent = document.createEvent('Event');
    this.autosizeUpdateEvent.initEvent('autosize:update', true, false);
  }

  prepFileContentForSubmit() {
    $('form').submit(() => {
      $('#file-content').val(this.editor.getValue());
    });
  }
}
