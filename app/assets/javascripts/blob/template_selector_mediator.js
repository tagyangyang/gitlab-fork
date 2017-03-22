/* eslint-disable class-methods-use-this no-new */
/* global Flash */

import FileTemplateTypeSelector from './template_selectors/type_selector';
import BlobCiYamlSelector from './template_selectors/ci_yaml_selector';
import DockerfileSelector from './template_selectors/dockerfile_selector';
import GitignoreSelector from './template_selectors/gitignore_selector';
import LicenseSelector from './template_selectors/license_selector';

export default class FileTemplateMediator {
  constructor({ editor, currentAction }) {
    this.editor = editor;
    this.currentAction = currentAction;
    this.$filenameInput = $('.js-file-path-name-input');

    this.templateSelectors = this.registerFileTemplateSelectors();
    this.typeSelector = this.registerTemplateTypeSelector();

    this.initDropdowns();
    this.initPageEvents();
    this.cacheFileContent();
  }

  initDropdowns() {
    if (this.currentAction === 'create') {
      this.typeSelector.show();
      this.checkForMatchingTemplate();
    }

    if (this.currentAction === 'edit') {
      this.typeSelector.show();
      this.checkForMatchingTemplate();
    }
  }

  initPageEvents() {
    this.listenForFilenameInput();
    this.prepFileContentForSubmit();
    this.initAutosizeUpdateEvent();
  }

  cacheFileContent() {
    this.initialContent = this.editor.getValue();
    this.initialTitle = this.$filenameInput.val();
  }

  enableUndoTemplate() {
    $('.template-undo').removeClass('hidden');
    $('.template-undo button').on('click', (e) => {
      this.setEditorContent(this.initialContent);
      this.setFilename(this.initialTitle);
    });
  }

  registerTemplateTypeSelector() {
    return new FileTemplateTypeSelector({
      mediator: this,
      dropdownData: this.templateSelectors
        .map((templateSelector) => {
          const cfg = templateSelector.config;

          return {
            name: cfg.name,
            key: cfg.key,
          };
        }),
    });
  }

  registerFileTemplateSelectors() {
    return [BlobCiYamlSelector, DockerfileSelector, GitignoreSelector, LicenseSelector]
      .map(TemplateSelectorClass => new TemplateSelectorClass({ mediator: this }));
  }

  selectTemplateType(item) {
    const selectedTemplateSelector = this.findSelectorByKey(item.key);

    this.templateSelectors.forEach((selector) => {
      if (selector.$dropdown !== null) {
        selector.hide();
      }
    });

    selectedTemplateSelector.show();

    this.typeSelector.$dropdown
      .find('.dropdown-toggle-text')
      .text(item.name);
  }

  selectTemplateFile(selector, query, data) {
    selector.loading();

    this.fetchFileTemplate(selector.config.endpoint, query, data)
      .then((file) => {
        if (this.currentAction === 'edit') {
          this.enableUndoTemplate();
        }
        this.setEditorContent(file);
        this.setFilename(selector.config.name);
        selector.loaded();
      })
      .catch(err => new Flash(`An error occurred while fetching the template: ${err}`));
  }

  checkForMatchingTemplate() {
    const currentInput = this.$filenameInput.val();
    this.templateSelectors.forEach((selector) => {
      const match = selector.config.pattern.test(currentInput);

      if (match) {
        // Need to handle when filename changes after having matched
        this.selectTemplateType(selector.config);
      }
    });
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

  getFilename() {
    return this.$filenameInput.val();
  }

  setFilename(name) {
    this.$filenameInput.val(name);
  }

  setEditorContent(file, { skipFocus } = {}) {
    if (!file) return;

    const newValue = file.content || file;

    this.editor.setValue(newValue, 1);

    if (!skipFocus) this.editor.focus();

    if (this.editor instanceof jQuery) {
      this.editor.get(0).dispatchEvent(this.autosizeUpdateEvent);
    }

    this.editor.navigateFileStart();
  }

  findSelectorByKey(key) {
    return this.templateSelectors.find((selector) => {
      return selector.config.key === key;
    });
  }

  listenForFilenameInput() {
    this.$filenameInput.on('keyup blur', (e) => {
      this.checkForMatchingTemplate();
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
