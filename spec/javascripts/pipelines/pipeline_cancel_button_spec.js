import Vue from 'vue';
import cancelButtonComp from '~/pipelines/components/pipelines_cancel_button';

describe('Pipelines Cancel Button', () => {
  let component;
  let spy;
  let CancelButton;

  beforeEach(() => {
    CancelButton = Vue.extend(cancelButtonComp);

    spyOn(window, 'confirm').and.returnValue(true);
    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

    component = new CancelButton({
      propsData: {
        cancel_path: '/',
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

  it('should hide loading if request fails', () => {
    spy = jasmine.createSpy('spy').and.returnValue(Promise.reject());

    component = new CancelButton({
      propsData: {
        cancel_path: '/',
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    component.$el.click();
    expect(component.$el.querySelector('.fa-spinner')).toBe(null);
  });
});
