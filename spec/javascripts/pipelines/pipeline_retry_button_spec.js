import Vue from 'vue';
import retryButtonComp from '~/pipelines/components/pipelines_retry_button';

describe('Pipelines Actions dropdown', () => {
  let component;
  let spy;

  beforeEach(() => {
    const RetryButton = Vue.extend(retryButtonComp);

    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

    component = new RetryButton({
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
    expect(component.$el.getAttribute('title')).toEqual('Retry Pipeline');
  });

  it('should call the service when is clicked', () => {
    component.$el.click();
    expect(spy).toHaveBeenCalled();
  });
});
