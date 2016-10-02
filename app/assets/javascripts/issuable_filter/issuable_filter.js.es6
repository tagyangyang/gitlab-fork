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
        // authorDropdown: { show: false },
        // assigneeDropdown: { show: false },
        // milestoneDropdown: { show: false },
        labelDropdown: {},
        // weightDropdown: { show: false }
      },
      modelWatch: {},
      activeFilters: []
    },
    methods: {
      openFilterDropdown() {
        this.closeFilterDropdowns();
        this.$refs[DEFAULT_DROPDOWN].openDropdown();
        this.initFieldWatchers();
      },
      closeFilterDropdowns() {
        for (const dropdownReference in this.dropdown) {
          this.$refs[dropdownReference].closeDropdown();
        }
        this.currentDropdown = DEFAULT_DROPDOWN;
      },
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
      openSelectedDropdown(clickedDropdownItem) {
        if (!clickedDropdownItem) return;
        this.$refs[clickedDropdownItem].openDropdown();
        this.currentDropdown = clickedDropdownItem;
      },
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
      submitFilters() {
        console.log('submitFilters');
      },
      initFieldWatchers() {
        this.registerFieldWatch('filterDropdown', () => {
          return this.$refs.filterDropdown.fieldModel;
        }, this.openSelectedDropdown);

        this.registerFieldWatch('labelDropdown', () => {
          return this.$refs.labelDropdown.fieldModel;
        }, (filterValue) => {
          this.addFilter('label', filterValue);
        });
      },
      registerFieldWatch(watchName, observable, updateAction) {
        if (this.modelWatch[watchName]) return;
        this.modelWatch[watchName] = this.$watch(observable, updateAction);
      }
    }
  });
});
