import _ from 'underscore';
import { addEventListener } from './utils/passive_event_listener';

const INACTIVITY = 60 * 1000; /* One minute */
const INACTIVITY_POLL = 10 * 1000; /* 10 seconds */

export default class EyeballsActivity {
  constructor(callback) {
    this.callback = callback;
    this.inactivityTimer = null;
    this.inactive = null;
    this.lastUserInteraction = null;

    const debouncedInteractionTracking = _.debounce(this.registerInteraction.bind(this), 500);

    addEventListener(document, 'keydown', debouncedInteractionTracking);
    addEventListener(document, 'mousemove', debouncedInteractionTracking);
    addEventListener(document, 'touchstart', debouncedInteractionTracking);
    addEventListener(window, 'scroll', debouncedInteractionTracking);

    // Default to there being activity
    this.setInactive(false);
  }

  setInactive(isInactive) {
    if (this.inactive === isInactive) return;

    this.inactive = isInactive;

    if (isInactive) {
      this.stopInactivityPoller();
    } else {
      this.lastUserInteraction = Date.now();
      this.startInactivityPoller();
    }

    this.callback(!isInactive);
  }

  // User did something
  registerInteraction() {
    this.setInactive(false);
  }

  /**
   * This timer occassionally checks whether the user has performed any
   * interactions since the last time it was called.
   * While being careful to deal with the computer sleeping
   */
  startInactivityPoller() {
    if (this.inactivityTimer) return;
    this.inactivityTimer = setInterval(() => {
      // This is a long timeout, so it could possibly be delayed by
      // the user pausing the application. Therefore just wait for one
      // more period for activity to start again...
      setTimeout(() => {
        if (Date.now() - this.lastUserInteraction > (INACTIVITY - INACTIVITY_POLL)) {
          this.setInactive(true);
        }
      }, 5);
    }, INACTIVITY_POLL);
  }

  stopInactivityPoller() {
    if (!this.inactivityTimer) return;
    clearTimeout(this.inactivityTimer);
    this.inactivityTimer = null;
  }
}
