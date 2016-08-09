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
