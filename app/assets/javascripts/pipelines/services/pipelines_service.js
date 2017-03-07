/* eslint-disable class-methods-use-this */
import Vue from 'vue';

export default class PipelinesService {
  constructor(endpoint) {
    this.pipelines = Vue.resource(endpoint);
  }

  getPipelines() {
    return this.pipelines.get();
  }

  /**
   * Post request for all pipelines actions.
   * Endpoint content type needs to be:
   * `Content-Type:application/x-www-form-urlencoded`
   *
   * @param  {String} endpoint
   * @return {Promise}
   */
  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }
}
