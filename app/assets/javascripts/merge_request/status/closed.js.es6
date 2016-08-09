const mrWidgetClosed = {
  mixins: [devMixin],
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest" ></ci-status>
              <div class="mr-widget-body">
                <h4>
                  Closed by
                  <author-link :author="mergeRequest.author"></author-link>
                  <time title="Jul 27, 2016 3:02pm GMT-0500">14 minutes ago</time>
                </h4>
                <p>
                  The changes were not merged into
                  <span class="label-branch">master</span>.
                </p>
              </div>
            </div>`
};
