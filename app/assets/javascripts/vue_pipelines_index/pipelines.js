/* global Vue, gl, Flash */
/* eslint-disable no-param-reassign, no-new */
import '~/flash';
import CommitPipelinesStoreWithTimeAgo from '../commit/pipelines/pipelines_store';
import PipelinesService from './services/pipelines_service';

window.Vue = require('vue');
require('../vue_shared/components/table_pagination');
require('../vue_shared/components/pipelines_table');

((gl) => {
  gl.VuePipelines = Vue.extend({

    props: {
      endpoint: {
        type: String,
        required: true,
      },

      store: {
        type: Object,
        required: true,
      },
    },

    components: {
      'gl-pagination': gl.VueGlPagination,
      'pipelines-table-component': gl.pipelines.PipelinesTableComponent,
    },

    data() {
      return {
        state: this.store.state,
        apiScope: 'all',
        pagenum: 1,
        pageRequest: false,
      };
    },

    created() {
      this.service = new PipelinesService(this.endpoint);

      this.fetchPipelines();
    },

    beforeUpdate() {
      if (this.state.pipelines.length && this.$children) {
        CommitPipelinesStoreWithTimeAgo.startTimeAgoLoops.call(this, Vue);
      }
    },

    methods: {
      /**
       * Will change the page number and update the URL.
       *
       * @param  {Number} pageNumber desired page to go to.
       */
      change(pageNumber) {
        const param = gl.utils.setParamInURL('page', pageNumber);

        gl.utils.visitUrl(param);
        return param;
      },

      fetchPipelines() {
        const pageNumber = gl.utils.getParameterByName('page') || this.pagenum;
        const scope = gl.utils.getParameterByName('scope') || this.apiScope;

        this.pageRequest = true;
        return this.service.getPipelines(scope, pageNumber)
          .then(resp => ({
            headers: resp.headers,
            body: resp.json(),
          }))
          .then((response) => {
            this.store.storeCount(response.body.count);
            this.store.storePipelines(response.body.pipelines);
            this.store.storePagination(response.headers);
          })
          .then(() => {
            this.pageRequest = false;
          })
          .catch(() => {
            this.pageRequest = false;
            new Flash('An error occurred while fetching the pipelines, please reload the page again.');
          });
      },
    },
    template: `
      <div>
        <div class="pipelines realtime-loading" v-if="pageRequest">
          <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
        </div>

        <div class="blank-state blank-state-no-icon"
          v-if="!pageRequest && state.pipelines.length === 0">
          <h2 class="blank-state-title js-blank-state-title">
            No pipelines to show
          </h2>
        </div>

        <div class="table-holder" v-if="!pageRequest && state.pipelines.length">
          <pipelines-table-component :pipelines="state.pipelines"/>
        </div>

        <gl-pagination
          v-if="!pageRequest && state.pipelines.length && state.pageInfo.total > state.pageInfo.perPage"
          :pagenum="pagenum"
          :change="change"
          :count="state.count.all"
          :pageInfo="state.pageInfo"
        >
        </gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
