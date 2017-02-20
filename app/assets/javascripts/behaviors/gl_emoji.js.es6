const installCustomElements = require('document-register-element');
const emojiMap = require('emoji-map');
const generatedUnicodeSupportMap = require('./gl_emoji/unicode_support_map');

installCustomElements(window);

function emojiImageTag(name, src) {
  return `<img class="emoji" title=":${name}:" alt=":${name}:" src="${src}" width="20" height="20" align="absmiddle" />`;
}

const glEmojiTagDefaults = {
  sprite: false,
  forceFallback: false,
};
function glEmojiTag(name, options) {
  const opts = Object.assign({}, glEmojiTagDefaults, options);
  return `
  <gl-emoji
    ${opts.forceFallback && opts.sprite ? `class="emoji-icon ${emojiMap[name].fallbackSpriteClass}"` : ''}
    data-name="${name}"
    data-fallback-src="${emojiMap[name].fallbackImageSrc}"
    ${opts.sprite ? `data-fallback-sprite-class="${emojiMap[name].fallbackSpriteClass}"` : ''}
    data-unicode-version="${emojiMap[name].unicodeVersion}"
  >
    ${opts.forceFallback && !opts.sprite ? emojiImageTag(name, emojiMap[name].fallbackImageSrc) : emojiMap[name].moji}
  </gl-emoji>
  `;
}

// On Windows, flags render as two-letter country codes, see http://emojipedia.org/flags/
const flagACodePoint = 127462; // parseInt('1F1E6', 16)
const flagZCodePoint = 127487; // parseInt('1F1FF', 16)
function isFlagEmoji(emojiUnicode) {
  const cp = emojiUnicode.codePointAt(0);
  // Length 4 because flags are made of 2 characters which are surrogate pairs
  return emojiUnicode.length === 4 && cp >= flagACodePoint && cp <= flagZCodePoint;
}

function isKeycapEmoji(emojiUnicode) {
  return emojiUnicode.length === 3 && emojiUnicode[2] === '\u20E3';
}

const tone1 = 127995;// parseInt('1F3FB', 16)
const tone5 = 127999;// parseInt('1F3FF', 16)
function isSkinToneComboEmoji(emojiUnicode) {
  return emojiUnicode.length > 2 && [...emojiUnicode].some((char) => {
    const cp = char.codePointAt(0);
    return cp >= tone1 && cp <= tone5;
  });
}

const horseRacingCodePoint = 127943;// parseInt('1F3C7', 16)
function isHorceRacingSkinToneComboEmoji(emojiUnicode) {
  return [...emojiUnicode][0].codePointAt(0) === horseRacingCodePoint &&
    isSkinToneComboEmoji(emojiUnicode);
}

const zwj = 8205; // parseInt('200D', 16)
const personStartCodePoint = 128102; // parseInt('1F466', 16)
const personEndCodePoint = 128105; // parseInt('1F469', 16)
function isPersonZwjEmoji(emojiUnicode) {
  let hasPersonEmoji = false;
  let hasZwj = false;
  [...emojiUnicode].forEach((character) => {
    const cp = character.codePointAt(0);
    if (cp === zwj) {
      hasZwj = true;
    } else if (cp >= personStartCodePoint && cp <= personEndCodePoint) {
      hasPersonEmoji = true;
    }
  });

  return hasPersonEmoji && hasZwj;
}

function isEmojiUnicodeSupported(unicodeSupportMap = {}, emojiUnicode, unicodeVersion) {
  const isOlderThanChrome57 = unicodeSupportMap.meta && unicodeSupportMap.meta.isChrome &&
    unicodeSupportMap.meta.chromeVersion < 57;

  return unicodeSupportMap[unicodeVersion] &&
    // See https://bugs.chromium.org/p/chromium/issues/detail?id=632294
    // Same issue on Windows also fixed in Chrome 57, http://i.imgur.com/rQF7woO.png
    !(isOlderThanChrome57 && isKeycapEmoji(emojiUnicode)) &&
    (!isFlagEmoji(emojiUnicode) || (unicodeSupportMap.flag && isFlagEmoji(emojiUnicode))) &&
    (
      (unicodeSupportMap.skinToneModifier && isSkinToneComboEmoji(emojiUnicode)) ||
      !isSkinToneComboEmoji(emojiUnicode)
    ) &&
    (
      (unicodeSupportMap.horseRacing && isHorceRacingSkinToneComboEmoji(emojiUnicode)) ||
      !isHorceRacingSkinToneComboEmoji(emojiUnicode)
    ) &&
    (
      (unicodeSupportMap.personZwj && isPersonZwjEmoji(emojiUnicode)) ||
      !isPersonZwjEmoji(emojiUnicode)
    );
}

const GlEmojiElementProto = Object.create(HTMLElement.prototype);
GlEmojiElementProto.createdCallback = function createdCallback() {
  const emojiUnicode = this.textContent.trim();
  const unicodeVersion = this.dataset.unicodeVersion;
  const fallbackSrc = this.dataset.fallbackSrc;
  const fallbackSpriteClass = this.dataset.fallbackSpriteClass;
  const isEmojiUnicode = this.childNodes && Array.prototype.every.call(
    this.childNodes,
    childNode => childNode.nodeType === 3,
  );
  const hasImageFallback = fallbackSrc && fallbackSrc.length > 0;
  const hasCssSpriteFalback = fallbackSpriteClass && fallbackSpriteClass.length > 0;

  if (
    isEmojiUnicode &&
    !isEmojiUnicodeSupported(generatedUnicodeSupportMap, emojiUnicode, unicodeVersion)
  ) {
    // CSS sprite fallback takes precedence over image fallback
    if (hasCssSpriteFalback) {
      // IE 11 doesn't like adding multiple at once :(
      this.classList.add('emoji-icon');
      this.classList.add(fallbackSpriteClass);
    } else if (hasImageFallback) {
      const emojiName = this.dataset.name;
      this.innerHTML = emojiImageTag(emojiName, fallbackSrc);
    }
  }
};

document.registerElement('gl-emoji', {
  prototype: GlEmojiElementProto,
});

module.exports = {
  emojiImageTag,
  glEmojiTag,
  isEmojiUnicodeSupported,
  isFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
};
