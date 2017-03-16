/******/ (function(modules) { // webpackBootstrap
/******/  // The module cache
/******/  var installedModules = {};
/******/
/******/  // The require function
/******/  function __webpack_require__(moduleId) {
/******/
/******/    // Check if module is in cache
/******/    if(installedModules[moduleId])
/******/      return installedModules[moduleId].exports;
/******/
/******/    // Create a new module (and put it into the cache)
/******/    var module = installedModules[moduleId] = {
/******/      i: moduleId,
/******/      l: false,
/******/      exports: {}
/******/    };
/******/
/******/    // Execute the module function
/******/    modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/    // Flag the module as loaded
/******/    module.l = true;
/******/
/******/    // Return the exports of the module
/******/    return module.exports;
/******/  }
/******/
/******/
/******/  // expose the modules object (__webpack_modules__)
/******/  __webpack_require__.m = modules;
/******/
/******/  // expose the module cache
/******/  __webpack_require__.c = installedModules;
/******/
/******/  // identity function for calling harmony imports with the correct context
/******/  __webpack_require__.i = function(value) { return value; };
/******/
/******/  // define getter function for harmony exports
/******/  __webpack_require__.d = function(exports, name, getter) {
/******/    if(!__webpack_require__.o(exports, name)) {
/******/      Object.defineProperty(exports, name, {
/******/        configurable: false,
/******/        enumerable: true,
/******/        get: getter
/******/      });
/******/    }
/******/  };
/******/
/******/  // getDefaultExport function for compatibility with non-harmony modules
/******/  __webpack_require__.n = function(module) {
/******/    var getter = module && module.__esModule ?
/******/      function getDefault() { return module['default']; } :
/******/      function getModuleExports() { return module; };
/******/    __webpack_require__.d(getter, 'a', getter);
/******/    return getter;
/******/  };
/******/
/******/  // Object.prototype.hasOwnProperty.call
/******/  __webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/  // __webpack_public_path__
/******/  __webpack_require__.p = "";
/******/
/******/  // Load entry module and return exports
/******/  return __webpack_require__(__webpack_require__.s = 9);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var DATA_TRIGGER = 'data-dropdown-trigger';
var DATA_DROPDOWN = 'data-dropdown';
var SELECTED_CLASS = 'droplab-item-selected';
var ACTIVE_CLASS = 'droplab-item-active';

var constants = {
  DATA_TRIGGER: DATA_TRIGGER,
  DATA_DROPDOWN: DATA_DROPDOWN,
  SELECTED_CLASS: SELECTED_CLASS,
  ACTIVE_CLASS: ACTIVE_CLASS
};

exports.default = constants;

/***/ }),
/* 1 */
/***/ (function(module, exports) {

// Polyfill for creating CustomEvents on IE9/10/11

// code pulled from:
// https://github.com/d4tocchini/customevent-polyfill
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent#Polyfill

try {
    var ce = new window.CustomEvent('test');
    ce.preventDefault();
    if (ce.defaultPrevented !== true) {
        // IE has problems with .preventDefault() on custom events
        // http://stackoverflow.com/questions/23349191
        throw new Error('Could not prevent default');
    }
} catch(e) {
  var CustomEvent = function(event, params) {
    var evt, origPrevent;
    params = params || {
      bubbles: false,
      cancelable: false,
      detail: undefined
    };

    evt = document.createEvent("CustomEvent");
    evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
    origPrevent = evt.preventDefault;
    evt.preventDefault = function () {
      origPrevent.call(this);
      try {
        Object.defineProperty(this, 'defaultPrevented', {
          get: function () {
            return true;
          }
        });
      } catch(e) {
        this.defaultPrevented = true;
      }
    };
    return evt;
  };

  CustomEvent.prototype = window.Event.prototype;
  window.CustomEvent = CustomEvent; // expose definition to window
}


/***/ }),
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _dropdown = __webpack_require__(6);

var _dropdown2 = _interopRequireDefault(_dropdown);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Hook = function Hook(trigger, list, plugins, config) {
  this.trigger = trigger;
  this.list = new _dropdown2.default(list);
  this.type = 'Hook';
  this.event = 'click';
  this.plugins = plugins || [];
  this.config = config || {};
  this.id = trigger.id;
};

Object.assign(Hook.prototype, {

  addEvents: function addEvents() {},

  constructor: Hook
});

exports.default = Hook;

/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DATA_TRIGGER = _constants2.default.DATA_TRIGGER,
    DATA_DROPDOWN = _constants2.default.DATA_DROPDOWN;


var utils = {
  toCamelCase: function toCamelCase(attr) {
    return this.camelize(attr.split('-').slice(1).join(' '));
  },
  t: function t(s, d) {
    for (var p in d) {
      if (Object.prototype.hasOwnProperty.call(d, p)) {
        s = s.replace(new RegExp('{{' + p + '}}', 'g'), d[p]);
      }
    }
    return s;
  },
  camelize: function camelize(str) {
    return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function (letter, index) {
      return index === 0 ? letter.toLowerCase() : letter.toUpperCase();
    }).replace(/\s+/g, '');
  },
  closest: function closest(thisTag, stopTag) {
    while (thisTag && thisTag.tagName !== stopTag && thisTag.tagName !== 'HTML') {
      thisTag = thisTag.parentNode;
    }
    return thisTag;
  },
  isDropDownParts: function isDropDownParts(target) {
    if (!target || target.tagName === 'HTML') return false;
    return target.hasAttribute(DATA_TRIGGER) || target.hasAttribute(DATA_DROPDOWN);
  }
};

exports.default = utils;

/***/ }),
/* 4 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function () {
  var DropLab = function DropLab(hook, list) {
    if (!this instanceof DropLab) return new DropLab(hook);

    this.ready = false;
    this.hooks = [];
    this.queuedData = [];
    this.config = {};

    this.eventWrapper = {};

    if (!hook) return this.loadStatic();
    this.addHook(hook, list);
    this.init();
  };

  Object.assign(DropLab.prototype, {
    loadStatic: function loadStatic() {
      var dropdownTriggers = [].slice.apply(document.querySelectorAll('[' + DATA_TRIGGER + ']'));
      this.addHooks(dropdownTriggers).init();
    },

    addData: function addData() {
      var args = [].slice.apply(arguments);
      this.applyArgs(args, '_addData');
    },

    setData: function setData() {
      var args = [].slice.apply(arguments);
      this.applyArgs(args, '_setData');
    },

    destroy: function destroy() {
      this.hooks.forEach(function (hook) {
        return hook.destroy();
      });
      this.hooks = [];
      this.removeEvents();
    },

    applyArgs: function applyArgs(args, methodName) {
      if (this.ready) return this[methodName].apply(this, args);

      this.queuedData = this.queuedData || [];
      this.queuedData.push(args);
    },

    _addData: function _addData(trigger, data) {
      this._processData(trigger, data, 'addData');
    },

    _setData: function _setData(trigger, data) {
      this._processData(trigger, data, 'setData');
    },

    _processData: function _processData(trigger, data, methodName) {
      this.hooks.forEach(function (hook) {
        if (Array.isArray(trigger)) hook.list[methodName](trigger);

        if (hook.trigger.id === trigger) hook.list[methodName](data);
      });
    },

    addEvents: function addEvents() {
      this.eventWrapper.documentClicked = this.documentClicked.bind(this);
      document.addEventListener('click', this.eventWrapper.documentClicked);
    },

    documentClicked: function documentClicked(e) {
      var thisTag = e.target;

      if (thisTag.tagName !== 'UL') thisTag = _utils2.default.closest(thisTag, 'UL');
      if (_utils2.default.isDropDownParts(thisTag, this.hooks) || _utils2.default.isDropDownParts(e.target, this.hooks)) return;

      this.hooks.forEach(function (hook) {
        return hook.list.hide();
      });
    },

    removeEvents: function removeEvents() {
      document.removeEventListener('click', this.eventWrapper.documentClicked);
    },

    changeHookList: function changeHookList(trigger, list, plugins, config) {
      var _this = this;

      var availableTrigger = typeof trigger === 'string' ? document.getElementById(trigger) : trigger;

      this.hooks.forEach(function (hook, i) {
        hook.list.list.dataset.dropdownActive = false;

        if (hook.trigger !== availableTrigger) return;

        hook.destroy();
        _this.hooks.splice(i, 1);
        _this.addHook(availableTrigger, list, plugins, config);
      });
    },

    addHook: function addHook(hook, list, plugins, config) {
      var availableHook = typeof hook === 'string' ? document.querySelector(hook) : hook;
      var availableList = void 0;

      if (typeof list === 'string') {
        availableList = document.querySelector(list);
      } else if (list instanceof Element) {
        availableList = list;
      } else {
        availableList = document.querySelector(hook.dataset[_utils2.default.toCamelCase(DATA_TRIGGER)]);
      }

      availableList.dataset.dropdownActive = true;

      var HookObject = availableHook.tagName === 'INPUT' ? _hook_input2.default : _hook_button2.default;
      this.hooks.push(new HookObject(availableHook, availableList, plugins, config));

      return this;
    },

    addHooks: function addHooks(hooks, plugins, config) {
      var _this2 = this;

      hooks.forEach(function (hook) {
        return _this2.addHook(hook, null, plugins, config);
      });
      return this;
    },

    setConfig: function setConfig(obj) {
      this.config = obj;
    },

    fireReady: function fireReady() {
      var readyEvent = new CustomEvent('ready.dl', {
        detail: {
          dropdown: this
        }
      });
      document.dispatchEvent(readyEvent);

      this.ready = true;
    },

    init: function init() {
      var _this3 = this;

      this.addEvents();

      this.fireReady();

      this.queuedData.forEach(function (data) {
        return _this3.addData(data);
      });
      this.queuedData = [];

      return this;
    }
  });

  return DropLab;
};

__webpack_require__(1);

var _hook_button = __webpack_require__(7);

var _hook_button2 = _interopRequireDefault(_hook_button);

var _hook_input = __webpack_require__(8);

var _hook_input2 = _interopRequireDefault(_hook_input);

var _utils = __webpack_require__(3);

var _utils2 = _interopRequireDefault(_utils);

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DATA_TRIGGER = _constants2.default.DATA_TRIGGER;

;

/***/ }),
/* 5 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function () {
  var currentKey;
  var currentFocus;
  var isUpArrow = false;
  var isDownArrow = false;
  var removeHighlight = function removeHighlight(list) {
    var itemElements = Array.prototype.slice.call(list.list.querySelectorAll('li:not(.divider)'), 0);
    var listItems = [];
    for (var i = 0; i < itemElements.length; i++) {
      var listItem = itemElements[i];
      listItem.classList.remove(_constants2.default.ACTIVE_CLASS);

      if (listItem.style.display !== 'none') {
        listItems.push(listItem);
      }
    }
    return listItems;
  };

  var setMenuForArrows = function setMenuForArrows(list) {
    var listItems = removeHighlight(list);
    if (list.currentIndex > 0) {
      if (!listItems[list.currentIndex - 1]) {
        list.currentIndex = list.currentIndex - 1;
      }

      if (listItems[list.currentIndex - 1]) {
        var el = listItems[list.currentIndex - 1];
        var filterDropdownEl = el.closest('.filter-dropdown');
        el.classList.add(_constants2.default.ACTIVE_CLASS);

        if (filterDropdownEl) {
          var filterDropdownBottom = filterDropdownEl.offsetHeight;
          var elOffsetTop = el.offsetTop - 30;

          if (elOffsetTop > filterDropdownBottom) {
            filterDropdownEl.scrollTop = elOffsetTop - filterDropdownBottom;
          }
        }
      }
    }
  };

  var mousedown = function mousedown(e) {
    var list = e.detail.hook.list;
    removeHighlight(list);
    list.show();
    list.currentIndex = 0;
    isUpArrow = false;
    isDownArrow = false;
  };
  var selectItem = function selectItem(list) {
    var listItems = removeHighlight(list);
    var currentItem = listItems[list.currentIndex - 1];
    var listEvent = new CustomEvent('click.dl', {
      detail: {
        list: list,
        selected: currentItem,
        data: currentItem.dataset
      }
    });
    list.list.dispatchEvent(listEvent);
    list.hide();
  };

  var keydown = function keydown(e) {
    var typedOn = e.target;
    var list = e.detail.hook.list;
    var currentIndex = list.currentIndex;
    isUpArrow = false;
    isDownArrow = false;

    if (e.detail.which) {
      currentKey = e.detail.which;
      if (currentKey === 13) {
        selectItem(e.detail.hook.list);
        return;
      }
      if (currentKey === 38) {
        isUpArrow = true;
      }
      if (currentKey === 40) {
        isDownArrow = true;
      }
    } else if (e.detail.key) {
      currentKey = e.detail.key;
      if (currentKey === 'Enter') {
        selectItem(e.detail.hook.list);
        return;
      }
      if (currentKey === 'ArrowUp') {
        isUpArrow = true;
      }
      if (currentKey === 'ArrowDown') {
        isDownArrow = true;
      }
    }
    if (isUpArrow) {
      currentIndex--;
    }
    if (isDownArrow) {
      currentIndex++;
    }
    if (currentIndex < 0) {
      currentIndex = 0;
    }
    list.currentIndex = currentIndex;
    setMenuForArrows(e.detail.hook.list);
  };

  document.addEventListener('mousedown.dl', mousedown);
  document.addEventListener('keydown.dl', keydown);
};

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/***/ }),
/* 6 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Object$assign;

__webpack_require__(1);

var _utils = __webpack_require__(3);

var _utils2 = _interopRequireDefault(_utils);

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var DropDown = function DropDown(list) {
  this.currentIndex = 0;
  this.hidden = true;
  this.list = typeof list === 'string' ? document.querySelector(list) : list;
  this.items = [];

  this.eventWrapper = {};

  this.getItems();
  this.initTemplateString();
  this.addEvents();

  this.initialState = list.innerHTML;
};

Object.assign(DropDown.prototype, (_Object$assign = {
  getItems: function getItems() {
    this.items = [].slice.call(this.list.querySelectorAll('li'));
    return this.items;
  },

  initTemplateString: function initTemplateString() {
    var items = this.items || this.getItems();

    var templateString = '';
    if (items.length > 0) templateString = items[items.length - 1].outerHTML;
    this.templateString = templateString;

    return this.templateString;
  },

  clickEvent: function clickEvent(e) {
    var selected = _utils2.default.closest(e.target, 'LI');
    if (!selected) return;

    this.addSelectedClass(selected);

    e.preventDefault();
    this.hide();

    var listEvent = new CustomEvent('click.dl', {
      detail: {
        list: this,
        selected: selected,
        data: e.target.dataset
      }
    });
    this.list.dispatchEvent(listEvent);
  },

  addSelectedClass: function addSelectedClass(selected) {
    this.removeSelectedClasses();
    selected.classList.add(_constants2.default.SELECTED_CLASS);
  },

  removeSelectedClasses: function removeSelectedClasses() {
    var items = this.items || this.getItems();

    items.forEach(function (item) {
      item.classList.remove(_constants2.default.SELECTED_CLASS);
    });
  },

  addEvents: function addEvents() {
    this.eventWrapper.clickEvent = this.clickEvent.bind(this);
    this.list.addEventListener('click', this.eventWrapper.clickEvent);
  },

  toggle: function toggle() {
    this.hidden ? this.show() : this.hide();
  },

  setData: function setData(data) {
    this.data = data;
    this.render(data);
  },

  addData: function addData(data) {
    this.data = (this.data || []).concat(data);
    this.render(this.data);
  },

  render: function render(data) {
    var children = data ? data.map(this.renderChildren.bind(this)) : [];
    var renderableList = this.list.querySelector('ul[data-dynamic]') || this.list;

    renderableList.innerHTML = children.join('');
  },

  renderChildren: function renderChildren(data) {
    var html = _utils2.default.t(this.templateString, data);
    var template = document.createElement('div');

    template.innerHTML = html;
    this.setImagesSrc(template);
    template.firstChild.style.display = data.droplab_hidden ? 'none' : 'block';

    return template.firstChild.outerHTML;
  },

  setImagesSrc: function setImagesSrc(template) {
    var images = [].slice.call(template.querySelectorAll('img[data-src]'));

    images.forEach(function (image) {
      image.src = image.getAttribute('data-src');
      image.removeAttribute('data-src');
    });
  },

  show: function show() {
    if (!this.hidden) return;
    this.list.style.display = 'block';
    this.currentIndex = 0;
    this.hidden = false;
  },

  hide: function hide() {
    if (this.hidden) return;
    this.list.style.display = 'none';
    this.currentIndex = 0;
    this.hidden = true;
  }

}, _defineProperty(_Object$assign, 'toggle', function toggle() {
  this.hidden ? this.show() : this.hide();
}), _defineProperty(_Object$assign, 'destroy', function destroy() {
  this.hide();
  this.list.removeEventListener('click', this.eventWrapper.clickEvent);
}), _Object$assign));

exports.default = DropDown;

/***/ }),
/* 7 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(1);

var _hook = __webpack_require__(2);

var _hook2 = _interopRequireDefault(_hook);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var HookButton = function HookButton(trigger, list, plugins, config) {
  _hook2.default.call(this, trigger, list, plugins, config);

  this.type = 'button';
  this.event = 'click';

  this.eventWrapper = {};

  this.addEvents();
  this.addPlugins();
};

HookButton.prototype = Object.create(_hook2.default.prototype);

Object.assign(HookButton.prototype, {
  addPlugins: function addPlugins() {
    var _this = this;

    this.plugins.forEach(function (plugin) {
      return plugin.init(_this);
    });
  },

  clicked: function clicked(e) {
    var buttonEvent = new CustomEvent('click.dl', {
      detail: {
        hook: this
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(buttonEvent);

    this.list.toggle();
  },

  addEvents: function addEvents() {
    this.eventWrapper.clicked = this.clicked.bind(this);
    this.trigger.addEventListener('click', this.eventWrapper.clicked);
  },

  removeEvents: function removeEvents() {
    this.trigger.removeEventListener('click', this.eventWrapper.clicked);
  },

  restoreInitialState: function restoreInitialState() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function removePlugins() {
    this.plugins.forEach(function (plugin) {
      return plugin.destroy();
    });
  },

  destroy: function destroy() {
    this.restoreInitialState();

    this.removeEvents();
    this.removePlugins();
  },

  constructor: HookButton
});

exports.default = HookButton;

/***/ }),
/* 8 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(1);

var _hook = __webpack_require__(2);

var _hook2 = _interopRequireDefault(_hook);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var HookInput = function HookInput(trigger, list, plugins, config) {
  _hook2.default.call(this, trigger, list, plugins, config);

  this.type = 'input';
  this.event = 'input';

  this.eventWrapper = {};

  this.addEvents();
  this.addPlugins();
};

Object.assign(HookInput.prototype, {
  addPlugins: function addPlugins() {
    var _this = this;

    this.plugins.forEach(function (plugin) {
      return plugin.init(_this);
    });
  },

  addEvents: function addEvents() {
    this.eventWrapper.mousedown = this.mousedown.bind(this);
    this.eventWrapper.input = this.input.bind(this);
    this.eventWrapper.keyup = this.keyup.bind(this);
    this.eventWrapper.keydown = this.keydown.bind(this);

    this.trigger.addEventListener('mousedown', this.eventWrapper.mousedown);
    this.trigger.addEventListener('input', this.eventWrapper.input);
    this.trigger.addEventListener('keyup', this.eventWrapper.keyup);
    this.trigger.addEventListener('keydown', this.eventWrapper.keydown);
  },

  removeEvents: function removeEvents() {
    this.hasRemovedEvents = true;

    this.trigger.removeEventListener('mousedown', this.eventWrapper.mousedown);
    this.trigger.removeEventListener('input', this.eventWrapper.input);
    this.trigger.removeEventListener('keyup', this.eventWrapper.keyup);
    this.trigger.removeEventListener('keydown', this.eventWrapper.keydown);
  },

  input: function input(e) {
    if (this.hasRemovedEvents) return;

    this.list.show();

    var inputEvent = new CustomEvent('input.dl', {
      detail: {
        hook: this,
        text: e.target.value
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(inputEvent);
  },

  mousedown: function mousedown(e) {
    if (this.hasRemovedEvents) return;

    var mouseEvent = new CustomEvent('mousedown.dl', {
      detail: {
        hook: this,
        text: e.target.value
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(mouseEvent);
  },

  keyup: function keyup(e) {
    if (this.hasRemovedEvents) return;

    this.keyEvent(e, 'keyup.dl');
  },

  keydown: function keydown(e) {
    if (this.hasRemovedEvents) return;

    this.keyEvent(e, 'keydown.dl');
  },

  keyEvent: function keyEvent(e, eventName) {
    this.list.show();

    var keyEvent = new CustomEvent(eventName, {
      detail: {
        hook: this,
        text: e.target.value,
        which: e.which,
        key: e.key
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(keyEvent);
  },

  restoreInitialState: function restoreInitialState() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function removePlugins() {
    this.plugins.forEach(function (plugin) {
      return plugin.destroy();
    });
  },

  destroy: function destroy() {
    this.restoreInitialState();

    this.removeEvents();
    this.removePlugins();

    this.list.destroy();
  }
});

exports.default = HookInput;

/***/ }),
/* 9 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _droplab = __webpack_require__(4);

var _droplab2 = _interopRequireDefault(_droplab);

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

var _keyboard = __webpack_require__(5);

var _keyboard2 = _interopRequireDefault(_keyboard);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DATA_TRIGGER = _constants2.default.DATA_TRIGGER;
var keyboard = (0, _keyboard2.default)();

var setup = function setup() {
  window.DropLab = (0, _droplab2.default)();
};

setup();

exports.default = setup;

/***/ })
/******/ ]);
