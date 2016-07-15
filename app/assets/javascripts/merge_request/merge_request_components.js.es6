const ciIconComponent = {
  props: ['type'],
  computed: {
    partialName() {
      return `ci-icon-${gl.text.dasherize(this.type)}`;
    },
  },
  template: `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" xmlns:xlink="http://www.w3.org/1999/xlink">
              <defs>
                <circle id="a" cx="7" cy="7" r="7"></circle>
                <mask id="b" width="14" height="14" x="0" y="0" fill="white">
                  <use xlink:href="#a"></use>
                </mask>
              </defs>
              <g fill="none" fill-rule="evenodd">
              <partial :name="partialName">
              </g>
            </svg>`
};

const ciStatusComponent = {
  props: ['ci', 'mergeRequest'],
  computed: {
    cssClasses() {
      let cssClasses = ['ci_widget'];
      cssClasses.push(`ci-${this.ci.status}`);
      return cssClasses;
    },
    ciLabel() {
      let label = this.ci.status;

      if (this.ci.status === 'success') {
        label = 'passed';
      } else if (this.ci.status === 'success_with_warnings') {
        label = 'passed with warnings';
      }

      return label;
    }
  },
  template: `<div v-bind:class="cssClasses">
              <ci-icon :type="ci.status"></ci-icon>
                CI build {{ciLabel}} for
              <a class="monospace" href="{{mergeRequest.commitUrl}}">{{mergeRequest.hash}}</a>.
              <a href="{{ci.detailsUrl}}">View Details</a>
            </div>`,
};

const mrAcceptButtonComponent = {
  props: ['ci', 'mergeRequest'],
  data: () => ({
    working: false
  }),
  computed: {
    buttonClass() {
      if (this.ci.status === 'running') {
        return 'btn-warning';
      }

      if (this.ci.status === 'failed') {
        return 'btn-danger';
      }
    }
  },
  methods: {
    onClick() {
      this.working = true;
      return this.$dispatch('do-accept-merge-request');
    },
  },
  template: ` <template v-if='ci.status==="pending" || ci.status==="running"'>
                <div class="accept-action">
                  <span class="btn-group">
                    <button class="btn btn-create {{buttonClass}}">
                      Merge When Build Succeeds
                    </button>
                    <button class="btn btn-create dropdown-toggle {{buttonClass}}" data-toggle="dropdown">
                      <span class="caret"></span>
                    </button>
                    <ul class="js-merge-dropdown dropdown-menu dropdown-menu-right" role="menu">
                      <li>
                        <a href="#">
                          <i class="fa fa-check fa-fw"></i>
                          Merge When Build Succeeds
                        </a>
                      </li>
                      <li>
                        <a class="accept_merge_request" href="#">
                          <i class="fa fa-warning fa-fw"></i>
                          Merge Immediately
                        </a>
                      </li>
                    </ul>
                  </span>
                </div>
              </template>
              <template v-else>
                <template v-if="working">
                  <button class="btn btn-create {{buttonClass}}" disabled="disabled">
                    <i class='fa fa-spinner fa-spin'></i> Merge in progress
                  </button>
                </template>
                <template v-else>
                  <button class="btn btn-create {{buttonClass}}" @click="onClick">
                    Accept Merge Request
                  </button>
                </template>
              </template>
              `,
};

const mrHeadlineComponent = {
  props: ['headline'],
  template: '<h4>{{ headline }}</h4>',
};

const mrWidgetOpened = {
  props: ['ci', 'mergeRequest'],
  data: () => ({
    removeBranch: false,
    showCommitMessage: false,
  }),
  methods: {
    onAcceptMergeRequest() {
      return mrService.acceptMergeRequest({
        removeBranch: this.removeBranch,
        commitMessage: this.commitMessage,
      });
    },
    toggleCommitMessage() {
      this.showCommitMessage = !this.showCommitMessage;
    },
  },
  ready: () => {
    mrService.getMergeStatus();
    mrService.getCiStatus();
    // only for testing purposes
    mrService.setCiStatus('success');
  },
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest"></ci-status>
              <div class="mr-widget-body">
                <template v-if="mergeRequest.mergeStatus==='unchecked'">
                  <strong>
                    <i class="fa fa-spinner fa-spin"></i>
                    Checking ability to merge automatically&hellip;
                  </strong>
                </template>
                <template v-else>
                  <div class="accept-merge-holder clearfix">
                    <div class="clearfix">
                      <div class="accept-action">
                        <mr-accept-button @do-accept-merge-request="onAcceptMergeRequest" :merge-request="mergeRequest" :ci="ci"></mr-accept-button>
                      </div>
                      <div class="accept-control checkbox">
                        <label for="mr-remove-branch">
                          <input type="checkbox" id="mr-remove-branch" v-model="removeBranch">
                          Remove Source Branch
                        </label>
                      </div>
                      <div class="accept-control right">
                        <a class="modify-merge-commit-link" href="#" @click="toggleCommitMessage">
                          <i class="fa fa-edit" v-if="!showCommitMessage"></i>
                          <i class="fa fa-chevron-up" v-if="showCommitMessage"></i>
                          Modify commit message
                        </a>
                      </div>
                    </div>
                    <div v-if="showCommitMessage">
                      <div class="form-group commit_message-group">
                        <label class="control-label" for="commit_message-825c2b031c44ce57296fa2585b06f63c">
                          Commit message
                        </label>
                        <div class="col-sm-10">
                          <div class="commit-message-container">
                          <div class="max-width-marker"></div>
                          <textarea name="commit_message" id="x" class="form-control js-commit-message" required="required" rows="14"  v-model="mergeRequest.mergeCommitMessage"></textarea>
                        </div>
                        <p class="hint">
                          Try to keep the first line under 52 characters
                          and the others under 72.
                        </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </template>
              </div>
            </div>`,
};

const mrWidgetReopened = {
  template: ` <div class="class="mr-state-widget"">
                Reopened State
              <div>`
};

const mrWidgetMerged = {
  props: ['mergeRequest'],
  template: `<div class="mr-state-widget">
              <div class="mr-widget-body">
                <h4>
                  Merged by
                  <author-link></author-link>
                  <timeago></timeago>
                </h4>
                <p>
                  The changes were merged into
                  <a class="label-branch" href="#">{{mergeRequest.targetBranch}}</a>.
                  <template v-if="mergeRequest.branchRemoved">
                    The source branch has been removed.
                  </template>
                  <template v-else="">
                    You can remove the source branch now.
                  </template>
                </p>
                <div class="clearfix merged-buttons">
                  <template v-if="!mergeRequest.branchRemoved">
                    <a class="btn btn-default btn-sm remove_source_branch" href="#">
                      <i class="fa fa-trash-o"></i>
                      Remove Source Branch
                    </a>
                  </template>
                  <a href="#modal-revert-merge-request" data-toggle="modal" class="btn btn-warning btn-sm remove_source_branch has-tooltip" title="Revert this merge request in a new merge request">
                    Revert
                  </a>
                  <a href="#modal-cherry-pick-merge-request" data-toggle="modal" title="" class="btn btn-default btn-sm">
                    Cherry-pick
                  </a>
                </div>
              </div>
            </div>`,
};

const mrWidgetLocked = {
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest"></ci-status>
              <div class="mr-widget-body">
                <h4>
                  <i class="fa fa-spinner fa-spin"></i>
                  Merge in progress…
                </h4>
                <p>
                  This merge request is in the process of being merged, during which time it is locked and cannot be closed.
                </p>
              </div>
            </div>`
}

const mrMergeStatusCannotBeMerged = {
  template: `<div class="mr-state-widget">
              <div class="mr-widget-body">
                <h4 class="has-conflicts">
                  <i class="fa fa-exclamation-triangle"></i>
                  This merge request contains merge conflicts
                </h4>
                <p>
                Please resolve these conflicts or
                <a class="how_to_merge_link" data-toggle="modal" href="#modal_merge_info">merge this request manually</a>.
                </p>
              </div>
            </div>`
}

const mrWidgetClosed = {
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest" ></ci-status>
              <div class="mr-widget-body">
                <h4>
                  Closed by
                  <a class="author_link  " href="/u/root"><img width="16" class="avatar avatar-inline s16" alt="" src="http://localhost:3000/uploads/user/avatar/1/avatar.png"><span class="author ">Alfredo Sumaran</span></a>
                  <time title="Jul 27, 2016 3:02pm GMT-0500">14 minutes ago</time>
                </h4>
                <p>
                  The changes were not merged into
                  <span class="label-branch">master</span>.
                </p>
              </div>
            </div>`
};

const mrWidgetCanBeMerged = {
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest" ></ci-status>
              <div class="mr-widget-body">
                <button>merge when build succeeds</button>
              </div>
            </div>`
};

const authorLinkComponent = {
  template: `<a class="author_link" href="/u/root">
              <img width="16" class="avatar avatar-inline s16" alt="User avatar" src="http://localhost:3000/uploads/user/avatar/1/avatar.png">
              <span class="author ">Alfredo Sumaran</span>
            </a>`,
};

const timeagoComponent = {
  template: `<time>17 minutes ago</time>`
};
