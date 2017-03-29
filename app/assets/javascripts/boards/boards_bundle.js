/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */
/* global BoardService */

import Vue from 'vue';
import VueResource from 'vue-resource';
import FilteredSearchBoards from './filtered_search_boards';
import eventHub from './eventhub';

require('./models/issue');
require('./models/label');
require('./models/list');
require('./models/milestone');
require('./models/user');
require('./stores/boards_store');
require('./stores/modal_store');
require('./services/board_service');
require('./mixins/modal_mixins');
require('./mixins/sortable_default_options');
require('./filters/due_date_filters');
require('./components/board');
require('./components/board_sidebar');
require('./components/new_list_dropdown');
require('./components/modal/index');
require('../vue_shared/vue_resource_interceptor');

Vue.use(VueResource);

$(() => {
  const $boardApp = document.getElementById('board-app');
  const Store = gl.issueBoards.BoardsStore;
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  Store.create();

  gl.IssueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      'board': gl.issueBoards.Board,
      'board-sidebar': gl.issueBoards.BoardSidebar,
      'board-add-issues-modal': gl.issueBoards.IssuesModal,
    },
    data: {
      state: Store.state,
      loading: true,
      endpoint: $boardApp.dataset.endpoint,
      boardId: $boardApp.dataset.boardId,
      disabled: $boardApp.dataset.disabled === 'true',
      issueLinkBase: $boardApp.dataset.issueLinkBase,
      rootPath: $boardApp.dataset.rootPath,
      bulkUpdatePath: $boardApp.dataset.bulkUpdatePath,
      detailIssue: Store.detail
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created () {
      gl.boardService = new BoardService(this.endpoint, this.bulkUpdatePath, this.boardId);

      this.filterManager = new FilteredSearchBoards(Store.filter, true);

      // Listen for updateTokens event
      eventHub.$on('updateTokens', this.updateTokens);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
    },
    mounted () {
      Store.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          resp.json().forEach((board) => {
            const list = Store.addList(board);

            if (list.type === 'closed') {
              list.position = Infinity;
            }
          });

          this.state.lists = _.sortBy(this.state.lists, 'position');

          Store.addBlankState();
          this.loading = false;
        })
        .catch(() => {
          this.loading = false;
        });
    },
    methods: {
      updateTokens() {
        this.filterManager.updateTokens();
      }
    },
  });

  gl.IssueBoardsSearch = new Vue({
    el: document.getElementById('js-add-list'),
    data: {
      filters: Store.state.filters
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    }
  });

  gl.IssueBoardsModalAddBtn = new Vue({
    mixins: [gl.issueBoards.ModalMixins],
    el: document.getElementById('js-add-issues-btn'),
    data: {
      modal: ModalStore.store,
      store: Store.state,
    },
    watch: {
      disabled() {
        this.updateTooltip();
      },
    },
    computed: {
      disabled() {
        return !this.store.lists.filter(list => list.type !== 'blank' && list.type !== 'done').length;
      },
      tooltipTitle() {
        if (this.disabled) {
          return 'Please add a list to your board first';
        }

        return '';
      },
    },
    methods: {
      updateTooltip() {
        const $tooltip = $(this.$el);

        this.$nextTick(() => {
          if (this.disabled) {
            $tooltip.tooltip();
          } else {
            $tooltip.tooltip('destroy');
          }
        });
      },
      openModal() {
        if (!this.disabled) {
          this.toggleModal(true);
        }
      },
    },
    mounted() {
      this.updateTooltip();
    },
    template: `
      <button
        class="btn btn-create pull-right prepend-left-10"
        type="button"
        data-placement="bottom"
        :class="{ 'disabled': disabled }"
        :title="tooltipTitle"
        :aria-disabled="disabled"
        @click="openModal">
        Add issues
      </button>
    `,
  });
});
