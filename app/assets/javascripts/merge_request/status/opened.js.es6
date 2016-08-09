const mrWidgetOpened = {
  mixins: [devMixin],
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
