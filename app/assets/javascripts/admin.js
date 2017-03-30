/* eslint-disable func-names, space-before-function-paren, wrap-iife, one-var, no-var, one-var-declaration-per-line, no-unused-vars, no-else-return, prefer-arrow-callback, camelcase, quotes, comma-dangle, max-len */

function Admin() {
  var modal, showBlacklistType;
  $('input#user_force_random_password').on('change', function(elem) {
    var elems;
    elems = $('#user_password, #user_password_confirmation');
    if ($(this).attr('checked')) {
      return elems.val('').attr('disabled', true);
    } else {
      return elems.removeAttr('disabled');
    }
  });
  $('body').on('click', '.js-toggle-colors-link', function(e) {
    e.preventDefault();
    return $('.js-toggle-colors-container').toggle();
  });
  $('.log-tabs a').click(function(e) {
    e.preventDefault();
    return $(this).tab('show');
  });
  $('.log-bottom').click(function(e) {
    var visible_log;
    e.preventDefault();
    visible_log = $(".file-content:visible");
    return visible_log.animate({
      scrollTop: visible_log.find('ol').height()
    }, "fast");
  });
  modal = $('.change-owner-holder');
  $('.change-owner-link').bind("click", function(e) {
    e.preventDefault();
    $(this).hide();
    return modal.show();
  });
  $('.change-owner-cancel-link').bind("click", function(e) {
    e.preventDefault();
    modal.hide();
    return $('.change-owner-link').show();
  });
  $('li.project_member').bind('ajax:success', function() {
    return gl.utils.refreshCurrentPage();
  });
  $('li.group_member').bind('ajax:success', function() {
    return gl.utils.refreshCurrentPage();
  });
  showBlacklistType = function() {
    if ($("input[name='blacklist_type']:checked").val() === 'file') {
      $('.blacklist-file').show();
      return $('.blacklist-raw').hide();
    } else {
      $('.blacklist-file').hide();
      return $('.blacklist-raw').show();
    }
  };
  $("input[name='blacklist_type']").click(showBlacklistType);
  showBlacklistType();
}

window.Admin = Admin;
