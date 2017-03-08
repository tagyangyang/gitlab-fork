/* eslint-disable no-new */
/* global Flash */
import '~/flash';
import eventHub from '../event_hub';

export default {
  props: {
    retry_path: {
      type: String,
      required: true,
    },

    service: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      isLoading: false,
    };
  },

  methods: {
    onClickRetry() {
      this.isLoading = true;

      this.service.postAction(this.retry_path)
      .then(() => {
        this.isLoading = false;
        eventHub.$emit('refreshPipelines');
      })
      .catch(() => {
        this.isLoading = false;
        new Flash('An error occured while making the request.', 'alert');
      });
    },
  },

  template: `
    <button
      type="button"
      @click="onClickRetry"
      class="btn btn-default btn-retry has-tooltip"
      title="Retry Pipeline"
      aria-label="Retry Pipeline"
      data-placement="top"
      :disabled="isLoading">
      <i class="fa fa-repeat" aria-hidden="true"></i>
      <i v-if="isLoading" class="fa fa-spinner fa-spin" aria-hidden="true"></i>
    </button>
  `,
};
