const authorLinkComponent = {
  props: ['author'],
  template: `<a class="author_link" href="{{author.profile}}"><img width="16" class="avatar avatar-inline s16" alt="User avatar" v-bind:src="author.avatar"><span class="author">{{author.name}}</span></a>`,
};
