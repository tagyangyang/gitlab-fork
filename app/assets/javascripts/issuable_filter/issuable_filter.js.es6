//= require vue
//= require vue-resource
//= require_tree ../dropdown

$(() => {
  const global = window.gl || (window.gl = {});
  const GLDropdown = global.GLDropdown;

  const KEY = {
    BACKSPACE: 8,
    ENTER: 13,
    ESC: 27,
    LEFT: 37,
    UP: 38,
    RIGHT: 39,
    DOWN: 40
  };

  const DEFAULT_DROPDOWN = 'filterDropdown';

  new Vue({
    el: '.js-issuable-filter',
    components: {
      'gl-dropdown': GLDropdown.GLDropdown,
      'filter-dropdown-item': GLDropdown.FilterDropdownItem
    },
    data: {
      currentDropdown: DEFAULT_DROPDOWN,
      dropdown: {
        filterDropdown: {},
        // TODO: authorDropdown: {},
        // TODO: assigneeDropdown: {},
        // TODO: milestoneDropdown: {},
        labelDropdown: {},
        // TODO: weightDropdown: {}
      },
      modelObserver: {},
      activeFilters: []
    },
    methods: {
      /**
       * Opens the default filter dropdown as well as closing any other
       * open dropdowns.
       * Lastly, initialise the field model observers.
       */
      openFilterDropdown() {
        this.closeFilterDropdowns();
        this.$refs[DEFAULT_DROPDOWN].openDropdown();
        this.initFieldObservers();
      },
      /**
       * Closes all dropdowns and sets the current dropdown to default.
       */
      closeFilterDropdowns() {
        for (const dropdownReference in this.dropdown) {
          this.$refs[dropdownReference].closeDropdown();
        }
        this.currentDropdown = DEFAULT_DROPDOWN;
      },
      /**
       * Handle a keyup event from the filter input.
       * On up: Select the previous item of the current dropdown.
       * On down: Select the next item of the current dropdown.
       * On enter: Click the current item of the current dropdown.
       * On esc: Close the dropdowns and open the default dropdown.
       * @param {Event} event - A keyup event object from the filter input.
       */
      filterInputKeyup(event) {
        const keycode = event.keyCode || event.which;
        switch (keycode) {
          case KEY.UP:
            this.$refs[this.currentDropdown].selectPrevItem();
            break;
          case KEY.DOWN:
            this.$refs[this.currentDropdown].selectNextItem();
            break;
          case KEY.ENTER:
            this.$refs[this.currentDropdown].clickCurrentItem();
            break;
          case KEY.ESC:
            this.openFilterDropdown()
            break;
        }
      },
      /**
       * Opens the dropdown specified from the value of the clicked dropdown
       * item from the default filter dropdown.
       * @param {String} clickedDropdownItem - The value of a clicked item,
       *                    which is a reference to a specific dropdown to open.
       */
      openSelectedDropdown(clickedDropdownItem) {
        if (!clickedDropdownItem) return;
        this.$refs[clickedDropdownItem].openDropdown();
        this.currentDropdown = clickedDropdownItem;
      },
      /**
       * Adds a filter to the active filters array using the updated value of
       * the filters model of the current dropdown.
       * @param {String} filterType - The type of filter, specified by the
       *                            specific filters model observer.
       * @param {String} filterValue - The new value of the filter model.
       */
      // TODO: Split into other methods, probably.
      addFilter(filterType, filterValue) {
        if (!filterValue) return;
        const { valueKey, titleKey } = this.$refs[this.currentDropdown];
        const filterItem = this.$refs[this.currentDropdown].items.find((item) => {
          return item[valueKey] === filterValue;
        });
        const filter = {
          type: filterType,
          value: filterValue,
          title: filterItem[titleKey]
        };
        this.activeFilters.push(filter);
        this.closeFilterDropdowns()
        this.$refs[this.currentDropdown].openDropdown();
      },
      /**
       * TODO: Implement submit method.
       */
      submitFilters() {
        console.log('submitFilters');
      },
      /**
       * Initialises all required model observers that watch for updates in
       * a specific dropdowns model and adds the updated filter values to the
       * active filters.
       */
      initFieldObservers() {
        this.registerFieldObserver('filterDropdown', () => {
          return this.$refs.filterDropdown.fieldModel;
        }, this.openSelectedDropdown);

        this.registerFieldObserver('labelDropdown', () => {
          return this.$refs.labelDropdown.fieldModel;
        }, (filterValue) => {
          this.addFilter('label', filterValue);
        });
      },
      /**
       * Checks an observer of a specific name is not already active and if not
       * creates an observer for the specified observable and action.
       * @param {String} observerName - The unique name of the observer.
       * @param {Function} observable - A function returning an observable
       *                              entity.
       * @param {Function} updateAction - A function to invoke when the
       *                                observable entity value updates.
       */
      registerFieldObserver(observerName, observable, updateAction) {
        if (this.modelObserver[observerName]) return;
        this.modelObserver[observerName] = this.$watch(observable, updateAction);
      }
    }
  });
});
