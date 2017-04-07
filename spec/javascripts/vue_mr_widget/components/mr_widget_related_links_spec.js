import Vue from 'vue';
import relatedLinksComponent from '~/vue_merge_request_widget/components/mr_widget_related_links';

const createComponent = (data) => {
  const Component = Vue.extend(relatedLinksComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: data,
  });
};

describe('MRWidgetRelatedLinks', () => {
  describe('props', () => {
    it('should have props', () => {
      const { relatedLinks } = relatedLinksComponent.props;

      expect(relatedLinks).toBeDefined();
      expect(relatedLinks.type instanceof Object).toBeTruthy();
      expect(relatedLinks.required).toBeTruthy();
    });
  });

  describe('methods', () => {
    const data = {
      relatedLinks: {
        closing: '<a href="#">#23</a> and <a>#42</a>',
        mentioned: '<a href="#">#7</a>',
      },
    };
    const vm = createComponent(data);

    describe('hasMultipleIssues', () => {
      it('should return true if the given text has multiple issues', () => {
        expect(vm.hasMultipleIssues(data.relatedLinks.closing)).toBeTruthy();
      });

      it('should return false if the given text has one issue', () => {
        expect(vm.hasMultipleIssues(data.relatedLinks.mentioned)).toBeFalsy();
      });
    });

    describe('issueLabel', () => {
      it('should return true if the given text has multiple issues', () => {
        expect(vm.issueLabel('closing')).toEqual('issues');
      });

      it('should return false if the given text has one issue', () => {
        expect(vm.issueLabel('mentioned')).toEqual('issue');
      });
    });

    describe('verbLabel', () => {
      it('should return true if the given text has multiple issues', () => {
        expect(vm.verbLabel('closing')).toEqual('are');
      });

      it('should return false if the given text has one issue', () => {
        expect(vm.verbLabel('mentioned')).toEqual('is');
      });
    });
  });

  describe('template', () => {
    it('should have only have closing issues text', () => {
      const vm = createComponent({ relatedLinks: { closing: '<a href="#">#23</a> and <a>#42</a>' } });

      expect(vm.$el.innerText).toContain('Closes issues #23 and #42');
      expect(vm.$el.innerText).not.toContain('mentioned');
    });

    it('should have only have mentioned issues text', () => {
      const vm = createComponent({ relatedLinks: { mentioned: '<a href="#">#7</a>' } });

      expect(vm.$el.innerText).toContain('issue #7');
      expect(vm.$el.innerText).toContain('is mentioned but will not be closed.');
      expect(vm.$el.innerText).not.toContain('Closes');
    });

    it('should have closing and mentioned issues at the same time', () => {
      const vm = createComponent({
        relatedLinks: {
          closing: '<a href="#">#7</a>',
          mentioned: '<a href="#">#23</a> and <a>#42</a>',
        },
      });

      expect(vm.$el.innerText).toContain('Closes issue #7.');
      expect(vm.$el.innerText).toContain('issues #23 and #42');
      expect(vm.$el.innerText).toContain('are mentioned but will not be closed.');
    });
  });
});
