/* global Element */
/* eslint-disable consistent-return, max-len, no-empty, func-names */

Element.prototype.closest = Element.prototype.closest || function closest(selector, selectedElement = this) {
  if (!selectedElement) return;
  return selectedElement.matches(selector) ? selectedElement : Element.prototype.closest(selector, selectedElement.parentElement);
};

Element.prototype.matches = Element.prototype.matches ||
  Element.prototype.matchesSelector ||
  Element.prototype.mozMatchesSelector ||
  Element.prototype.msMatchesSelector ||
  Element.prototype.oMatchesSelector ||
  Element.prototype.webkitMatchesSelector ||
  function (s) {
    const matches = (this.document || this.ownerDocument).querySelectorAll(s);
    let i = matches.length - 1;
    while (i >= 0 && matches.item(i) !== this) { i -= 1; }
    return i > -1;
  };

// See https://github.com/epiloque/element-dataset/blob/c20e5706d710cd2b51a6ebae4b71a478f6039af9/src/index.js
if (!document.documentElement.dataset && (!Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'dataset') || !Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'dataset').get)) {
  Object.defineProperty(HTMLElement.prototype, 'dataset', {
    enumerable: true,
    get: function get() {
      const element = this;
      const map = {};
      const attributes = this.attributes;

      function toUpperCase(n0) {
        return n0.charAt(1).toUpperCase();
      }

      function getter() {
        return this.value;
      }

      function setter(name, value) {
        if (typeof value !== 'undefined') {
          this.setAttribute(name, value);
        } else {
          this.removeAttribute(name);
        }
      }

      for (let i = 0; i < attributes.length; i += 1) {
        const attribute = attributes[i];

        // This test really should allow any XML Name without
        // colons (and non-uppercase for XHTML)

        if (attribute && attribute.name && (/^data-\w[\w-]*$/).test(attribute.name)) {
          const name = attribute.name;
          const value = attribute.value;

          // Change to CamelCase

          const propName = name.substr(5).replace(/-./g, toUpperCase);

          Object.defineProperty(map, propName, {
            enumerable: this.enumerable,
            get: getter.bind({ value: value || '' }),
            set: setter.bind(element, name),
          });
        }
      }
      return map;
    },
  });
}
