const mrAcceptButtonComponent = {
  props: ['ci', 'mergeRequest'],
  data: () => ({
    working: false
  }),
  computed: {
    buttonClass() {
      if (this.ci.status === 'running') {
        return 'btn-warning';
      }

      if (this.ci.status === 'failed') {
        return 'btn-danger';
      }
    }
  },
  methods: {
    onClick() {
      this.working = true;
      return this.$dispatch('do-accept-merge-request');
    },
  },
  template: ` <template v-if='ci.status==="pending" || ci.status==="running"'>
                <div class="accept-action">
                  <span class="btn-group">
                    <button class="btn btn-create {{buttonClass}}">
                      Merge When Build Succeeds
                    </button>
                    <button class="btn btn-create dropdown-toggle {{buttonClass}}" data-toggle="dropdown">
                      <span class="caret"></span>
                    </button>
                    <ul class="js-merge-dropdown dropdown-menu dropdown-menu-right" role="menu">
                      <li>
                        <a href="#">
                          <i class="fa fa-check fa-fw"></i>
                          Merge When Build Succeeds
                        </a>
                      </li>
                      <li>
                        <a class="accept_merge_request" href="#">
                          <i class="fa fa-warning fa-fw"></i>
                          Merge Immediately
                        </a>
                      </li>
                    </ul>
                  </span>
                </div>
              </template>
              <template v-else>
                <template v-if="working">
                  <button class="btn btn-create {{buttonClass}}" disabled="disabled">
                    <i class='fa fa-spinner fa-spin'></i> Merge in progress
                  </button>
                </template>
                <template v-else>
                  <button class="btn btn-create {{buttonClass}}" @click="onClick">
                    Accept Merge Request
                  </button>
                </template>
              </template>
              `,
};
