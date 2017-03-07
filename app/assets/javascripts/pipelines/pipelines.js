/* eslint-disable no-new */
/* global Flash */

import PipelinesService from './services/pipelines_service';
import PipelinesStore from './stores/pipelines_store';
import PipelinesTable from '../vue_shared/components/pipelines_table';
import TablePagination from '../vue_shared/components/table_pagination';

export default {

  components: {
    'gl-pagination': TablePagination,
    'pipelines-table-component': PipelinesTable,
  },

  data() {
    const store = new PipelinesStore();

    return {
      store,
      state: store.state,
      apiScope: 'all',
      pagenum: 1,
      pageRequest: false,
    };
  },

  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },

  created() {
    const pageNumber = gl.utils.getParameterByName('page') || this.pagenum;
    const scope = gl.utils.getParameterByName('scope') || this.apiScope;

    const endpoint = `${this.endpoint}?scope=${scope}&page=${pageNumber}`;

    this.service = new PipelinesService(endpoint);

    this.pageRequest = true;
    return this.service.getPipelines(endpoint)
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

  beforeUpdate() {
    if (this.state.pipelines.length && this.$children) {
      this.store.startTimeAgoLoops.call(this, Vue);
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
        <pipelines-table-component
          :pipelines="state.pipelines"
          :service="service"/>
      </div>

      <gl-pagination
        v-if="!pageRequest && state.pipelines.length && state.pageInfo.total > state.pageInfo.perPage"
        :pagenum="pagenum"
        :change="change"
        :count="state.count.all"
        :pageInfo="state.pageInfo"/>
    </div>
  `,
};
