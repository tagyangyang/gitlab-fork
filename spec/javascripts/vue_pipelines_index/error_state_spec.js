import Vue from 'vue';
import errorStateComp from '~/vue_pipelines_index/components/error_state.vue';

describe('Pipelines Error State', () => {
  let component;
  let ErrorStateComponent;

  beforeEach(() => {
    ErrorStateComponent = Vue.extend(errorStateComp);

    component = new ErrorStateComponent().$mount();
  });

  it('should render error state SVG', () => {
    expect(component.$el.querySelector('.svg-content svg')).toBeDefined();
  });

  it('should render emtpy state information', () => {
    expect(
      component.$el.querySelector('h4').textContent,
    ).toContain('The API failed to fetch the pipelines');
  });
});
