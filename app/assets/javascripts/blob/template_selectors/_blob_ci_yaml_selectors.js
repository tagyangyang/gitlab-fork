/* global Api */

const FileTemplateSelector = require('./_file_template_selector');

class BlobCiYamlSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'gitlab-ci-yaml',
      name: 'GitLab CI Yaml',
      pattern: /(.gitlab-ci.yml)/,
      endpoint: Api.gitlabCiYml,
      dropdown: '.js-gitlab-ci-yml-selector',
      loading: 'fa-chevron-down',
      wrapper: '.js-gitlab-ci-yml-selector-wrap',
    };
  }

  initDropdown() {
    // maybe move to super class as well
    this.$dropdown.glDropdown({
      data: this.$dropdown.data('data'),
      filterable: true,
      selectable: true,
      toggleLabel: item => item.name,
      search: {
        fields: ['name'],
      },
      clicked: (query, el, e) => this.reportSelection(query.name, el, e),
      text: item => item.name,
    });
  }
}

module.exports = BlobCiYamlSelector;