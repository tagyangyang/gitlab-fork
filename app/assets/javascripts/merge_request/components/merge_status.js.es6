const mergeStatusComponent = {
  props: ['ci', 'mergeRequest'],
  components: {
    unchecked: mergeStatusUnchecked,
    can_be_merged: mergeStatusCanBeMerged,
    cannot_be_merged: mergeStatusCannotBeMerged,
  },
  template: `<component :is="mergeRequest.mergeStatus" :ci="ci" :merge-request="mergeRequest"></component>`,
};
