import Vue from 'vue';
import headerComponent from '~/vue_merge_request_widget/components/mr_widget_header';

const createComponent = (mr) => {
  const Component = Vue.extend(headerComponent);
  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetHeader', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = headerComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('computed', () => {
    let vm;
    beforeEach(() => {
      vm = createComponent({
        divergedCommitsCount: 12,
        sourceBranch: 'mr-widget-refactor',
        targetBranch: 'master',
      });
    });

    it('shouldShowCommitsBehindText', () => {
      expect(vm.shouldShowCommitsBehindText).toBeTruthy();

      vm.mr.divergedCommitsCount = 0;
      expect(vm.shouldShowCommitsBehindText).toBeFalsy();
    });

    it('commitsText', () => {
      expect(vm.commitsText).toEqual('commits');

      vm.mr.divergedCommitsCount = 1;
      expect(vm.commitsText).toEqual('commit');
    });
  });

  describe('template', () => {
    let vm;
    let el;
    const mr = {
      divergedCommitsCount: 12,
      sourceBranch: 'mr-widget-refactor',
      targetBranch: 'master',
      isOpen: true,
      emailPatchesPath: '/mr/email-patches',
      plainDiffPath: '/mr/plainDiffPath',
    };

    beforeEach(() => {
      vm = createComponent(mr);
      el = vm.$el;
    });

    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-source-target')).toBeTruthy();
      expect(el.querySelectorAll('.label-branch')[0].textContent).toContain(mr.sourceBranch);
      expect(el.querySelectorAll('.label-branch')[1].textContent).toContain(mr.targetBranch);
      expect(el.querySelector('.diverged-commits-count').textContent).toContain('12 commits behind');

      expect(el.textContent).toContain('Check out branch');
      expect(el.querySelectorAll('.dropdown li a')[0].getAttribute('href')).toEqual(mr.emailPatchesPath);
      expect(el.querySelectorAll('.dropdown li a')[1].getAttribute('href')).toEqual(mr.plainDiffPath);
    });

    it('should not have right action links if the MR state is not open', (done) => {
      vm.mr.isOpen = false;
      Vue.nextTick(() => {
        expect(el.textContent).not.toContain('Check out branch');
        expect(el.querySelectorAll('.dropdown li a').length).toEqual(0);
        done();
      });
    });

    it('should not render diverged commits count if the MR has no diverged commits', (done) => {
      vm.mr.divergedCommitsCount = null;
      Vue.nextTick(() => {
        expect(el.textContent).not.toContain('commits behind');
        expect(el.querySelectorAll('.diverged-commits-count').length).toEqual(0);
        done();
      });
    });
  });
});
