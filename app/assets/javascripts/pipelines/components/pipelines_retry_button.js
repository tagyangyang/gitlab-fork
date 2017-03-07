/* eslint-disable no-new */
/* global Flash */
import '~/flash';

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
    download(name) {
      return `Download ${name} artifacts`;
    },

    onClickRetry() {
      this.isLoading = true;

      this.service.postAction(this.retry_path)
      .then(() => {
        this.isLoading = false;
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
      class="btn btn-default btn-retry has-tooltip"
      title="Retry Pipeline"
      aria-label="Retry Pipeline">
      <i class="fa fa-repeat" aria-hidden="true"></i>
    </button>
  `,
};
