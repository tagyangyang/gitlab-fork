/* eslint-disable no-param-reassign */
/* global Vue */

require('./pipelines_table_row');
/**
 * Pipelines Table Component.
 *
 * Given an array of objects, renders a table.
 */

(() => {
  window.gl = window.gl || {};
  gl.pipelines = gl.pipelines || {};

  gl.pipelines.PipelinesTableComponent = Vue.component('pipelines-table-component', {

    props: {
      pipelines: {
        type: Array,
        required: true,
        default: () => ([]),
      },

      service: {
        type: Object,
        required: true,
      },
    },

    components: {
      'pipelines-table-row-component': gl.pipelines.PipelinesTableRowComponent,
    },

    template: `
      <table class="table ci-table">
        <thead>
          <tr>
            <th class="js-pipeline-status pipeline-status">Status</th>
            <th class="js-pipeline-info pipeline-info">Pipeline</th>
            <th class="js-pipeline-commit pipeline-commit">Commit</th>
            <th class="js-pipeline-stages pipeline-stages">Stages</th>
            <th class="js-pipeline-date pipeline-date"></th>
            <th class="js-pipeline-actions pipeline-actions"></th>
          </tr>
        </thead>
        <tbody>
          <template v-for="model in pipelines"
            v-bind:model="model">
            <tr is="pipelines-table-row-component"
              :pipeline="model"
              :service="service"></tr>
          </template>
        </tbody>
      </table>
    `,
  });
})();
