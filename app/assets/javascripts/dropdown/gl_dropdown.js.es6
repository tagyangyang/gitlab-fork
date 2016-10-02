((global) => {

  const DEFAULT_SELECTED_ITEM_INDEX = -1;
  const SELECTION_OUT_OF_BOUNDS_INDEX = -2;

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
      headerItems: {
        type: Array,
        twoWay: true,
        default: () => []
      },
      footerItems: {
        type: Array,
        twoWay: true,
        default: () => []
      },
      selectedItemIndex: {
        type: Number,
        default: DEFAULT_SELECTED_ITEM_INDEX
      },
      selectedHeaderItemIndex: {
        type: Number,
        default: DEFAULT_SELECTED_ITEM_INDEX
      },
      selectedFooterItemIndex: {
        type: Number,
        default: DEFAULT_SELECTED_ITEM_INDEX
      },
      // Hidden field
      fieldName: String,
      fieldModel: String
    },
    ready() {
      $('[slot="header-item"], [slot="item"], [slot="footer-item"]', this.$el)
        .each(this.addSlotItem);
      if (!this.deferRequest) this.requestData();
    },
    methods: {
      // Creational
      addSlotItem(index, element) {
        const $element = $(element);
        const newItem = { isNonSelectable: $element.attr('non-selectable') };
        newItem[this.valueKey] = $element.attr('value');
        if (newItem.isNonSelectable || !newItem[this.valueKey]) return;
        newItem[this.titleKey] = $element.html();
        const existingIndex = this.items.findIndex((existingItem) => {
          newItem[this.valueKey] === existingItem[this.valueKey];
        });
        if (existingIndex === DEFAULT_SELECTED_ITEM_INDEX) {
          this.addSlotItemToData(newItem, $element);
        }
      },
      addSlotItemToData(newItem, $element) {
        const slotName = $element.attr('slot');
        let itemArray = {};
        switch (slotName) {
          case 'header-item':
            itemArray = this.headerItems;
            break;
          case 'item':
            itemArray = this.items;
            break;
          case 'footer-item':
            itemArray = this.footerItems;
            break;
        }
        itemArray.push(newItem);
        $element.remove();
      },
      // HTTP data retrieval
      requestData() {
        if (!this.dataEndpoint) return;
        return this.$http.get(this.dataEndpoint)
          .then(this.parseDataResponse)
          .then(null, this.handleError);
      },
      parseDataResponse(response) {
        console.log(response);
        this.items = response.data;
      },
      handleError(error) {
        console.log(error);
      },
      // API
      openDropdown() {
        this.showDropdown = true;
        this.fieldModel = '';
        if (this.deferRequest) this.requestData();
      },
      closeDropdown() {
        this.selectedItemIndex = DEFAULT_SELECTED_ITEM_INDEX;
        this.showDropdown = false;
      },
      selectNextItem() {
        const headerItemsLength = this.headerItems.length - 1;
        const itemsLength = this.items.length - 1;
        const footerItemsLength = this.footerItems.length - 1;
        if (this.selectedHeaderItemIndex < headerItemsLength && this.selectedHeaderItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX && headerItemsLength) {
          return this.selectedHeaderItemIndex++;
        } else if (itemsLength !== -1 && this.selectedHeaderItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX) {
          this.selectedHeaderItemIndex = SELECTION_OUT_OF_BOUNDS_INDEX;
        }
        if (this.selectedItemIndex < itemsLength && this.selectedHeaderItemIndex === SELECTION_OUT_OF_BOUNDS_INDEX && this.selectedItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX && itemsLength) {
          return this.selectedItemIndex++;
        } else if (footerItemsLength !== -1 && this.selectedItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX) {
          this.selectedItemIndex = SELECTION_OUT_OF_BOUNDS_INDEX;
        }
        if (this.selectedFooterItemIndex < footerItemsLength && this.selectedItemIndex === SELECTION_OUT_OF_BOUNDS_INDEX && footerItemsLength) {
          this.selectedFooterItemIndex++;
        }
      },
      selectPrevItem() {
        const headerItemsLength = this.headerItems.length - 1;
        const itemsLength = this.items.length - 1;
        const footerItemsLength = this.footerItems.length - 1;
        if (this.selectedHeaderItemIndex <= headerItemsLength && this.selectedHeaderItemIndex !== DEFAULT_SELECTED_ITEM_INDEX && this.selectedHeaderItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX) {
          this.selectedHeaderItemIndex--;
        } else if(this.selectedHeaderItemIndex === SELECTION_OUT_OF_BOUNDS_INDEX && this.selectedItemIndex === 0) {
          this.selectedItemIndex--;
          return this.selectedHeaderItemIndex = headerItemsLength;
        }
        if (this.selectedItemIndex <= itemsLength && this.selectedItemIndex !== DEFAULT_SELECTED_ITEM_INDEX && this.selectedItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX) {
          this.selectedItemIndex--;
        } else if(this.selectedItemIndex === SELECTION_OUT_OF_BOUNDS_INDEX && this.selectedFooterItemIndex === 0) {
          this.selectedFooterItemIndex--;
          return this.selectedItemIndex = itemsLength;
        }
        if (this.selectedFooterItemIndex <= footerItemsLength && this.selectedFooterItemIndex !== DEFAULT_SELECTED_ITEM_INDEX && this.selectedFooterItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX) {
          this.selectedFooterItemIndex--;
        }
      },
      clickCurrentItem(selectedItemIndex, selectedItemList) {
        if (this.selectedHeaderItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX && this.selectedHeaderItemIndex !== DEFAULT_SELECTED_ITEM_INDEX) {
          selectedItemIndex = this.selectedHeaderItemIndex;
          selectedItemList = this.headerItems;
        } else if (this.selectedItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX && this.selectedItemIndex !== DEFAULT_SELECTED_ITEM_INDEX) {
          selectedItemIndex = this.selectedItemIndex;
          selectedItemList = this.items;
        } else if (this.selectedFooterItemIndex !== SELECTION_OUT_OF_BOUNDS_INDEX && this.selectedFooterItemIndex !== DEFAULT_SELECTED_ITEM_INDEX) {
          selectedItemKey = this.selectedFooterItemIndex;
          selectedItemList = this.footerItems;
        }
        selectedItemKey = Object.keys(selectedItemList)[selectedItemIndex];
        this.fieldModel = selectedItemList[selectedItemKey][this.valueKey];
        this.closeDropdown();
      }
    }
  };

})(window.gl.GLDropdown || (window.gl.GLDropdown = {}));
