((global) => {

  global.GLDropdown = {
    template: '#gl-dropdown',
    props: {
      showDropdown: {
        type: Boolean,
        twoWay: true
      },
      // HTTP data retrieval
      dataEndpoint: String,
      deferRequest: Boolean,
      requestingData: Boolean,
      // Data
      valueKey: {
        type: String,
        default: 'value'
      },
      titleKey: {
        type: String,
        default: 'title'
      },
      items: {
        type: Array,
        twoWay: true,
        default: () => []
      },
      selectedItemIndex: {
        type: Number,
        default: -1
      },
      // Hidden field
      fieldName: String,
      fieldModel: String
    },
    /**
     * On ready, loop all hardcoded slot items and add them to the default
     * items array.
     * The query order is important. Items first, then footer items. Header
     * items are queried last and separately as they must be reversed due to
     * them being unshifted ontop of the items array.
     * It then sets the global indexes of each item.
     * Lastly, if the data request is not set to defer, we invoke the
     * data request.
     */
    ready() {
      $('[slot="item"], [slot="footer-item"]', this.$el)
        .each(this.createItemFromSlot);
      $($('[slot="header-item"]', this.$el).get().reverse())
        .each(this.createItemFromSlot);
      this.setGlobalIndexes();
      if (!this.deferRequest) this.requestData();
    },
    methods: {
      // Creational
      /**
       * Invoked on ready, takes a slot item element and creates an item array
       * object using specified attributes. If the slot item has a truthy
       * non-selectable attribute, no value attribute, or already exists
       * in the items array, it will not be added to the default items array.
       * @param {Number} index - Current slot item index.
       * @param {Element} element - Current slot item element.
       */
      createItemFromSlot(index, element) {
        const $element = $(element);
        const newItem = {};
        newItem.isNonSelectable = $element.attr('non-selectable') == 'true'
        newItem[this.valueKey] = $element.attr('value');
        newItem.slotType = $element.attr('slot');
        newItem[this.titleKey] = $element.html();

        if (this.isRenderable(newItem) && this.existingIndex(newItem) === -1) {
          this.addSlotItemObject(newItem, $element);
        }
      },
      /**
       * Pushes a slot item object the the items array to be rendered
       * in the component. If the slot item is a header item, it will be
       * unshifted onto the array. The slot item DOM element is also
       * removed to avoid duplicates.
       * @param {Object} newItem - Slot item data to be rendered.
       * @param {jQuery} $element - Slot item jQuery object to be removed.
       */
      addSlotItemObject(newItem, $element) {
        if (newItem.slotType === 'header-item') {
          this.items.unshift(newItem);
        } else {
          this.items.push(newItem);
        }
        $element.remove();
      },
      /**
       * Sets the global index of each item. This simplifies a lot of functions
       * when dealing with items that are split between header, regular and
       * footer item arrays. This is because header, regular and footer item
       * arrays are computed properties, but we must perform all state changes
       * to the default items array.
       */
      setGlobalIndexes() {
        this.items.forEach((item, index) => item.globalIndex = index);
      },
      // Helpers
      /**
       * Checks the given item has the correct properties to be renderable,
       * it must be selectable and have a value attribute.
       * @param {Object} item - An item object to test.
       * @return {Boolean} - true if the item should be rendered.
       */
      isRenderable(item) {
        return !item.isNonSelectable && item[this.valueKey];
      },
      /**
       * Checks if the given item already exists in the items array by finding
       * existing items with an equal value attribute.
       * @param {Object} item - An item object to test.
       * @return {Number} - The index of an existing item with equal value,
       *                    which will be -1 if no match is found.
       */
      existingIndex(item) {
        return this.items.findIndex((existingItem) => {
          return item[this.valueKey] === existingItem[this.valueKey];
        });
      },
      /**
       * Checks the given items global index is equal to the selected index
       * meaning the given item is currently selected.
       * @param {Object} item - An item object to test.
       */
      isSelectedItem(item) {
        return item.globalIndex === this.selectedItemIndex;
      },
      // HTTP data retrieval
      /**
       * Requests data for the item array from the specific data endpoint
       * and either parses the response or handles the error.
       * @return {Promise} - A promise resolved on request response.
       */
      requestData() {
        if (!this.dataEndpoint) return;
        this.requestingData = true;
        return this.$http.get(this.dataEndpoint)
          .then((response) => {
            this.requestingData = false;
            return response;
          })
          .then(this.parseData)
          .then(null, this.handleError);
      },
      /**
       * Parses data into the default items array. This method preserves the
       * default item order, keeping header items at the beginning and
       * footer items at the end of the items array.
       * @param {Response} response - A vue-resource response object.
       */
      parseData(response) {
        let headerItems = [];
        let footerItems = [];
        let items = response.data;

        this.items.forEach((item, index) => {
          const slotType = item.slotType;
          if (slotType === 'header-item') {
            headerItems.push(item);
          } else if (slotType === 'footer-item') {
            footerItems.push(item);
          } else if (slotType === 'item') {
            items.push(item);
          }
        });

        this.items = headerItems.concat(items).concat(footerItems);
        this.setGlobalIndexes();
      },
      /**
       * TODO: Implement error handling.
       */
      handleError(error) {
        console.log(error);
      },
      // API
      /**
       * Shows the dropdown and resets its model.
       * If the data request is set to defer it also invokes the request.
       */
      openDropdown() {
        this.showDropdown = true;
        this.fieldModel = '';
        if (this.deferRequest) this.requestData();
      },
      /**
       * Hides the dropdown and resets its selected item.
       */
      closeDropdown() {
        this.selectedItemIndex = -1;
        this.showDropdown = false;
      },
      /**
       * Increments the selectedItemIndex by one if there is a
       * next item to select.
       */
      selectNextItem() {
        if(this.selectedItemIndex < this.items.length - 1) this.selectedItemIndex++;
      },
      /**
       * Decrement the selectedItemIndex by one if there is a
       * previous item to select.
       */
      selectPrevItem() {
        if(this.selectedItemIndex > -1) this.selectedItemIndex--;
      },
      /**
       * Simulates the clicking of an item by setting the model to the items
       * value. Lastly, it closes the dropdown.
       * TODO: Implement ability to click with mouse, this does not currently
       * work unless invoked directly from instance controller.
       */
      clickCurrentItem() {
        selectedItemKey = Object.keys(this.items)[this.selectedItemIndex];
        this.fieldModel = this.items[selectedItemKey][this.valueKey];
        this.closeDropdown();
      }
    },
    computed: {
      /**
       * Filters an array of only header items from the default item array.
       * @return {Object} - An array of header items.
       */
      headerItems() {
        return this.items.filter((item) => item.slotType === 'header-item');
      },
      /**
       * Filters an array of only regular items from the default item array.
       * Regular items are neither footer nor header items.
       * @return {Object} - An array of regular items.
       */
      regularItems() {
        return this.items.filter((item) => item.slotType === 'item' || !item.slotType);
      },
      /**
       * Filters an array of only footer items from the default item array.
       * @return {Object} - An array of footer items.
       */
      footerItems() {
        return this.items.filter((item) => item.slotType === 'footer-item');
      }
    }
  };

})(window.gl.GLDropdown || (window.gl.GLDropdown = {}));
