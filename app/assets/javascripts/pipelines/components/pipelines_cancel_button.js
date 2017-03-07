/* eslint-disable no-new */
/* global Flash */
import '~/flash';

export default {
  props: {
    cancel_path: {
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
    onClickCancel() {
      this.isLoading = true;

      this.service.postAction(this.cancel_path)
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
      @click="onClickCancel"
      class="btn btn-remove has-tooltip"
      title="Cancel"
      aria-label="Cancel">
      <i class="fa fa-remove" aria-hidden="true"></i>
    </button>
  `,
};
