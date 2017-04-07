/* eslint-disable space-before-function-paren, new-parens, quotes, no-var, one-var, one-var-declaration-per-line, comma-dangle, max-len */
/* global MockU2FDevice */
/* global U2FRegister */

require('~/u2f/register');
require('~/u2f/util');
require('~/u2f/error');
require('vendor/u2f');
require('./mock_u2f_device');

(function() {
  describe('U2FRegister', function() {
    preloadFixtures('u2f/register.html.raw');

    beforeEach(function() {
      loadFixtures('u2f/register.html.raw');
      this.u2fDevice = new MockU2FDevice;
      this.container = $("#js-register-u2f");
      this.component = new U2FRegister(this.container, $("#js-register-u2f-templates"), {}, "token");
      return this.component.start();
    });
    it('allows registering a U2F device', function() {
      var deviceResponse, inProgressMessage, registeredMessage, setupButton;
      setupButton = this.container.find("#js-setup-u2f-device");
      expect(setupButton.text()).toBe('Setup new U2F device');
      setupButton.trigger('click');
      inProgressMessage = this.container.children("p");
      expect(inProgressMessage.text()).toContain("Trying to communicate with your device");
      this.u2fDevice.respondToRegisterRequest({
        deviceData: "this is data from the device"
      });
      registeredMessage = this.container.find('p');
      deviceResponse = this.container.find('#js-device-response');
      expect(registeredMessage.text()).toContain("Your device was successfully set up!");
      return expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}');
    });
    return describe("errors", function() {
      it("doesn't allow the same device to be registered twice (for the same user", function() {
        var errorMessage, setupButton;
        setupButton = this.container.find("#js-setup-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToRegisterRequest({
          errorCode: 4
        });
        errorMessage = this.container.find("p");
        return expect(errorMessage.text()).toContain("already been registered with us");
      });
      it("displays an error message for other errors", function() {
        var errorMessage, setupButton;
        setupButton = this.container.find("#js-setup-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToRegisterRequest({
          errorCode: "error!"
        });
        errorMessage = this.container.find("p");
        return expect(errorMessage.text()).toContain("There was a problem communicating with your device");
      });
      return it("allows retrying registration after an error", function() {
        var registeredMessage, retryButton, setupButton;
        setupButton = this.container.find("#js-setup-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToRegisterRequest({
          errorCode: "error!"
        });
        retryButton = this.container.find("#U2FTryAgain");
        retryButton.trigger('click');
        setupButton = this.container.find("#js-setup-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToRegisterRequest({
          deviceData: "this is data from the device"
        });
        registeredMessage = this.container.find("p");
        return expect(registeredMessage.text()).toContain("Your device was successfully set up!");
      });
    });
  });
}).call(window);
