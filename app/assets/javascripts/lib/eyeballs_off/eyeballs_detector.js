
import _ from 'underscore';
// var Backbone = require('backbone');
// var debug = require('debug-proxy')('app:eyeballs:detector');

import EyeballsActivity from './eyeballs_activity';
import eyeballsFocus from './eyeballs_focus';
import EyeballsVisibility from './eyeballs_visibility';

const events = {};
// _.extend(events, Backbone.Events);

export default class EyeballsDetector {
  constructor() {
    this.hasVisibility = true;
    this.hasFocus = true;
    this.hasActivity = true;
    this.eyesOnState = true;

    this.activityMonitor = new EyeballsActivity((signal) => {
      // debug('Activity signal: %s', signal);
      this.hasActivity = signal;
      this.update();
    });

    this.eyeballsVisibility = new EyeballsVisibility((signal) => {
      // debug('Visibility signal: %s', signal);
      this.hasVisibility = signal;
      this.update();
    });

    eyeballsFocus((signal) => {
      // debug('Focus signal: %s', signal);
      this.hasFocus = signal;
      if (signal) {
        // Focus means the user is active...
        this.activityMonitor.setInactive(false);
      } else {
        this.activityMonitor.setInactive(true);
      }
      this.update();
    });
  }

  update() {
    const newValue = this.hasVisibility && this.hasFocus && this.hasActivity;
    if (newValue === this.eyesOnState) return;

    this.eyesOnState = newValue;
    // debug('Eyeballs change: %s', newValue);

    this.events.trigger('change', this.eyesOnState);
  }

  getEyeballs() {
    return this.eyesOnState;
  }

  forceActivity() {
    this.activityMonitor.setInactive(false);
  }
}
