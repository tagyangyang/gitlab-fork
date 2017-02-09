/* eslint-disable func-names, space-before-function-paren, wrap-iife, max-len, no-var, prefer-arrow-callback, consistent-return, one-var, one-var-declaration-per-line, no-unused-vars, no-else-return, prefer-template, quotes, comma-dangle, no-param-reassign, no-void, brace-style, no-underscore-dangle, no-return-assign, camelcase */
/* global Cookies */

var emojiMap = require('emoji-map');
var emojiAliases = require('emoji-aliases');
const glEmoji = require('./behaviors/gl_emoji.js.es6');

const glEmojiTag = glEmoji.glEmojiTag;

var transitionEndEventString = 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd';
var requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.setTimeout;

var categoryMap = null;

var categoryLabelMap = {
  activity: 'Activity',
  people: 'People',
  nature: 'Nature',
  food: 'Food',
  travel: 'Travel',
  objects: 'Objects',
  symbols: 'Symbols',
  flags: 'Flags'
};

function buildCategoryMap() {
  return Object.keys(emojiMap).reduce(function(currentCategoryMap, emojiNameKey) {
    var emojiInfo = emojiMap[emojiNameKey];
    if (currentCategoryMap[emojiInfo.category]) {
      currentCategoryMap[emojiInfo.category].push(emojiNameKey);
    }

    return currentCategoryMap;
  }, {
    activity: [],
    people: [],
    nature: [],
    food: [],
    travel: [],
    objects: [],
    symbols: [],
    flags: []
  });
}

function renderCategory(name, emojiList) {
  return `
    <h5 class="emoji-menu-title">
      ${name}
    </h5>
    <ul class="clearfix emoji-menu-list">
      ${emojiList.map(function(emojiName) {
        return `
          <li class="emoji-menu-list-item">
            <button class="emoji-menu-btn text-center js-emoji-btn" type="button">
              ${glEmojiTag(emojiName, {
                sprite: true
              })}
            </button>
          </li>
        `;
      }).join('\n')}
    </ul>
  `;
}

(function() {
  this.AwardsHandler = (function() {
    var FROM_SENTENCE_REGEX = /(?:, and | and |, )/; // For separating lists produced by ruby's Array#toSentence
    function AwardsHandler() {
      this.aliases = emojiAliases;
      // If the user shows intent let's pre-build the menu
      $(document).one('mouseenter focus', '.js-add-award', function preBuildEmojiMenu() {
        var $menu = $('.emoji-menu');
        if ($menu.length === 0) {
          requestAnimationFrame(() => {
            this.createEmojiMenu();
          });
        }
      }.bind(this));
      $(document).on('click', '.js-add-award', function(e) {
        e.stopPropagation();
        e.preventDefault();
        this.showEmojiMenu($(e.currentTarget));
      }.bind(this));

      $('html').on('click', function(e) {
        var $target;
        $target = $(e.target);
        if (!$target.closest('.emoji-menu-content').length) {
          $('.js-awards-block.current').removeClass('current');
        }
        if (!$target.closest('.emoji-menu').length) {
          if ($('.emoji-menu').is(':visible')) {
            $('.js-add-award.is-active').removeClass('is-active');
            return $('.emoji-menu').removeClass('is-visible');
          }
        }
      });
      $(document).off('click', '.js-emoji-btn').on('click', '.js-emoji-btn', (function(_this) {
        return function(e) {
          var $target, emoji, $glEmojiElement, $spriteIconElement;
          e.preventDefault();
          $target = $(e.currentTarget);
          $glEmojiElement = $target.find('gl-emoji');
          $spriteIconElement = $target.find('.icon');
          emoji = ($glEmojiElement.length ? $glEmojiElement : $spriteIconElement).data('name');
          $target.closest('.js-awards-block').addClass('current');
          return _this.addAward(_this.getVotesBlock(), _this.getAwardUrl(), emoji);
        };
      })(this));
    }

    AwardsHandler.prototype.showEmojiMenu = function($addBtn) {
      var url;
      var $menu = $('.emoji-menu');

      if ($addBtn.hasClass('js-note-emoji')) {
        $addBtn.closest('.note').find('.js-awards-block').addClass('current');
      } else {
        $addBtn.closest('.js-awards-block').addClass('current');
      }
      if ($menu.length) {
        if ($menu.is('.is-visible')) {
          $addBtn.removeClass('is-active');
          $menu.removeClass('is-visible');
          return $('#emoji_search').blur();
        } else {
          $addBtn.addClass('is-active');
          this.positionMenu($menu, $addBtn);
          $menu.addClass('is-visible');
          return $('#emoji_search').focus();
        }
      } else {
        $addBtn.addClass('is-loading is-active');
        return this.createEmojiMenu((function(_this) {
          return function() {
            $addBtn.removeClass('is-loading');
            $menu = $('.emoji-menu');
            _this.positionMenu($menu, $addBtn);
            if (!_this.frequentEmojiBlockRendered) {
              _this.renderFrequentlyUsedBlock();
            }
            return setTimeout(function() {
              $menu.addClass('is-visible');
              $('#emoji_search').focus();
            }, 200);
          };
        })(this));
      }
    };

    AwardsHandler.prototype.createEmojiMenu = function(callback) {
      var addRemainingEmojiMenuCategories = this.addRemainingEmojiMenuCategories;
      var $menu;
      var emojiMenuMarkup;
      if (this.isCreatingEmojiMenu) {
        return;
      }
      this.isCreatingEmojiMenu = true;

      categoryMap = categoryMap || buildCategoryMap();
      emojiMenuMarkup = `
        <div class="emoji-menu">
          <input type="text" name="emoji_search" id="emoji_search" value="" class="emoji-search search-input form-control" placeholder="Search emoji" />

          <div class="emoji-menu-content">
            ${(function() {
              // Render the first category
              var categoryNameKey = Object.keys(categoryMap)[0];
              var emojisInCategory = categoryMap[categoryNameKey];
              return renderCategory(categoryLabelMap[categoryNameKey], emojisInCategory);
            })()}
          </div>
        </div>
      `;

      document.body.insertAdjacentHTML('beforeend', emojiMenuMarkup);
      $menu = $('.emoji-menu');
      $menu.on(transitionEndEventString, function menuTransitionEndHandler(e) {
        if (e.target === e.currentTarget) {
          addRemainingEmojiMenuCategories();
          $menu.off(transitionEndEventString, menuTransitionEndHandler);
        }
      });
      this.setupSearch();
      if (callback) {
        callback();
      }
    };

    AwardsHandler.prototype.addRemainingEmojiMenuCategories = function() {
      var emojiContentElement;
      var remainingCategories;

      if (this.isAddingRemainingEmojiMenuCategories) {
        return;
      }
      this.isAddingRemainingEmojiMenuCategories = true;

      categoryMap = categoryMap || buildCategoryMap();

      // Avoid the jank and render the remaining categories separately
      // This will take more time, but makes UI more responsive
      emojiContentElement = document.querySelector('.emoji-menu .emoji-menu-content');
      remainingCategories = Object.keys(categoryMap).slice(1);
      remainingCategories.reduce(function(promiseChain, categoryNameKey, index) {
        return promiseChain.then(function() {
          return new Promise(function(resolve) {
            requestAnimationFrame(function() {
              var emojisInCategory = categoryMap[categoryNameKey];
              var categoryMarkup = renderCategory(categoryLabelMap[categoryNameKey], emojisInCategory);
              emojiContentElement.insertAdjacentHTML('beforeend', categoryMarkup);
              resolve();
            });
          });
        });
      }, Promise.resolve());
    }.bind(this);

    AwardsHandler.prototype.positionMenu = function($menu, $addBtn) {
      var css, position;
      position = $addBtn.data('position');
      // The menu could potentially be off-screen or in a hidden overflow element
      // So we position the element absolute in the body
      css = {
        top: ($addBtn.offset().top + $addBtn.outerHeight()) + "px"
      };
      if (position === 'right') {
        css.left = (($addBtn.offset().left - $menu.outerWidth()) + 20) + "px";
        $menu.addClass('is-aligned-right');
      } else {
        css.left = ($addBtn.offset().left) + "px";
        $menu.removeClass('is-aligned-right');
      }
      return $menu.css(css);
    };

    AwardsHandler.prototype.addAward = function(votesBlock, awardUrl, emoji, checkMutuality, callback) {
      if (checkMutuality == null) {
        checkMutuality = true;
      }
      emoji = this.normalizeEmojiName(emoji);
      this.postEmoji(awardUrl, emoji, (function(_this) {
        return function() {
          _this.addAwardToEmojiBar(votesBlock, emoji, checkMutuality);
          return typeof callback === "function" ? callback() : void 0;
        };
      })(this));
      return $('.emoji-menu').removeClass('is-visible');
    };

    AwardsHandler.prototype.addAwardToEmojiBar = function(votesBlock, emoji, checkForMutuality) {
      var $emojiButton, counter;
      if (checkForMutuality == null) {
        checkForMutuality = true;
      }
      if (checkForMutuality) {
        this.checkMutuality(votesBlock, emoji);
      }
      this.addEmojiToFrequentlyUsedList(emoji);
      emoji = this.normalizeEmojiName(emoji);
      $emojiButton = this.findEmojiIcon(votesBlock, emoji).parent();
      if ($emojiButton.length > 0) {
        if (this.isActive($emojiButton)) {
          return this.decrementCounter($emojiButton, emoji);
        } else {
          counter = $emojiButton.find('.js-counter');
          counter.text(parseInt(counter.text(), 10) + 1);
          $emojiButton.addClass('active');
          this.addYouToUserList(votesBlock, emoji);
          return this.animateEmoji($emojiButton);
        }
      } else {
        votesBlock.removeClass('hidden');
        return this.createEmoji(votesBlock, emoji);
      }
    };

    AwardsHandler.prototype.getVotesBlock = function() {
      var currentBlock;
      currentBlock = $('.js-awards-block.current');
      if (currentBlock.length) {
        return currentBlock;
      } else {
        return $('.js-awards-block').eq(0);
      }
    };

    AwardsHandler.prototype.getAwardUrl = function() {
      return this.getVotesBlock().data('award-url');
    };

    AwardsHandler.prototype.checkMutuality = function(votesBlock, emoji) {
      var $emojiButton, awardUrl, isAlreadyVoted, mutualVote;
      awardUrl = this.getAwardUrl();
      if (emoji === 'thumbsup' || emoji === 'thumbsdown') {
        mutualVote = emoji === 'thumbsup' ? 'thumbsdown' : 'thumbsup';
        $emojiButton = votesBlock.find("[data-name=" + mutualVote + "]").parent();
        isAlreadyVoted = $emojiButton.hasClass('active');
        if (isAlreadyVoted) {
          this.addAward(votesBlock, awardUrl, mutualVote, false);
        }
      }
    };

    AwardsHandler.prototype.isActive = function($emojiButton) {
      return $emojiButton.hasClass('active');
    };

    AwardsHandler.prototype.decrementCounter = function($emojiButton, emoji) {
      var counter, counterNumber;
      counter = $('.js-counter', $emojiButton);
      counterNumber = parseInt(counter.text(), 10);
      if (counterNumber > 1) {
        counter.text(counterNumber - 1);
        this.removeYouFromUserList($emojiButton, emoji);
      } else if (emoji === 'thumbsup' || emoji === 'thumbsdown') {
        $emojiButton.tooltip('destroy');
        counter.text('0');
        this.removeYouFromUserList($emojiButton, emoji);
        if ($emojiButton.parents('.note').length) {
          this.removeEmoji($emojiButton);
        }
      } else {
        this.removeEmoji($emojiButton);
      }
      return $emojiButton.removeClass('active');
    };

    AwardsHandler.prototype.removeEmoji = function($emojiButton) {
      var $votesBlock;
      $emojiButton.tooltip('destroy');
      $emojiButton.remove();
      $votesBlock = this.getVotesBlock();
      if ($votesBlock.find('.js-emoji-btn').length === 0) {
        return $votesBlock.addClass('hidden');
      }
    };

    AwardsHandler.prototype.getAwardTooltip = function($awardBlock) {
      return $awardBlock.attr('data-original-title') || $awardBlock.attr('data-title') || '';
    };

    AwardsHandler.prototype.toSentence = function(list) {
      if (list.length <= 2) {
        return list.join(' and ');
      }
      else {
        return list.slice(0, -1).join(', ') + ', and ' + list[list.length - 1];
      }
    };

    AwardsHandler.prototype.removeYouFromUserList = function($emojiButton, emoji) {
      var authors, awardBlock, newAuthors, originalTitle;
      awardBlock = $emojiButton;
      originalTitle = this.getAwardTooltip(awardBlock);
      authors = originalTitle.split(FROM_SENTENCE_REGEX);
      authors.splice(authors.indexOf('You'), 1);
      return awardBlock
        .closest('.js-emoji-btn')
        .removeData('title')
        .removeAttr('data-title')
        .removeAttr('data-original-title')
        .attr('title', this.toSentence(authors))
        .tooltip('fixTitle');
    };

    AwardsHandler.prototype.addYouToUserList = function(votesBlock, emoji) {
      var awardBlock, origTitle, users;
      awardBlock = this.findEmojiIcon(votesBlock, emoji).parent();
      origTitle = this.getAwardTooltip(awardBlock);
      users = [];
      if (origTitle) {
        users = origTitle.trim().split(FROM_SENTENCE_REGEX);
      }
      users.unshift('You');
      return awardBlock
        .attr('title', this.toSentence(users))
        .tooltip('fixTitle');
    };

    AwardsHandler.prototype.createEmoji_ = function(votesBlock, emojiName) {
      var $emojiButton, buttonHtml, emojiData, emojiMarkup;
      emojiData = emojiMap[emojiName];
      emojiMarkup = '<gl-emoji data-name="' + emojiName + '" data-fallback-src="' + emojiData.fallbackImageSrc + '" data-unicode-version="' + emojiData.unicodeVersion + '">' + emojiData.moji + '</gl-emoji>';
      buttonHtml = '<button class="btn award-control js-emoji-btn has-tooltip active" title="You" data-placement="bottom">' + emojiMarkup + ' <span class="award-control-text js-counter">1</span></button>';
      $emojiButton = $(buttonHtml);
      $emojiButton.insertBefore(votesBlock.find('.js-award-holder')).find('.emoji-icon').data('name', emojiName);
      this.animateEmoji($emojiButton);
      $('.award-control').tooltip();
      return votesBlock.removeClass('current');
    };

    AwardsHandler.prototype.animateEmoji = function($emoji) {
      var className = 'pulse animated once short';
      $emoji.addClass(className);

      $emoji.on('webkitAnimationEnd animationEnd', function() {
        $(this).removeClass(className);
      });
    };

    AwardsHandler.prototype.createEmoji = function(votesBlock, emoji) {
      if ($('.emoji-menu').length) {
        return this.createEmoji_(votesBlock, emoji);
      }
      return this.createEmojiMenu((function(_this) {
        return function() {
          return _this.createEmoji_(votesBlock, emoji);
        };
      })(this));
    };

    AwardsHandler.prototype.postEmoji = function(awardUrl, emoji, callback) {
      return $.post(awardUrl, {
        name: emoji
      }, function(data) {
        if (data.ok) {
          return callback();
        }
      });
    };

    AwardsHandler.prototype.findEmojiIcon = function(votesBlock, emoji) {
      return votesBlock.find(".js-emoji-btn [data-name='" + emoji + "']");
    };

    AwardsHandler.prototype.scrollToAwards = function() {
      var options;
      options = {
        scrollTop: $('.awards').offset().top - 110
      };
      return $('body, html').animate(options, 200);
    };

    AwardsHandler.prototype.normalizeEmojiName = function(emoji) {
      return this.aliases[emoji] || emoji;
    };

    AwardsHandler.prototype.addEmojiToFrequentlyUsedList = function(emoji) {
      var frequentlyUsedEmojis;
      frequentlyUsedEmojis = this.getFrequentlyUsedEmojis();
      frequentlyUsedEmojis.push(emoji);
      Cookies.set('frequently_used_emojis', frequentlyUsedEmojis.join(','), { expires: 365 });
    };

    AwardsHandler.prototype.getFrequentlyUsedEmojis = function() {
      var frequentlyUsedEmojis;
      frequentlyUsedEmojis = (Cookies.get('frequently_used_emojis') || '').split(',');
      return _.compact(_.uniq(frequentlyUsedEmojis));
    };

    AwardsHandler.prototype.renderFrequentlyUsedBlock = function() {
      var emoji, frequentlyUsedEmojis, i, len, ul;
      if (Cookies.get('frequently_used_emojis')) {
        frequentlyUsedEmojis = this.getFrequentlyUsedEmojis();
        ul = $("<ul class='clearfix emoji-menu-list frequent-emojis'>");
        for (i = 0, len = frequentlyUsedEmojis.length; i < len; i += 1) {
          emoji = frequentlyUsedEmojis[i];
          $(".emoji-menu-content [data-name='" + emoji + "']").closest('li').clone().appendTo(ul);
        }
        $('.emoji-menu-content').prepend(ul).prepend($('<h5>').text('Frequently used'));
      }
      return this.frequentEmojiBlockRendered = true;
    };

    AwardsHandler.prototype.setupSearch = function() {
      return $('input.emoji-search').on('input', (function(_this) {
        return function(ev) {
          var found_emojis, h5, term, ul;
          term = $(ev.target).val();
          // Clean previous search results
          $('ul.emoji-menu-search, h5.emoji-search').remove();
          if (term) {
            // Generate a search result block
            h5 = $('<h5 class="emoji-search" />').text('Search results');
            found_emojis = _this.searchEmojis(term).show();
            ul = $('<ul>').addClass('emoji-menu-list emoji-menu-search').append(found_emojis);
            $('.emoji-menu-content ul, .emoji-menu-content h5').hide();
            return $('.emoji-menu-content').append(h5).append(ul);
          } else {
            return $('.emoji-menu-content').children().show();
          }
        };
      })(this));
    };

    AwardsHandler.prototype.searchEmojis = function(term) {
      const safeTerm = term.toLowerCase();

      const namesMatchingAlias = [];
      Object.keys(emojiAliases).forEach((alias) => {
        if (alias.indexOf(safeTerm) >= 0) {
          namesMatchingAlias.push(emojiAliases[alias]);
        }
      });
      const $matchingElements = namesMatchingAlias.concat(safeTerm).reduce(($result, searchTerm) => {
        return $result.add($(".emoji-menu-list:not(.frequent-emojis) [data-name*='" + searchTerm + "']"));
      }, $([]));
      return $matchingElements.closest('li').clone();
    };

    return AwardsHandler;
  })();
}).call(window);
