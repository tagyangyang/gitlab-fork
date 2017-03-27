/**
 * Makes search request for content when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */

import '~/lib/utils/url_utility';

export default class FilterableList {
  constructor(form, filter, holder, dropdownLinks, filterName) {
    this.filterForm = form;
    this.listFilterElement = filter;
    this.listHolderElement = holder;
    this.dropdownLinks = dropdownLinks;
    this.filterName = filterName;
  }

  initSearch() {
    this.debounceFilter = _.debounce(this.filterResults.bind(this), 500);

    this.listFilterElement.removeEventListener('input', this.debounceFilter);
    this.listFilterElement.addEventListener('input', this.debounceFilter);
  }

  filterResults() {
    const form = this.filterForm;
    const filterUrl = `${form.getAttribute('action')}?${$(form).serialize()}`;

    $(this.listHolderElement).fadeTo(250, 0.5);

    return $.ajax({
      url: form.getAttribute('action'),
      data: $(form).serialize(),
      type: 'GET',
      dataType: 'json',
      context: this,
      complete() {
        $(this.listHolderElement).fadeTo(250, 1);
      },
      success(data) {
        this.listHolderElement.innerHTML = data.html;

       // Change url so if user reload a page - search results are saved
        window.history.replaceState({
          page: filterUrl,
        }, document.title, filterUrl);

        this.updateDropdownLinks();
      },
    });
  }

  updateDropdownLinks() {
    [].forEach.call(this.dropdownLinks, (item) => {
      const href = gl.utils.updateParamQueryString(
        item.href,
        this.filterName,
        this.listFilterElement.value,
      );
      item.setAttribute('href', href);
    });
  }
}
