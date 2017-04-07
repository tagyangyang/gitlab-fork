/* global Sortable */
import boardNewIssue from './board_new_issue';
import boardCard from './board_card';
import eventHub from '../eventhub';

const Store = gl.issueBoards.BoardsStore;

export default {
  name: 'BoardList',
  props: {
    disabled: {
      type: Boolean,
      required: true,
    },
    list: {
      type: Object,
      required: true,
    },
    issues: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      scrollOffset: 250,
      filters: Store.state.filters,
      showCount: false,
      showIssueForm: false,
    };
  },
  components: {
    boardCard,
    boardNewIssue,
  },
  methods: {
    listHeight() {
      return this.$refs.list.getBoundingClientRect().height;
    },
    scrollHeight() {
      return this.$refs.list.scrollHeight;
    },
    scrollTop() {
      return this.$refs.list.scrollTop + this.listHeight();
    },
    loadNextPage() {
      const getIssues = this.list.nextPage();

      if (getIssues) {
        this.list.loadingMore = true;
        getIssues.then(() => {
          this.list.loadingMore = false;
        });
      }
    },
    toggleForm() {
      this.showIssueForm = !this.showIssueForm;
    },
    onScroll() {
      if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.list.loadingMore) {
        this.loadNextPage();
      }
    },
  },
  watch: {
    filters: {
      handler() {
        this.list.loadingMore = false;
        this.$refs.list.scrollTop = 0;
      },
      deep: true,
    },
    issues() {
      this.$nextTick(() => {
        if (this.scrollHeight() <= this.listHeight() &&
          this.list.issuesSize > this.list.issues.length) {
          this.list.page += 1;
          this.list.getIssues(false);
        }

        if (this.scrollHeight() > Math.ceil(this.listHeight())) {
          this.showCount = true;
        } else {
          this.showCount = false;
        }
      });
    },
  },
  created() {
    eventHub.$on(`hide-issue-form-${this.list.id}`, this.toggleForm);
  },
  mounted() {
    const options = gl.issueBoards.getBoardSortableDefaultOptions({
      scroll: document.querySelectorAll('.boards-list')[0],
      group: 'issues',
      disabled: this.disabled,
      filter: '.board-list-count, .is-disabled',
      dataIdAttr: 'data-issue-id',
      onStart: (e) => {
        const card = this.$refs.issue[e.oldIndex];

        card.showDetail = false;
        Store.moving.list = card.list;
        Store.moving.issue = Store.moving.list.findIssue(+e.item.dataset.issueId);

        gl.issueBoards.onStart();
      },
      onAdd: (e) => {
        gl.issueBoards.BoardsStore
          .moveIssueToList(Store.moving.list, this.list, Store.moving.issue, e.newIndex);

        this.$nextTick(() => {
          e.item.remove();
        });
      },
      onUpdate: (e) => {
        const sortedArray = this.sortable.toArray().filter(id => id !== '-1');
        gl.issueBoards.BoardsStore
          .moveIssueInList(this.list, Store.moving.issue, e.oldIndex, e.newIndex, sortedArray);
      },
      onMove(e) {
        return !e.related.classList.contains('board-list-count');
      },
    });

    this.sortable = Sortable.create(this.$refs.list, options);

    // Scroll event on list to load more
    this.$refs.list.addEventListener('scroll', this.onScroll);
  },
  beforeDestroy() {
    eventHub.$off(`hide-issue-form-${this.list.id}`, this.toggleForm);
    this.$refs.list.removeEventListener('scroll', this.onScroll);
  },
  template: `
    <div class="board-list-component">
      <div
        class="board-list-loading text-center"
        aria-label="Loading issues"
        v-if="loading">
        <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true">
        </i>
      </div>
      <board-new-issue
        :list="list"
        v-if="list.type !== 'closed' && showIssueForm"/>
      <ul
        class="board-list"
        v-show="!loading"
        ref="list"
        :data-board="list.id"
        :class="{ 'is-smaller': showIssueForm }">
        <board-card
          v-for="(issue, index) in issues"
          ref="issue"
          :index="index"
          :list="list"
          :issue="issue"
          :issue-link-base="issueLinkBase"
          :root-path="rootPath"
          :disabled="disabled"
          :key="issue.id" />
        <li
          class="board-list-count text-center"
          v-if="showCount"
          data-id="-1">
          <i
            class="fa fa-spinner fa-spin"
            aria-label="Loading more issues"
            aria-hidden="true"
            v-show="list.loadingMore">
          </i>
          <span v-if="list.issues.length === list.issuesSize">
            Showing all issues
          </span>
          <span v-else>
            Showing {{ list.issues.length }} of {{ list.issuesSize }} issues
          </span>
        </li>
      </ul>
    </div>
  `,
};
