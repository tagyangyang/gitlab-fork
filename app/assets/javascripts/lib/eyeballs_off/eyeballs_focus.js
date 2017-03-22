import { addEventListener } from './utils/passive_event_listener';

export default (callback) => {
  // Add listeners to the base window
  addEventListener(window, 'focus', () => {
    callback(true);
  });

  addEventListener(window, 'blur', () => {
    callback(false);
  });
};
