function switchToViewer(name) {
  const $target = $(`.js-blob-viewer-switcher[data-viewer='${name}']`);
  $('.js-blob-viewer-switcher.active').removeClass('active');
  $target.addClass('active');
  $target.blur();

  $('.blob-viewer').hide();
  $(`.blob-viewer[data-type='${name}']`).show();
}

document.addEventListener('DOMContentLoaded', () => {
  $('.js-blob-viewer-switcher').on('click', (e) => {
    const $target = $(e.target);

    e.preventDefault();

    switchToViewer($target.data('viewer'));
  });

  $('.js-copy-blob-content-btn').on('click', (e) => {
    switchToViewer('simple');
  });

  if (location.hash.startsWith('#L')) {
    switchToViewer('simple');
  }
});
