const mrWidgetOpened = {
  mixins: [devMixin],
  props: ['ci', 'mergeRequest', 'project'],
  computed: {
    status() {
      let status;

      if (this.project.isArchived) {
        status = 'archived';
      } else if (this.mergeRequest.branchMissing) {
        status = 'branch_missing'
      }else if (this.mergeRequest.userNotAllowed) {
        status = 'not_allowed';
      } else {
        status = this.mergeRequest.mergeStatus;
      }

      return status;
    },
    showCiStatus() {
      let show = true;

      if (this.project.isArchived) {
        show = false;
      }

      return show;
    }
  },
  template: `<div class="mr-state-widget">
              <ci-status v-if="showCiStatus" :ci="ci" :merge-request="mergeRequest"></ci-status>
              <div class="mr-widget-body">
                <merge-status :merge-request="mergeRequest" :ci="ci" :status="status"></merge-status>
              </div>
            </div>`,
};
