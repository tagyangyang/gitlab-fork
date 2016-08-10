// Service
const mrService = {
  acceptMergeRequest(params) {

    const successCallback = () => {
      mrStore.updateState({
        mergeRequest: {
          status: 'merged',
          branchRemoved: params.removeBranch
        }
      });
    };

    setTimeout(() => {
      successCallback();
    }, 1000);
  },

  getState(state) {
    const successCallback = (response) => {
      mrStore.updateState({
        mergeRequest: {
          status: response.data.status
        }
      });
    };

    const errorCallback = (response) => {
      console.log(response);
    };

    Vue.http
      .get(`http://glapi.dev/merge_request_status/${state}`, { state })
      .then(successCallback, errorCallback);
  },

  getMergeStatus() {
    const successCallback = () => {
      mrStore.updateMergeStatus('cannot_be_merged');
    };
    setTimeout(successCallback, 4000);
  },

  getCiStatus() {
    setTimeout(() => {
      mrStore.updateCiStatus('running');
    }, 5000);
  },

  // only for testing purposes
  setCiStatus(ciStatus) {
    setTimeout(() => {
      console.log('xx');
      mrStore.updateCiStatus(ciStatus);
    }, 6000);

  }
};
