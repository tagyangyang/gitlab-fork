import FilterableList from './filterable_list';

/**
 * Makes search request for projects when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */
export default class ProjectsList {
  constructor() {
    const form = document.querySelector('form#project-filter-form');
    const filter = document.querySelector('.js-projects-list-filter');
    const holder = document.querySelector('.js-projects-list-holder');
    const dropdownLinks = document.querySelectorAll('.nav-controls .dropdown a');
    const filterName = 'name';

    if (form && filter && holder) {
      const list = new FilterableList(form, filter, holder, dropdownLinks, filterName);
      list.initSearch();
    }
  }
}
