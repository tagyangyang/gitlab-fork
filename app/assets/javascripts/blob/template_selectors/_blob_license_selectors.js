/* global Api */

const FileTemplateSelector = require('./_file_template_selector');

class BlobLicenseSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'license',
      name: 'License',
      pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/,
      endpoint: Api.licenseText,
      dropdown: '.js-license-selector',
      wrapper: '.js-license-selector-wrap',
    };
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.$dropdown.data('data'),
      filterable: true,
      selectable: true,
      toggleLabel: item => item.name,
      search: {
        fields: ['name'],
      },
      clicked: (query, el, e) => {
        const data = {
          project: this.$dropdown.data('project'),
          fullname: this.$dropdown.data('fullname'),
        };

        this.reportSelection(query.id, el, e, data);
      },
      text: item => item.name,
    });
  }
}

module.exports = BlobLicenseSelector;
