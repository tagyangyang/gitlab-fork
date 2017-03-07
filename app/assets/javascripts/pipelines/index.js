/* eslint-disable no-param-reassign */
/* global Vue, VueResource, gl */

import Pipelines from './pipelines';

window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../vue_shared/vue_resource_interceptor');

$(() => new Vue({
  el: document.querySelector('.vue-pipelines-index'),

  data() {
    const project = document.querySelector('.pipelines');

    return {
      endpoint: project.dataset.url,
    };
  },
  components: {
    'vue-pipelines': Pipelines,
  },
  template: `
    <vue-pipelines :endpoint="endpoint"/>
  `,
}));
