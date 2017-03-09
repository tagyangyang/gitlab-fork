/* eslint-disable func-names, space-before-function-paren, no-param-reassign, quotes, prefer-template, no-var, one-var, no-unused-vars, one-var-declaration-per-line, no-void, consistent-return, no-empty, max-len */
/* global Autosave */

window.Autosave = function (field, key) {
  this.field = field;
  if (key.join != null) {
    key = key.join("/");
  }
  this.key = "autosave/" + key;
  this.field.data("autosave", this);
  this.restore();
  this.field.on("input", this.save);
};

Autosave.prototype.restore = function() {
  var e, text;
  if (window.localStorage == null) {
    return;
  }
  try {
    text = window.localStorage.getItem(this.key);
  } catch (error) {
    e = error;
    return;
  }
  if ((text != null ? text.length : void 0) > 0) {
    this.field.val(text);
  }
  return this.field.trigger("input");
};

Autosave.prototype.save = function() {
  var text;
  if (window.localStorage == null) {
    return;
  }
  text = this.field.val();
  if ((text != null ? text.length : void 0) > 0) {
    try {
      return window.localStorage.setItem(this.key, text);
    } catch (error) {}
  } else {
    return this.reset();
  }
};

Autosave.prototype.reset = function() {
  if (window.localStorage == null) {
    return;
  }
  try {
    return window.localStorage.removeItem(this.key);
  } catch (error) {}
};
