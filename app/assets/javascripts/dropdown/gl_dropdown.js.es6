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
     * On ready, loop all hardcoded slot items and add them to the renderable
     * items array.
     * The query order is important. Items first, then footer items. Header
     * items are queried last and separately as they must be reversed due to
     * them being unshifted ontop of the items array.
     * Lastly, if the data request is not set to defer, we invoke the
     * data request.
     */
    ready() {
      $('[slot="item"], [slot="footer-item"]', this.$el)
        .each(this.createRenderableFromSlotItem);
      $($('[slot="header-item"]', this.$el).get().reverse())
        .each(this.createRenderableFromSlotItem);
      if (!this.deferRequest) this.requestData();
    },
    methods: {
      // Creational
      /**
       * Invoked on ready, takes a slot item element and creates an item array
       * object using specified attributes. If the slot item has a truthy
       * non-selectable attribute, no value attribute, or already exists
       * in the items array, it will not be added to the renderable items array.
       * @param {Number} index - Current slot item index.
       * @param {Element} element - Current slot item element.
       */
      createRenderableFromSlotItem(index, element) {
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
      // Helpers
      /**
       * Checks the given item has the correct properties to be renderable,
       * it must be selectable and have a value attribute.
       * @param {Object} item - A renderable item object to test.
       * @return {Boolean} - true if the item should be rendered.
       */
      isRenderable(item) {
        return !item.isNonSelectable && item[this.valueKey];
      },
      /**
       * Checks if the given item already exists in the items array by finding
       * existing items with an equal value attribute.
       * @param {Object} item - A renderable item object to test.
       * @return {Number} - The index of an existing item with equal value,
       *                    which will be -1 if no match is found.
       */
      existingIndex(item) {
        return this.items.findIndex((existingItem) => {
          return item[this.valueKey] === existingItem[this.valueKey];
        });
      },
      // HTTP data retrieval
      /**
       * Requests data for the item array from the specific data endpoint
       * and either parses the response or handles the error.
       * @return {Promise} - A promise resolved on request response.
       */
      requestData() {
        if (!this.dataEndpoint) return;
        return this.$http.get(this.dataEndpoint)
          .then(this.parseData)
          .then(null, this.handleError);
      },
      /**
       * Parses data into the renderable items array. This method preserves the
       * default item order, keeping header items at the beginning and
       * footer items at the end of the items array.
       * @param {Response} response - A vue-resource response object.
       */
      parseData(response) {
        let headerItems = [];
        let footerItems = [];
        let items = response.data;

        this.items.forEach((item) => {
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
    }
  };

})(window.gl.GLDropdown || (window.gl.GLDropdown = {}));
