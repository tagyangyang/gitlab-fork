/* eslint-disable comma-dangle, func-names, no-new, space-before-function-paren, one-var */

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  const Store = gl.issueBoards.BoardsStore;

  $(document).off('created.label').on('created.label', (e, label) => {
    Store.new({
      title: label.title,
      position: Store.state.lists.length - 2,
      list_type: 'label',
      label: {
        id: label.id,
        title: label.title,
        color: label.color
      }
    });
  });

  gl.issueBoards.newListDropdownInit = () => {
    $('.js-new-board-list').each(function () {
      const $this = $(this);
      new gl.CreateLabelDropdown($this.closest('.dropdown').find('.dropdown-new-label'), $this.data('namespace-path'), $this.data('project-path'));

      $this.glDropdown({
        data(term, callback) {
          $.get($this.attr('data-labels'))
            .then((resp) => {
              callback(resp);
            })
            .catch(() => {
              // An empty catch!
            });
        },
        renderRow (label) {
          const active = Store.findList('title', label.title);
          const $li = $('<li />');
          const $a = $('<a />', {
            class: (active ? `is-active js-board-list-${active.id}` : ''),
            text: label.title,
            href: '#'
          });
          const $labelColor = $('<span />', {
            class: 'dropdown-label-box',
            style: `background-color: ${label.color}`
          });

          return $li.append($a.prepend($labelColor));
        },
        search: {
          fields: ['title']
        },
        filterable: true,
        selectable: true,
        multiSelect: true,
        clicked (label, $el, e) {
          e.preventDefault();

          if (!Store.findList('title', label.title)) {
            Store.new({
              title: label.title,
              position: Store.state.lists.length - 2,
              list_type: 'label',
              label: {
                id: label.id,
                title: label.title,
                color: label.color
              }
            });

            Store.state.lists = _.sortBy(Store.state.lists, 'position');
          }
        }
      });
    });
  };
})();
