
const eventsObject = {};

_.extend(eventsObject, Backbone.Events);

const PREFIXES = ['moz', 'ms', 'webkit'];

const findPrefix = () => {
  if (typeof document.hidden !== 'undefined') { // Opera 12.10 and Firefox 18 and later support
    return {
      prop: 'hidden',
      eventName: 'visibilitychange',
    };
  }

  for (let i = 0; i < PREFIXES.length; i += 1) {
    const prefix = PREFIXES[i];
    if (typeof document[`${prefix} Hidden`] !== 'undefined') {
      return {
        prop: `${prefix} Hidden`,
        eventName: `${prefix} visibilitychange`,
      };
    }
  }
};

const prefix = findPrefix();
const prop = prefix && prefix.prop;
const eventName = prefix && prefix.eventName;

const handleVisibilityChange = () => {
  eventsObject.trigger('change');
};

export const isHidden = () => {
  if (!prop) return undefined;
  return document[prop];
};

if (eventName) {
  document.addEventListener(eventName, handleVisibilityChange, false);
}

export const events = eventsObject;
