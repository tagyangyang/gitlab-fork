import {
  WidgetHeader,
  WidgetMergeHelp,
  WidgetPipeline,
  WidgetDeployment,
  WidgetRelatedLinks,
  MergedState,
  ClosedState,
  LockedState,
  WipState,
  ArchivedState,
  ConflictsState,
  NothingToMergeState,
  MissingBranchState,
  NotAllowedState,
  ReadyToMergeState,
  UnresolvedDiscussionsState,
  PipelineBlockedState,
  PipelineFailedState,
  FailedToMerge,
  MergeWhenPipelineSucceedsState,
  CheckingState,
  MRWidgetStore,
  MRWidgetService,
  eventHub,
  // stateMaps,
  SquashBeforeMerge,
} from './dependencies';

export default {
  el: '#js-vue-mr-widget',
  name: 'MRWidget',
  data() {
    const store = new MRWidgetStore(gl.mrWidgetData);
    const service = new MRWidgetService(store);
    return {
      mr: store,
      service,
    };
  },
  computed: {
    componentName() {
      const stateToComponentMap = {
        merged: 'mr-widget-merged',
        closed: 'mr-widget-closed',
        locked: 'mr-widget-locked',
        conflicts: 'mr-widget-conflicts',
        missingBranch: 'mr-widget-missing-branch',
        workInProgress: 'mr-widget-wip',
        readyToMerge: 'mr-widget-ready-to-merge',
        nothingToMerge: 'mr-widget-nothing-to-merge',
        notAllowedToMerge: 'mr-widget-not-allowed',
        archived: 'mr-widget-archived',
        checking: 'mr-widget-checking',
        unresolvedDiscussions: 'mr-widget-unresolved-discussions',
        pipelineBlocked: 'mr-widget-pipeline-blocked',
        pipelineFailed: 'mr-widget-pipeline-failed',
        mergeWhenPipelineSucceeds: 'mr-widget-merge-when-pipeline-succeeds',
        failedToMerge: 'mr-widget-failed-to-merge',
      };
      return stateToComponentMap[this.mr.state];
    },
    shouldRenderMergeHelp() {
      return false; // stateMaps.statesToShowHelpWidget.indexOf(this.mr.state) > -1;
    },
    shouldRenderPipelines() {
      return Object.keys(this.mr.pipeline).length || this.mr.hasCI;
    },
    shouldRenderRelatedLinks() {
      return this.mr.relatedLinks;
    },
    shouldRenderDeployments() {
      return this.mr.deployments.length;
    },
  },
  methods: {
    checkStatus(cb) {
      // TODO: Error handling
      this.service.checkStatus()
        .then(res => res.json())
        .then((res) => {
          this.mr.setData(res);
          if (cb) {
            cb.call(null, res);
          }
        });
    },
    initCIPolling() {
      this.ciStatusInterval = new gl.SmartInterval({
        callback: this.fetchCIStatus,
        startingInterval: 10000,
        maxInterval: 30000,
        hiddenInterval: 120000,
        incrementByFactorOf: 5000,
      });
    },
    initDeploymentsPolling() {
      this.deploymentsInterval = new gl.SmartInterval({
        callback: this.fetchDeployments,
        startingInterval: 30000,
        maxInterval: 120000,
        hiddenInterval: 240000,
        incrementByFactorOf: 15000,
        immediateExecution: true,
      });
    },
    fetchCIStatus() {
      // TODO: Error handling
      gl.utils.setCiStatusFavicon(this.mr.pipelineStatusPath);
      this.service.fetchCIStatus()
        .then(res => res.json())
        .then((res) => {
          if (res.has_ci) {
            this.mr.updatePipelineData(res);
          }
        });
    },
    fetchDeployments() {
      // TODO: Error handling
      this.service.fetchDeployments()
        .then(res => res.json())
        .then((res) => {
          if (res.length) {
            this.mr.deployments = res;
          }
        });
    },
    fetchActionsContent() {
      this.service.fetchMergeActionsContent()
        .then((res) => {
          if (res.body) {
            const el = document.createElement('div');
            el.innerHTML = res.body;
            document.body.appendChild(el);
          }
        });
    },
    bindEventHubListeners() {
      eventHub.$on('MRWidgetUpdateRequested', (cb) => {
        this.checkStatus(cb);
      });

      // `params` should be an Array contains a Boolean, like `[true]`
      // Passing parameter as Boolean didn't work.
      eventHub.$on('SetBranchRemoveFlag', (params) => {
        this.mr.isRemovingSourceBranch = params[0];
      });

      eventHub.$on('FailedToMerge', () => {
        this.mr.state = 'failedToMerge';
      });

      eventHub.$on('UpdateWidgetData', (data) => {
        this.mr.setData(data);
      });

      eventHub.$on('FetchActionsContent', () => {
        this.fetchActionsContent();
      });
    },
    handleMounted() {
      this.checkStatus();
      this.fetchCIStatus();
      this.initDeploymentsPolling();

      if (this.mr.hasCI) {
        this.initCIPolling();
      }
    },
  },
  created() {
    this.bindEventHubListeners();
  },
  mounted() {
    this.handleMounted();
  },
  components: {
    'mr-widget-header': WidgetHeader,
    'mr-widget-merge-help': WidgetMergeHelp,
    'mr-widget-pipeline': WidgetPipeline,
    'mr-widget-deployment': WidgetDeployment,
    'mr-widget-related-links': WidgetRelatedLinks,
    'mr-widget-merged': MergedState,
    'mr-widget-closed': ClosedState,
    'mr-widget-locked': LockedState,
    'mr-widget-failed-to-merge': FailedToMerge,
    'mr-widget-wip': WipState,
    'mr-widget-archived': ArchivedState,
    'mr-widget-conflicts': ConflictsState,
    'mr-widget-nothing-to-merge': NothingToMergeState,
    'mr-widget-not-allowed': NotAllowedState,
    'mr-widget-missing-branch': MissingBranchState,
    'mr-widget-ready-to-merge': ReadyToMergeState,
    'mr-widget-squash-before-merge': SquashBeforeMerge,
    'mr-widget-checking': CheckingState,
    'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
    'mr-widget-pipeline-blocked': PipelineBlockedState,
    'mr-widget-pipeline-failed': PipelineFailedState,
    'mr-widget-merge-when-pipeline-succeeds': MergeWhenPipelineSucceedsState,
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline v-if="shouldRenderPipelines" :mr="mr" />
      <mr-widget-deployment v-if="shouldRenderDeployments" :mr="mr" :service="service" />
      <component :is="componentName" :mr="mr" :service="service" />
      <mr-widget-related-links v-if="shouldRenderRelatedLinks" :related-links="mr.relatedLinks" />
      <mr-widget-merge-help v-if="shouldRenderMergeHelp" />
    </div>
  `,
};
