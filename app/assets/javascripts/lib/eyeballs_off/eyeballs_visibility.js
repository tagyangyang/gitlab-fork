import { events, isHidden } from './utils/page_visibility';
import { addEventListener } from './utils/passive_event_listener';

export default (callback) => {
  // TODO: consider removing these now that we're using
  // pageVisibility
  addEventListener(window, 'pageshow', () => {
    callback(true);
  });
  addEventListener(window, 'pagehide', () => {
    callback(false);
  });

  events.on('change', () => {
    if (isHidden()) {
      callback(false);
    } else {
      callback(true);
    }
  });
};
