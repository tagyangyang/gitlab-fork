/* eslint-disable func-names, space-before-function-paren, wrap-iife, one-var, no-var, camelcase, one-var-declaration-per-line, no-else-return, max-len */

function ConfirmDangerModal(form, text) {
  var project_path, submit;
  this.form = form;
  $('.js-confirm-text').text(text || '');
  $('.js-confirm-danger-input').val('');
  $('#modal-confirm-danger').modal('show');
  project_path = $('.js-confirm-danger-match').text();
  submit = $('.js-confirm-danger-submit');
  submit.disable();
  $('.js-confirm-danger-input').off('input');
  $('.js-confirm-danger-input').on('input', function() {
    if (gl.utils.rstrip($(this).val()) === project_path) {
      return submit.enable();
    } else {
      return submit.disable();
    }
  });
  $('.js-confirm-danger-submit').off('click');
  $('.js-confirm-danger-submit').on('click', () => this.form.submit());
}

window.ConfirmDangerModal = ConfirmDangerModal;
