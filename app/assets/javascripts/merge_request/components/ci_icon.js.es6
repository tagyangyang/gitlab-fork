const ciIconComponent = {
  props: ['type'],
  computed: {
    partialName() {
      return `ci-icon-${gl.text.dasherize(this.type)}`;
    },
  },
  template: `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" xmlns:xlink="http://www.w3.org/1999/xlink">
              <defs>
                <circle id="a" cx="7" cy="7" r="7"></circle>
                <mask id="b" width="14" height="14" x="0" y="0" fill="white">
                  <use xlink:href="#a"></use>
                </mask>
              </defs>
              <g fill="none" fill-rule="evenodd">
              <partial :name="partialName">
              </g>
            </svg>`
};
