/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, prefer-arrow-callback, no-else-return, quotes, quote-props, comma-dangle, one-var, one-var-declaration-per-line, max-len */
/* global u2f */
/* global U2FError */
/* global U2FUtil */

// Authenticate U2F (universal 2nd factor) devices for users to authenticate with.
//
// State Flow #1: setup -> in_progress -> authenticated -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup
const global = window.gl || (window.gl = {});

var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

function U2FAuthenticate(container, form, u2fParams, fallbackButton, fallbackUI) {
  this.container = container;
  this.renderNotSupported = bind(this.renderNotSupported, this);
  this.renderAuthenticated = bind(this.renderAuthenticated, this);
  this.renderError = bind(this.renderError, this);
  this.renderInProgress = bind(this.renderInProgress, this);
  this.renderTemplate = bind(this.renderTemplate, this);
  this.authenticate = bind(this.authenticate, this);
  this.start = bind(this.start, this);
  this.appId = u2fParams.app_id;
  this.challenge = u2fParams.challenge;
  this.form = form;
  this.fallbackButton = fallbackButton;
  this.fallbackUI = fallbackUI;
  if (this.fallbackButton) this.fallbackButton.addEventListener('click', this.switchToFallbackUI.bind(this));
  this.signRequests = u2fParams.sign_requests.map(function(request) {
    // The U2F Javascript API v1.1 requires a single challenge, with
    // _no challenges per-request_. The U2F Javascript API v1.0 requires a
    // challenge per-request, which is done by copying the single challenge
    // into every request.
    //
    // In either case, we don't need the per-request challenges that the server
    // has generated, so we can remove them.
    //
    // Note: The server library fixes this behaviour in (unreleased) version 1.0.0.
    // This can be removed once we upgrade.
    // https://github.com/castle/ruby-u2f/commit/103f428071a81cd3d5f80c2e77d522d5029946a4
    return _(request).omit('challenge');
  });
}

U2FAuthenticate.prototype.start = function() {
  if (U2FUtil.isU2FSupported()) {
    return this.renderInProgress();
  } else {
    return this.renderNotSupported();
  }
};

U2FAuthenticate.prototype.authenticate = function() {
  return u2f.sign(this.appId, this.challenge, this.signRequests, (function(_this) {
    return function(response) {
      var error;
      if (response.errorCode) {
        error = new U2FError(response.errorCode, 'authenticate');
        return _this.renderError(error);
      } else {
        return _this.renderAuthenticated(JSON.stringify(response));
      }
    };
  })(this), 10);
};

// Rendering #
U2FAuthenticate.prototype.templates = {
  "notSupported": "#js-authenticate-u2f-not-supported",
  "setup": '#js-authenticate-u2f-setup',
  "inProgress": '#js-authenticate-u2f-in-progress',
  "error": '#js-authenticate-u2f-error',
  "authenticated": '#js-authenticate-u2f-authenticated'
};

U2FAuthenticate.prototype.renderTemplate = function(name, params) {
  var template, templateString;
  templateString = $(this.templates[name]).html();
  template = _.template(templateString);
  return this.container.html(template(params));
};

U2FAuthenticate.prototype.renderInProgress = function() {
  this.renderTemplate('inProgress');
  return this.authenticate();
};

U2FAuthenticate.prototype.renderError = function(error) {
  this.renderTemplate('error', {
    error_message: error.message(),
    error_code: error.errorCode
  });
  return this.container.find('#js-u2f-try-again').on('click', this.renderInProgress);
};

U2FAuthenticate.prototype.renderAuthenticated = function(deviceResponse) {
  this.renderTemplate('authenticated');
  const container = this.container[0];
  container.querySelector('#js-device-response').value = deviceResponse;
  container.querySelector(this.form).submit();
  this.fallbackButton.classList.add('hidden');
};

U2FAuthenticate.prototype.renderNotSupported = function() {
  return this.renderTemplate('notSupported');
};

U2FAuthenticate.prototype.switchToFallbackUI = function() {
  this.fallbackButton.classList.add('hidden');
  this.container[0].classList.add('hidden');
  this.fallbackUI.classList.remove('hidden');
};

global.gl.U2FAuthenticate = U2FAuthenticate;
