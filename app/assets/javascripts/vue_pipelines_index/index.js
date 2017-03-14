/* global Vue, VueResource, gl */
import PipelinesStore from './stores/pipelines_store';

window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../vue_shared/vue_resource_interceptor');
require('./pipelines');

$(() => new Vue({
  el: document.querySelector('.vue-pipelines-index'),

  data() {
    const project = document.querySelector('.pipelines');
    const store = new PipelinesStore();

    return {
      store,
      endpoint: project.dataset.url,
    };
  },
  components: {
    'vue-pipelines': gl.VuePipelines,
  },
  template: `
    <vue-pipelines
      :endpoint="endpoint"
      :store="store" />
  `,
}));
