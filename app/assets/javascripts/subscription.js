(function() {
  this.Subscription = (function() {
    var ICON_SUBSCRIBE = 'eye';
    var ICON_UNSUBSCRIBE = 'eye-slash';

    function Subscription(container) {
      var $container = $(container);

      this.url = $container.attr('data-url');
      this.$subscribeButton = $container.find('.js-subscribe-button');
      this.$subscriptionStatus = $container.find('.subscription-status');
      this.$subscriptionIcon = $container.find('.subscription-icon');

      this.bindEvents();
    }

    Subscription.prototype.bindEvents = function () {
      var self = this;

      this.$subscribeButton.off('click').on('click', function (e) {
        e.preventDefault();
        self.toggleSubscription();
      });
    };

    Subscription.prototype.toggleSubscription = function() {
      this.$subscribeButton.addClass('disabled'); // disable only the visible button that was clicked

      $.post(this.url)
        .success(this.onToggleSubscriptionSuccess.bind(this))
        .fail(this.onToggleSubscriptionFail.bind(this))
        .always(function () {
          this.$subscribeButton.removeClass('disabled');  // enable only the visible button that was clicked
        }.bind(this));
    };

    Subscription.prototype.onToggleSubscriptionSuccess = function() {
      var currentIcon = this.$subscriptionIcon.attr('data-icon');
      var icon = currentIcon === ICON_SUBSCRIBE ? ICON_UNSUBSCRIBE : ICON_SUBSCRIBE;
      var currentStatus = this.$subscriptionStatus.attr('data-status');
      var status = currentStatus === 'subscribed' ? 'unsubscribed' : 'subscribed';
      var action = status === 'subscribed' ? 'Unsubscribe' : 'Subscribe';

      this.$subscriptionIcon
        .attr('data-icon', icon)
        .find('.label-subscribe-button-icon')
        .removeClass("fa-" + currentIcon)
        .addClass("fa-" + icon);

      this.$subscriptionStatus
        .attr('data-status', status)
        .find('> div')
        .toggleClass('hidden');

      this.$subscribeButton
        .find('span')
        .text(action);

      if (this.$subscribeButton.attr('data-original-title')) {
        this.$subscribeButton
          .tooltip('hide')
          .attr('data-original-title', action)
          .tooltip('fixTitle');
      }
    }

    Subscription.prototype.onToggleSubscriptionFail = function() {
      new Flash('Failed to update subscription');
    }

    return Subscription;
  })();

}).call(this);
