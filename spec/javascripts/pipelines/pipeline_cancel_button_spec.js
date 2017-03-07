import Vue from 'vue';
import cancelButtonComp from '~/pipelines/components/pipelines_cancel_button';

describe('Pipelines Actions dropdown', () => {
  let component;
  let spy;

  beforeEach(() => {
    const CancelButton = Vue.extend(cancelButtonComp);

    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

    component = new CancelButton({
      propsData: {
        retry_path: '/',
        service: {
          postAction: spy,
        },
      },
    }).$mount();
  });

  it('should render a button', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
    expect(component.$el.getAttribute('title')).toEqual('Cancel');
  });

  it('should call the service when is clicked', () => {
    component.$el.click();
    expect(spy).toHaveBeenCalled();
  });
});
