const ciStatusComponent = {
  props: ['ci', 'mergeRequest'],
  computed: {
    cssClasses() {
      let cssClasses = ['ci_widget'];
      cssClasses.push(`ci-${this.ci.status}`);
      return cssClasses;
    },
    ciLabel() {
      let label = this.ci.status;

      if (this.ci.status === 'success') {
        label = 'passed';
      } else if (this.ci.status === 'success_with_warnings') {
        label = 'passed with warnings';
      }

      return label;
    }
  },
  template: `<div v-bind:class="cssClasses">
              <ci-icon :type="ci.status"></ci-icon>
                CI build {{ciLabel}} for
              <a class="monospace" href="{{mergeRequest.commitUrl}}">{{mergeRequest.hash}}</a>.
              <a href="{{ci.detailsUrl}}">View Details</a>
            </div>`,
};
