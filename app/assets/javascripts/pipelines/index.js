import Vue from 'vue';
import Pipelines from './pipelines';
import '../vue_shared/vue_resource_interceptor';

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
