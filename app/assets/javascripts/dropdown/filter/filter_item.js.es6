((global) => {

    global.FilterDropdownItem = {
      template: '#filter-dropdown-item',
      props: {
        slot: String,
        value: String,
        icon: String,
        title: String,
        subtitle: String
      }
    };

})(window.gl.GLDropdown || (window.gl.GLDropdown = {}));
