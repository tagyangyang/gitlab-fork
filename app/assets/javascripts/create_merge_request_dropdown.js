class CreateMergeRequestDropdown {
  constructor(wrapperEl) {
    this.wrapperEl = wrapperEl;
    this.createMergeRequestButton = this.wrapperEl.querySelector('.js-create-merge-request');
    this.init();
  }

  init() {
    const xhr = this.checkAbilityToCreateBranch();

    xhr.done(() => {
      this.initDropdown();
    });
  }

  checkAbilityToCreateBranch() {
    const available = this.wrapperEl.querySelector('.available');
    const unavailable = this.wrapperEl.querySelector('.unavailable');
    const xhr = $.getJSON(this.wrapperEl.dataset.path);

    xhr.done((data) => {
      if (data.can_create_branch) {
        available.classList.remove('hide');
      } else {
        unavailable.classList.remove('hide');
      }
    });

    xhr.fail(() => {
      unavailable.classList.remove('hide');
      new Flash('Failed to check if a new branch can be created.');
    });

    return xhr;
  }

  initDropdown() {
    this.droplab = new DropLab();
    this.bindEvents();
  }

  bindEvents() {
    this.createMergeRequestButton
      .addEventListener('click', this.onClickCreateMergeRequestButton.bind(this));
  }

  onClickCreateMergeRequestButton(e) {
    e.preventDefault();

    const xhr = this.goToCreateMergeRequest();

    this.createMergeRequestButton.classList.add('disabled');

    xhr.always(() => {
      this.createMergeRequestButton.classList.remove('disabled');
    });
  }

  goToCreateMergeRequest() {
    const xhr = $.ajax({
      url: 'http://ip.jsontest.com/',
      data: {}
    });

    xhr.done(() => {
      console.log('Redirect to merge request page');
    });

    xhr.fail(() => {
      new Flash('Failed to create Merge Request. Please try again.');
    });

    return xhr;
  }

  initCanCreateBranch() {

  }
}

export default CreateMergeRequestDropdown;
