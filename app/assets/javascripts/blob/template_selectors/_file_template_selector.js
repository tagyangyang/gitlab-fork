/* global Api */

class FileTemplateSelector {
  constructor(mediator) {
    this.mediator = mediator;
    this.$dropdown = null;
    this.$wrapper = null;
    this.initialized = false;
  }

  init() {
    const cfg = this.config;

    this.$dropdown = $(cfg.dropdown);
    this.$wrapper = $(cfg.wrapper);
    this.$loadingIcon = this.$wrapper.find('.fa-chevron-down');

    this.initDropdown();
    this.initialized = true;
  }

  show() {
    if (this.$dropdown === null) {
      this.init();
    }

    this.$wrapper.removeClass('hidden');
  }

  hide() {
    // super class
    if (this.$dropdown !== null) {
      this.$wrapper.addClass('hidden');
    }
  }

  loading() {
    // superclass
    this.$loadingIcon
      .addClass('fa-spinner fa-spin')
      .removeClass('fa-chevron-down');
  }

  loaded() {
    this.$loadingIcon
      .addClass('fa-chevron-down')
      .removeClass('fa-spinner fa-spin');
  }

  reportSelection(query, el, e, data) {
    e.preventDefault();
    return this.mediator.reportTemplateSelection(this, query.name, data);
  }
}

module.exports = FileTemplateSelector;
