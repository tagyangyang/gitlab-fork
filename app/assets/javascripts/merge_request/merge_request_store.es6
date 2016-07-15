// mrStore
const mrStore = $.extend(true, {}, {
  state: {},
  updateState(state) {
    mrStore.state.mergeRequest = Object.assign({}, mrStore.state.mergeRequest, state.mergeRequest);
    mrStore.state.widget = Object.assign({}, mrStore.state.widget, state.widget);
  },
  updateMergeStatus(mergeStatus) {
    this.state.mergeRequest.mergeStatus = mergeStatus;
  },
  updateCiStatus(ciStatus) {
    this.state.ci.status = ciStatus;
  }
}, mergeRequestInitialState);
