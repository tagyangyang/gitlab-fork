/* global Flash */

import Vue from 'vue';
import Cookies from 'js-cookie';
import LimitWarningComponent from './components/limit_warning_component';

require('./components/stage_code_component');
require('./components/stage_issue_component');
require('./components/stage_plan_component');
require('./components/stage_production_component');
require('./components/stage_review_component');
require('./components/stage_staging_component');
require('./components/stage_test_component');
require('./components/total_time_component');
require('./cycle_analytics_service');
require('./cycle_analytics_store');
require('./default_event_objects');

$(() => {
  const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';
  const cycleAnalyticsEl = document.querySelector('#cycle-analytics');
  const cycleAnalyticsStore = gl.cycleAnalytics.CycleAnalyticsStore;
  const cycleAnalyticsService = new gl.cycleAnalytics.CycleAnalyticsService({
    requestPath: cycleAnalyticsEl.dataset.requestPath,
  });

  gl.cycleAnalyticsApp = new Vue({
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    data: {
      state: cycleAnalyticsStore.state,
      isLoading: false,
      isLoadingStage: false,
      isEmptyStage: false,
      hasError: false,
      startDate: 30,
      isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
    },
    computed: {
      currentStage() {
        return cycleAnalyticsStore.currentActiveStage();
      },
    },
    components: {
      'stage-issue-component': gl.cycleAnalytics.StageIssueComponent,
      'stage-plan-component': gl.cycleAnalytics.StagePlanComponent,
      'stage-code-component': gl.cycleAnalytics.StageCodeComponent,
      'stage-test-component': gl.cycleAnalytics.StageTestComponent,
      'stage-review-component': gl.cycleAnalytics.StageReviewComponent,
      'stage-staging-component': gl.cycleAnalytics.StageStagingComponent,
      'stage-production-component': gl.cycleAnalytics.StageProductionComponent,
    },
    created() {
      this.fetchCycleAnalyticsData();
    },
    methods: {
      handleError() {
        cycleAnalyticsStore.setErrorState(true);
        return new Flash('There was an error while fetching cycle analytics data.');
      },
      initDropdown() {
        const $dropdown = $('.js-ca-dropdown');
        const $label = $dropdown.find('.dropdown-label');

        $dropdown.find('li a').off('click').on('click', (e) => {
          e.preventDefault();
          const $target = $(e.currentTarget);
          this.startDate = $target.data('value');

          $label.text($target.text().trim());
          this.fetchCycleAnalyticsData({ startDate: this.startDate });
        });
      },
      fetchCycleAnalyticsData(options) {
        const fetchOptions = options || { startDate: this.startDate };

        this.isLoading = true;

        cycleAnalyticsService
          .fetchCycleAnalyticsData(fetchOptions)
          .done((response) => {
            cycleAnalyticsStore.setCycleAnalyticsData(response);
            this.selectDefaultStage();
            this.initDropdown();
          })
          .error(() => {
            this.handleError();
          })
          .always(() => {
            this.isLoading = false;
          });
      },
      selectDefaultStage() {
        const stage = this.state.stages.first();
        this.selectStage(stage);
      },
      selectStage(stage) {
        if (this.isLoadingStage) return;
        if (this.currentStage === stage) return;

        if (!stage.isUserAllowed) {
          cycleAnalyticsStore.setActiveStage(stage);
          return;
        }

        this.isLoadingStage = true;
        cycleAnalyticsStore.setStageEvents([], stage);
        cycleAnalyticsStore.setActiveStage(stage);

        cycleAnalyticsService
          .fetchStageData({
            stage,
            startDate: this.startDate,
          })
          .done((response) => {
            this.isEmptyStage = !response.events.length;
            cycleAnalyticsStore.setStageEvents(response.events, stage);
          })
          .error(() => {
            this.isEmptyStage = true;
          })
          .always(() => {
            this.isLoadingStage = false;
          });
      },
      dismissOverviewDialog() {
        this.isOverviewDialogDismissed = true;
        Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
      },
    },
  });

  // Register global components
  Vue.component('limit-warning', LimitWarningComponent);
  Vue.component('total-time', gl.cycleAnalytics.TotalTimeComponent);
});
