/* global ListIssue */

import Vue from 'vue';
import queryData from '../../utils/query_data';

require('./header');
require('./list');
require('./footer');
require('./empty_state');

(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.IssuesModal = Vue.extend({
    props: {
      blankStateImage: {
        type: String,
        required: true,
      },
      newIssuePath: {
        type: String,
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
      projectId: {
        type: Number,
        required: true,
      },
      milestonePath: {
        type: String,
        required: true,
      },
      labelPath: {
        type: String,
        required: true,
      },
    },
    data() {
      return ModalStore.store;
    },
    watch: {
      page() {
        this.loadIssues();
      },
      showAddIssuesModal() {
        if (this.showAddIssuesModal && !this.issues.length) {
          this.loading = true;

          this.loadIssues()
            .then(() => {
              this.loading = false;
            })
            .catch(() => {
              this.loading = false;
            });
        } else if (!this.showAddIssuesModal) {
          this.issues = [];
          this.selectedIssues = [];
          this.issuesCount = false;
        }
      },
      filter: {
        handler() {
          if (this.$el.tagName) {
            this.page = 1;
            this.filterLoading = true;

            this.loadIssues(true)
              .then(() => {
                this.filterLoading = false;
              });
          }
        },
        deep: true,
      },
    },
    methods: {
      loadIssues(clearIssues = false) {
        if (!this.showAddIssuesModal) return false;

        return gl.boardService.getBacklog(queryData(this.filter.path, {
          page: this.page,
          per: this.perPage,
        })).then((res) => {
          const data = res.json();

          if (clearIssues) {
            this.issues = [];
          }

          data.issues.forEach((issueObj) => {
            const issue = new ListIssue(issueObj);
            const foundSelectedIssue = ModalStore.findSelectedIssue(issue);
            issue.selected = !!foundSelectedIssue;

            this.issues.push(issue);
          });

          this.loadingNewPage = false;

          if (!this.issuesCount) {
            this.issuesCount = data.size;
          }
        });
      },
    },
    computed: {
      showList() {
        if (this.activeTab === 'selected') {
          return this.selectedIssues.length > 0;
        }

        return this.issuesCount > 0;
      },
      showEmptyState() {
        if (!this.loading && this.issuesCount === 0) {
          return true;
        }

        return this.activeTab === 'selected' && this.selectedIssues.length === 0;
      },
    },
    created() {
      this.page = 1;
    },
    components: {
      'modal-header': gl.issueBoards.ModalHeader,
      'modal-list': gl.issueBoards.ModalList,
      'modal-footer': gl.issueBoards.ModalFooter,
      'empty-state': gl.issueBoards.ModalEmptyState,
    },
    template: `
      <div
        class="add-issues-modal"
        v-if="showAddIssuesModal">
        <div class="add-issues-container">
          <modal-header
            :project-id="projectId"
            :milestone-path="milestonePath"
            :label-path="labelPath">
          </modal-header>
          <modal-list
            :image="blankStateImage"
            :issue-link-base="issueLinkBase"
            :root-path="rootPath"
            v-if="!loading && showList && !filterLoading"></modal-list>
          <empty-state
            v-if="showEmptyState"
            :image="blankStateImage"
            :new-issue-path="newIssuePath"></empty-state>
          <section
            class="add-issues-list text-center"
            v-if="loading || filterLoading">
            <div class="add-issues-list-loading">
              <i class="fa fa-spinner fa-spin"></i>
            </div>
          </section>
          <modal-footer></modal-footer>
        </div>
      </div>
    `,
  });
})();
