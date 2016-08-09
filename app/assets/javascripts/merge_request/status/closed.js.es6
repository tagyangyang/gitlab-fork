const mrWidgetClosed = {
  mixins: [devMixin],
  props: ['ci', 'mergeRequest'],
  template: `<div class="mr-state-widget">
              <ci-status :ci="ci" :merge-request="mergeRequest" ></ci-status>
              <div class="mr-widget-body">
                <h4>
                  Closed by
                  <a class="author_link" href="/u/root"><img width="16" class="avatar avatar-inline s16" alt="" src="http://localhost:3000/uploads/user/avatar/1/avatar.png"><span class="author ">Alfredo Sumaran</span></a>
                  <time title="Jul 27, 2016 3:02pm GMT-0500">14 minutes ago</time>
                </h4>
                <p>
                  The changes were not merged into
                  <span class="label-branch">master</span>.
                </p>
              </div>
            </div>`
};
