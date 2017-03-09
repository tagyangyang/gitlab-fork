import Vue from 'vue';
import retryButtonComp from '~/pipelines/components/pipelines_retry_button';

describe('Pipelines Retry Button', () => {
  let component;
  let spy;
  let RetryButton;

  beforeEach(() => {
    RetryButton = Vue.extend(retryButtonComp);

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

  it('should hide loading if request fails', () => {
    spy = jasmine.createSpy('spy').and.returnValue(Promise.reject());

    component = new RetryButton({
      propsData: {
        retry_path: '/',
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    component.$el.click();
    expect(component.$el.querySelector('.fa-spinner')).toBe(null);
  });
});
