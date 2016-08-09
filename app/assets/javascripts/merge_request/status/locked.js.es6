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
};
