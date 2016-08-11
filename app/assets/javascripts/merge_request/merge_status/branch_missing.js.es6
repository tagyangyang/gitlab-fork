const branchMissing = {
  props: ['ci', 'mergeRequest', 'project'],
  template: `<div>
              <template v-if="!this.mergeRequest.sourceBranchExists">
                <h4>
                  <i class="fa fa-exclamation-triangle"></i>
                  Source branch
                  <span class="label-branch"><a href="{{mergeRequest.sourceBranchUrl}}">{{mergeRequest.sourceBranch}}</a></span>
                  does not exist
                </h4>
                <p>
                  Please restore the source branch or close this merge request and open a new merge request with a different source branch.
                </p>
              </template>
              <template v-else>
                <h4>
                  <i class="fa fa-exclamation-triangle"></i>
                  Target branch
                  <span class="label-branch">{{mergeRequest.sourceBranch}}</span>
                  does not exist
                </h4>
                <p>
                  Please restore the target branch or use a different target branch.
                </p>
              </template>
            </div>`
};
