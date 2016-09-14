((global) => {
  class GLOverflowDropdown {
    constructor($table, $dropdown) {
      const MENU_MAX_HEIGHT = 250;

      this.$table = $table;
      this.$dropdownToggle = $('.dropdown-toggle', $dropdown);
      this.$dropdownMenu = $('.dropdown-menu', $dropdown);
      this.positioned = false;

      this.$dropdownMenu.css({
        'max-height': MENU_MAX_HEIGHT,
        overflow: 'scroll'
      });

      $dropdown.off('click.positionDropdownWithinTable')
        .on('click.positionDropdownWithinTable', this.positionDropdownWithinTable.bind(this));
    }

    positionDropdownWithinTable() {
      if (this.positioned) return;
      const dropdownMenuHeight = this.$dropdownMenu.outerHeight(true);
      if ((this.$dropdownToggle.offset().top - this.$table.offset().top + this.$dropdownToggle.outerHeight() + dropdownMenuHeight) > this.$table.outerHeight()) {
        this.$dropdownMenu.css({ top: -(dropdownMenuHeight + 3) });
      }
      this.positioned = true;
    }
  }

  global.GLOverflowDropdown = GLOverflowDropdown;

  $.fn.glOverflowDropdown = function($dropdowns) {
    const $table = this;
    $dropdowns = $dropdowns || $('.gl-overflow-dropdown', $table);
    $dropdowns.each(function() {
      if (!$.data(this, 'glOverflowDropdown')) {
        $.data(this, 'glOverflowDropdown', new global.GLOverflowDropdown($table, $(this)));
      }
    });
  };
})(window.gl || (window.gl = {}));
