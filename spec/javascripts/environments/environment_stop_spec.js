import Vue from 'vue';
import stopComp from '~/environments/components/environment_stop';

describe('Stop Component', () => {
  let StopComponent;
  let component;
  const stopURL = '/stop';

  beforeEach(() => {
    StopComponent = Vue.extend(stopComp);

    component = new StopComponent({
      propsData: {
        stopUrl: stopURL,
      },
    }).$mount();
  });

  it('should render a button to stop the environment', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
    expect(component.$el.getAttribute('title')).toEqual('Stop Environment');
  });

  it('should call the service when an action is clicked', () => {
    const spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());
    spyOn(window, 'confirm').and.returnValue(true);

    component = new StopComponent({
      propsData: {
        stopUrl: stopURL,
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    component.$el.click();

    expect(spy).toHaveBeenCalled();
  });
});
