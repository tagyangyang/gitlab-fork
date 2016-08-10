const mrWidgetOpened = {
  mixins: [devMixin],
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest"></ci-status>
              <div class="mr-widget-body">
                <template v-if="mergeRequest.userCanMerge">
                  <merge-status :merge-request="mergeRequest" :ci="ci"></merge-status>
                </template>
                <template v-else>
                  <h4>Ready to be merged automatically</h4>
                  <p>Ask someone with write access to this repository to merge this request.</p>
                </template>
              </div>
            </div>`,
};
