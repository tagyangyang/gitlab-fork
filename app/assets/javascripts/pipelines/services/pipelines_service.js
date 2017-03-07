/* eslint-disable class-methods-use-this */
import Vue from 'vue';

export default class PipelinesService {
  /**
   * FIXME: The url provided to request the pipelines in the new merge request
   * page already has `.json`.
   * This should be fixed when the endpoint is improved.
   *
   * @param  {String} root
   */
  constructor(root) {
    let endpoint;

    if (root.indexOf('.json') === -1) {
      endpoint = `${root}.json`;
    } else {
      endpoint = root;
    }
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
