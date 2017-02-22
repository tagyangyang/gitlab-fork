/* eslint-disable no-new */
/* jshint esversion: 6 */

$(() => {
  const IMAGE_SELECTOR = '.no-attachment-icon';

  class GitLabLightbox {
    constructor() {
      this.$lightbox = null;
      this.$lbLink = null;
      this.$lbImage = null;
      this.$closeBtn = null;
      this.initLightbox();
      this.addBindings();
    }

    initLightbox() {
      /* Create base lightbox template
      <div class="gl-lightbox">
        <i class="fa fa-close dismiss"></i>
        <a href="#" target="_blank">
          <img src="" alt="" />
        </a>
      </div>
      */
      if (!document.querySelector('.gl-lightbox')) {
        this.$lightbox = $('<div/>', { class: 'gl-lightbox' });
        this.$closeBtn = $('<i/>', { class: 'fa fa-close dismiss' });
        this.$lbLink = $('<a/>', { href: '', target: '_blank' });
        this.$lbImage = $('<img/>', { src: '' });
        this.$lbLink.append(this.$lbImage);
        this.$lightbox.append(this.$closeBtn);
        this.$lightbox.append(this.$lbLink);
        $('body').append(this.$lightbox);
      }
    }

    addBindings() {
      this.$lightbox.on('click', this.hideLightbox.bind(this));
      $(IMAGE_SELECTOR).on('click', this.showLightbox.bind(this));
      $(document).on('scroll', this.hideLightbox.bind(this));
      $(document).on('markdown-preview:fetched', this.addPreviewBindings.bind(this));
      $(document).on('ajax:success', '.gfm-form', this.addNoteBinding.bind(this));
    }

    addPreviewBindings(e, $form) {
      if (!$form) return;
      $form.find(IMAGE_SELECTOR).on('click', this.showLightbox.bind(this));
    }

    addNoteBinding(e, data) {
      $(`#note_${data.id} ${IMAGE_SELECTOR}`).on('click',
       this.showLightbox.bind(this));
    }

    showLightbox(e) {
      e.preventDefault();
      this.$lightbox.addClass('show-box');
      this.$lbLink.attr('href', e.target.src);
      this.$lbImage.attr('src', e.target.src);
      this.$lbImage.attr('alt', e.target.alt);
    }

    hideLightbox() {
      this.$lightbox.removeClass('show-box');
    }
  }

  window.gl = window.gl || {};
  window.gl.GitLabLightbox = GitLabLightbox;

  new GitLabLightbox();
});
