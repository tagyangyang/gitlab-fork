import Vue from 'vue';
import wipComponent from '~/vue_merge_request_widget/components/states/mr_widget_wip';
import eventHub from '~/vue_merge_request_widget/event_hub';

const createComponent = () => {
  const Component = Vue.extend(wipComponent);
  const mr = {
    title: 'The best MR ever',
    canUpdateMergeRequest: true,
  };
  const service = {
    removeWIP() {},
  };
  return new Component({
    el: document.createElement('div'),
    propsData: { mr, service },
  });
};

describe('MRWidgetWIP', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = wipComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();

      expect(service.type instanceof Object).toBeTruthy();
      expect(service.required).toBeTruthy();
    });
  });

  describe('methods', () => {
    const mrObj = {
      is_new_mr_data: true,
    };

    describe('removeWIP', () => {
      it('should make a request to service and handle response', (done) => {
        const vm = createComponent();

        spyOn(window, 'Flash').and.returnValue(true);
        spyOn(eventHub, '$emit');
        spyOn(vm.service, 'removeWIP').and.returnValue(new Promise((resolve) => {
          resolve({
            json() {
              return mrObj;
            },
          });
        }));

        vm.removeWIP();
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('UpdateWidgetData', mrObj);
          expect(window.Flash).toHaveBeenCalledWith('The merge request can now be merged.', 'notice');
          done();
        }, 333);
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent();
      el = vm.$el;
    });

    it('should have correct elements', () => {
      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.innerText).toContain('This merge request is currently Work In Progress and therefore unable to merge');
      expect(el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(el.querySelector('button').innerText).toEqual('Merge');
      expect(el.querySelector('.js-remove-wip').innerText).toContain('Resolve WIP status');
    });

    it('should not show removeWIP button is user cannot update MR', (done) => {
      vm.mr.canUpdateMergeRequest = false;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-remove-wip')).toEqual(null);
        done();
      });
    });
  });
});
