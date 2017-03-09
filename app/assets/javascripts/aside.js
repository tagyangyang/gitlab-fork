/* eslint-disable func-names, space-before-function-paren, quotes, prefer-arrow-callback, no-var, one-var, one-var-declaration-per-line, no-else-return, max-len */

window.Aside = function () {
  $(document).off("click", "a.show-aside");
  $(document).on("click", 'a.show-aside', function(e) {
    var btn, icon;
    e.preventDefault();
    btn = $(e.currentTarget);
    icon = btn.find('i');
    if (icon.hasClass('fa-angle-left')) {
      btn.parent().find('section').hide();
      btn.parent().find('aside').fadeIn();
      return icon.removeClass('fa-angle-left').addClass('fa-angle-right');
    } else {
      btn.parent().find('aside').hide();
      btn.parent().find('section').fadeIn();
      return icon.removeClass('fa-angle-right').addClass('fa-angle-left');
    }
  });
};
