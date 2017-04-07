import Vue from 'vue';
import mrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import { stateToComponentMap } from '~/vue_merge_request_widget/stores/state_maps';
import eventHub from '~/vue_merge_request_widget/event_hub';
import mockData from './mock_data';

const createComponent = () => {
  delete mrWidgetOptions.el; // Prevent component mounting
  gl.mrWidgetData = mockData;
  const Component = Vue.extend(mrWidgetOptions);
  return new Component();
};

const returnPromise = data => new Promise((resolve) => {
  resolve({
    json() {
      return data;
    },
    body: data,
  });
});

describe('mrWidgetOptions', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  describe('data', () => {
    it('should instantiate Store and Service', () => {
      expect(vm.mr).toBeDefined();
      expect(vm.service).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('componentName', () => {
      it('should return merged component', () => {
        expect(vm.componentName).toEqual(stateToComponentMap.merged);
      });

      it('should return conflicts component', () => {
        vm.mr.state = 'conflicts';
        expect(vm.componentName).toEqual(stateToComponentMap.conflicts);
      });
    });

    describe('shouldRenderMergeHelp', () => {
      it('should return false for the initial merged state', () => {
        expect(vm.shouldRenderMergeHelp).toBeFalsy();
      });

      it('should return true for a state which requires help widget', () => {
        vm.mr.state = 'conflicts';
        expect(vm.shouldRenderMergeHelp).toBeTruthy();
      });
    });

    describe('shouldRenderPipelines', () => {
      it('should return true for the initial data', () => {
        expect(vm.shouldRenderPipelines).toBeTruthy();
      });

      it('should return true when pipeline is empty but MR.hasCI is set to true', () => {
        vm.mr.pipeline = {};
        expect(vm.shouldRenderPipelines).toBeTruthy();
      });

      it('should return true when pipeline available', () => {
        vm.mr.hasCI = false;
        expect(vm.shouldRenderPipelines).toBeTruthy();
      });

      it('should return false when there is no pipeline', () => {
        vm.mr.pipeline = {};
        vm.mr.hasCI = false;
        expect(vm.shouldRenderPipelines).toBeFalsy();
      });
    });

    describe('shouldRenderRelatedLinks', () => {
      it('should return false for the initial data', () => {
        expect(vm.shouldRenderRelatedLinks).toBeFalsy();
      });

      it('should return true if there is relatedLinks in MR', () => {
        vm.mr.relatedLinks = {};
        expect(vm.shouldRenderRelatedLinks).toBeTruthy();
      });
    });

    describe('shouldRenderDeployments', () => {
      it('should return false for the initial data', () => {
        expect(vm.shouldRenderDeployments).toBeFalsy();
      });

      it('should return true if there is deployments', () => {
        vm.mr.deployments.push({}, {});
        expect(vm.shouldRenderDeployments).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('checkStatus', () => {
      it('should tell service to check status', (done) => {
        spyOn(vm.service, 'checkStatus').and.returnValue(returnPromise(mockData));
        spyOn(vm.mr, 'setData');
        let isCbExecuted = false;
        const cb = () => {
          isCbExecuted = true;
        };

        vm.checkStatus(cb);

        setTimeout(() => {
          expect(vm.service.checkStatus).toHaveBeenCalled();
          expect(vm.mr.setData).toHaveBeenCalled();
          expect(isCbExecuted).toBeTruthy();
          done();
        }, 333);
      });
    });

    describe('initCIPolling', () => {
      it('should call SmartInterval', () => {
        spyOn(gl, 'SmartInterval');
        vm.initCIPolling();

        expect(vm.ciStatusInterval).toBeDefined();
        expect(gl.SmartInterval).toHaveBeenCalled();
      });
    });

    describe('initDeploymentsPolling', () => {
      it('should call SmartInterval', () => {
        spyOn(gl, 'SmartInterval');
        vm.initDeploymentsPolling();

        expect(vm.deploymentsInterval).toBeDefined();
        expect(gl.SmartInterval).toHaveBeenCalled();
      });
    });

    describe('fetchCIStatus', () => {
      it('should set favicon and fetch status', (done) => {
        spyOn(gl.utils, 'setCiStatusFavicon');
        spyOn(vm.service, 'fetchCIStatus').and.returnValue(returnPromise(mockData));
        spyOn(vm.mr, 'updatePipelineData');

        vm.fetchCIStatus();

        setTimeout(() => {
          expect(gl.utils.setCiStatusFavicon).toHaveBeenCalledWith(vm.mr.pipelineStatusPath);
          expect(vm.service.fetchCIStatus).toHaveBeenCalled();
          expect(vm.mr.updatePipelineData).toHaveBeenCalledWith(mockData);
          done();
        }, 333);
      });
    });

    describe('fetchDeployments', () => {
      it('should fetch deployments', (done) => {
        spyOn(vm.service, 'fetchDeployments').and.returnValue(returnPromise([{ deployment: 1 }]));

        vm.fetchDeployments();

        setTimeout(() => {
          expect(vm.service.fetchDeployments).toHaveBeenCalled();
          expect(vm.mr.deployments.length).toEqual(1);
          expect(vm.mr.deployments[0].deployment).toEqual(1);
          done();
        }, 333);
      });
    });

    describe('fetchActionsContent', () => {
      it('should fetch content of Cherry Pick and Revert modals', (done) => {
        spyOn(vm.service, 'fetchMergeActionsContent').and.returnValue(returnPromise('hello world'));

        vm.fetchActionsContent();

        setTimeout(() => {
          expect(vm.service.fetchMergeActionsContent).toHaveBeenCalled();
          expect(document.body.textContent).toContain('hello world');
          done();
        }, 333);
      });
    });

    describe('bindEventHubListeners', () => {
      it('should bind eventHub listeners', () => {
        spyOn(vm, 'checkStatus').and.returnValue(() => {});
        spyOn(vm.service, 'checkStatus').and.returnValue(returnPromise(mockData));
        spyOn(vm, 'fetchActionsContent');
        spyOn(vm.mr, 'setData');
        spyOn(eventHub, '$on');

        vm.bindEventHubListeners();

        eventHub.$emit('SetBranchRemoveFlag', ['flag']);
        expect(vm.mr.isRemovingSourceBranch).toEqual('flag');

        eventHub.$emit('FailedToMerge');
        expect(vm.mr.state).toEqual('failedToMerge');

        eventHub.$emit('UpdateWidgetData', mockData);
        expect(vm.mr.setData).toHaveBeenCalledWith(mockData);

        const listenersWithServiceRequest = {
          MRWidgetUpdateRequested: true,
          FetchActionsContent: true,
        };

        const allArgs = eventHub.$on.calls.allArgs();
        allArgs.forEach((params) => {
          const eventName = params[0];
          const callback = params[1];

          if (listenersWithServiceRequest[eventName]) {
            listenersWithServiceRequest[eventName] = callback;
          }
        });

        listenersWithServiceRequest.MRWidgetUpdateRequested();
        expect(vm.checkStatus).toHaveBeenCalled();

        listenersWithServiceRequest.FetchActionsContent();
        expect(vm.fetchActionsContent).toHaveBeenCalled();
      });
    });

    describe('handleMounted', () => {
      it('should call required methods to do the initial kick-off', () => {
        spyOn(vm, 'checkStatus');
        spyOn(vm, 'fetchCIStatus');
        spyOn(vm, 'initDeploymentsPolling');
        spyOn(vm, 'initCIPolling');

        vm.handleMounted();

        expect(vm.checkStatus).toHaveBeenCalled();
        expect(vm.fetchCIStatus).toHaveBeenCalled();
        expect(vm.initDeploymentsPolling).toHaveBeenCalled();
        expect(vm.initCIPolling).toHaveBeenCalled();
      });

      it('should not call CI polling if MR has no CI', () => {
        spyOn(vm, 'checkStatus');
        spyOn(vm, 'fetchCIStatus');
        spyOn(vm, 'initDeploymentsPolling');
        spyOn(vm, 'initCIPolling');

        vm.mr.hasCI = false;
        vm.handleMounted();

        expect(vm.initCIPolling).not.toHaveBeenCalled();
      });
    });
  });

  describe('components', () => {
    it('should register all components', () => {
      const comps = mrWidgetOptions.components;
      expect(comps['mr-widget-header']).toBeDefined();
      expect(comps['mr-widget-merge-help']).toBeDefined();
      expect(comps['mr-widget-pipeline']).toBeDefined();
      expect(comps['mr-widget-deployment']).toBeDefined();
      expect(comps['mr-widget-related-links']).toBeDefined();
      expect(comps['mr-widget-merged']).toBeDefined();
      expect(comps['mr-widget-closed']).toBeDefined();
      expect(comps['mr-widget-locked']).toBeDefined();
      expect(comps['mr-widget-failed-to-merge']).toBeDefined();
      expect(comps['mr-widget-wip']).toBeDefined();
      expect(comps['mr-widget-archived']).toBeDefined();
      expect(comps['mr-widget-conflicts']).toBeDefined();
      expect(comps['mr-widget-nothing-to-merge']).toBeDefined();
      expect(comps['mr-widget-not-allowed']).toBeDefined();
      expect(comps['mr-widget-missing-branch']).toBeDefined();
      expect(comps['mr-widget-ready-to-merge']).toBeDefined();
      expect(comps['mr-widget-checking']).toBeDefined();
      expect(comps['mr-widget-unresolved-discussions']).toBeDefined();
      expect(comps['mr-widget-pipeline-blocked']).toBeDefined();
      expect(comps['mr-widget-pipeline-failed']).toBeDefined();
      expect(comps['mr-widget-merge-when-pipeline-succeeds']).toBeDefined();
    });
  });
});
