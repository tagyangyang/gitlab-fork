import Cookies from 'js-cookie';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

const USER_CALLOUT_TEMPLATE = `
  <div class="bordered-box landing content-block">
    <button class="btn btn-default close close-user-callout" type="button" aria-label="Close">
      <i class="fa fa-times dismiss-icon"></i>
    </button>
    <div class="svg-container"></div>
    <div class="user-callout-copy">
      <h4>
        Customize your experience
      </h4>
      <p>
        Change syntax themes, default project pages, and more in preferences.
      </p>
      <a class="btn btn-primary user-callout-btn" href="/profile/preferences">Check it out</a>
    </div>
  </div>
</div>`;

export default class UserCallout {
  constructor() {
    this.isCalloutDismissed = Cookies.get(USER_CALLOUT_COOKIE);
    this.userCalloutBody = $('.user-callout');
    this.init();
  }

  init() {
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      $('.js-close-callout').on('click', e => this.dismissCallout(e));
    }
  }

  dismissCallout(e) {
    const $currentTarget = $(e.currentTarget);

    Cookies.set(USER_CALLOUT_COOKIE, 'true');

    if ($currentTarget.hasClass('close')) {
      this.userCalloutBody.remove();
    }
  }
}
