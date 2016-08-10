const mrWidgetOpened = {
  mixins: [devMixin],
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest"></ci-status>
              <div class="mr-widget-body">
                <merge-status :merge-request="mergeRequest" :ci="ci"></merge-status>
              </div>
            </div>`,
};
