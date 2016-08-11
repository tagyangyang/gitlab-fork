const mergeStatusComponent = {
  props: ['ci', 'mergeRequest', 'status'],
  components: {
    // Merge Request Statuses
    unchecked: mergeStatusUnchecked,
    can_be_merged: mergeStatusCanBeMerged,
    cannot_be_merged: mergeStatusCannotBeMerged,

    // Custom statuses
    not_allowed: userNotAllowed,
    branch_missing: branchMissing,
    archived: projectArchived,
  },
  template: `<component :is="status" :ci="ci" :merge-request="mergeRequest"></component>`,
};
