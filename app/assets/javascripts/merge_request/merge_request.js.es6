// App
const mergeRequest = {
  el: '#merge-request-app',
  data: mrStore.state,
  components: {
    opened:   mrWidgetOpened,
    reopened: mrWidgetReopened,
    closed:   mrWidgetClosed,
    merged:   mrWidgetMerged,
    locked:   mrWidgetLocked,
  },
};

// Partials
Vue.partial('ci-icon-pending', ciIconPartialPending);
Vue.partial('ci-icon-running', ciIconPartialRunning);
Vue.partial('ci-icon-failed', ciIconPartialFailed);
Vue.partial('ci-icon-canceled', ciIconPartialCanceled);
Vue.partial('ci-icon-skipped', ciIconPartialSkipped);
Vue.partial('ci-icon-success-with-warnings', ciIconPartialSuccessWithWarnings);
Vue.partial('ci-icon-success', ciIconPartialSuccess);

// Register Global Components
Vue.component('mr-accept-button', mrAcceptButtonComponent);
Vue.component('author-link', authorLinkComponent);
Vue.component('timeago', timeagoComponent);
Vue.component('ci-status', ciStatusComponent);
Vue.component('ci-icon', ciIconComponent);

$(() => {
  // Initialize App
  window.vmMergeRequest = new Vue(mergeRequest);
});
