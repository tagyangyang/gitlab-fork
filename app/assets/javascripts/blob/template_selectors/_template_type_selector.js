const FileTemplateSelector = require('./_file_template_selector');

class TemplateTypeSelector extends FileTemplateSelector {
  constructor({ mediator, selectors }) {
    super(mediator);
    this.mediator = mediator;
    this.config = {
      dropdown: '.js-template-type-selector',
      wrapper: '.js-template-type-selector-wrap',
      selectors: selectors,
    };
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.config.selectors,
      filterable: false,
      selectable: true,
      toggleLabel: item => item.name,
      clicked: (item, el, e) => this.mediator.reportTypeSelection(item, el, e),
      text: item => item.name,
    });
  }

}

module.exports = TemplateTypeSelector;