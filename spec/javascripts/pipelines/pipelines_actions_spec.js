import Vue from 'vue';
import pipelinesActionsComp from '~/pipelines/components/pipelines_actions';

fdescribe('Pipelines Actions dropdown', () => {
  let component;
  let spy;
  let actions;

  beforeEach(() => {
    const ActionsComponent = Vue.extend(pipelinesActionsComp);

    actions = [
      {
        name: 'stop_review',
        path: '/root/review-app/builds/1893/play',
      },
    ];

    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

    component = new ActionsComponent({
      propsData: {
        actions,
        service: {
          postAction: spy,
        },
      },
    }).$mount();
  });

  it('should render a dropdown with the provided actions', () => {
    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(actions.length);
  });

  it('should call the service when an action is clicked', () => {
    component.$el.querySelector('.dropdown').click();
    component.$el.querySelector('.js-manual-action-link').click();

    expect(spy).toHaveBeenCalledWith(actions[0].path);
  });
});
