/* global Flash */
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetWIP',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  methods: {
    removeWIP() {
      // TODO: Error handling
      this.service.removeWIP()
        .then(res => res.json())
        .then((res) => {
          eventHub.$emit('UpdateWidgetData', res);
          new Flash('The merge request can now be merged.', 'notice'); // eslint-disable-line
          $('.merge-request .detail-page-description .title').text(this.mr.title);
        });
    },
  },
  template: `
    <div class="mr-widget-body">
      <button type="button" class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">This merge request is currently Work In Progress and therefore unable to merge</span>
      <template v-if="mr.removeWIPPath">
        <i class="fa fa-question-circle has-tooltip" title="When this merge request is ready, remove the WIP: prefix from the title to allow it to be merged."></i>
        <button
          @click="removeWIP"
          type="button"
          class="btn btn-default btn-xs js-remove-wip">Resolve WIP status</button>
      </template>
    </div>
  `,
};
