const installCustomElements = require('document-register-element');
const emojiMap = require('emoji-map');

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
    data-name="${name}"
    data-fallback-src="${emojiMap[name].fallbackImageSrc}"
    ${opts.sprite ? `data-fallback-css-class="${emojiMap[name].fallbackSpriteClass}"` : ''}
    data-unicode-version="${emojiMap[name].unicodeVersion}"
  >
    ${opts.forceFallback ? emojiImageTag(name, emojiMap[name].fallbackImageSrc) : emojiMap[name].moji}
  </gl-emoji>
  `;
}

const unicodeSupportTestMap = {
  // man, student (emojione does not have any of these yet), http://emojipedia.org/emoji-zwj-sequences/
  // occupationZwj: '\u{1F468}\u{200D}\u{1F393}',
  // woman, biking (emojione does not have any of these yet), http://emojipedia.org/emoji-zwj-sequences/
  // sexZwj: '\u{1F6B4}\u{200D}\u{2640}',
  // family_mwgb
  // Windows 8.1, Firefox 51.0.1 does not support `family_`, `kiss_`, `couple_`
  personZwj: '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}',
  // horse_racing_tone5
  // Special case that is not supported on macOS 10.12 even though `skinToneModifier` succeeds
  horseRacing: '\u{1F3C7}\u{1F3FF}',
  // US flag, http://emojipedia.org/flags/
  flag: '\u{1F1FA}\u{1F1F8}',
  // http://emojipedia.org/modifiers/
  skinToneModifier: [
    // spy_tone5
    '\u{1F575}\u{1F3FF}',
    // person_with_ball_tone5
    '\u{26F9}\u{1F3FF}',
    // angel_tone5
    '\u{1F47C}\u{1F3FF}',
  ],
  // rofl, http://emojipedia.org/unicode-9.0/
  '9.0': '\u{1F923}',
  // metal, http://emojipedia.org/unicode-8.0/
  '8.0': '\u{1F918}',
  // spy, http://emojipedia.org/unicode-7.0/
  '7.0': '\u{1F575}',
  // expressionless, http://emojipedia.org/unicode-6.1/
  6.1: '\u{1F611}',
  // japanese_goblin, http://emojipedia.org/unicode-6.0/
  '6.0': '\u{1F47A}',
  // sailboat, http://emojipedia.org/unicode-5.2/
  5.2: '\u{26F5}',
  // mahjong, http://emojipedia.org/unicode-5.1/
  5.1: '\u{1F004}',
  // gear, http://emojipedia.org/unicode-4.1/
  4.1: '\u{2699}',
  // zap, http://emojipedia.org/unicode-4.0/
  '4.0': '\u{26A1}',
  // recycle, http://emojipedia.org/unicode-3.2/
  3.2: '\u{267B}',
  // information_source, http://emojipedia.org/unicode-3.0/
  '3.0': '\u{2139}',
  // heart, http://emojipedia.org/unicode-1.1/
  1.1: '\u{2764}',
};

function checkPixelInImageDataArray(pixelOffset, imageDataArray) {
  const indexOffset = 4 * pixelOffset;
  const hasColor = imageDataArray[indexOffset + 0] ||
    imageDataArray[indexOffset + 1] ||
    imageDataArray[indexOffset + 2];
  const isVisible = imageDataArray[indexOffset + 3];
  // Check for some sort of color other than black
  if (hasColor && isVisible) {
    return true;
  }
  return false;
}

const fontSize = 32;
function testUnicodeSupportMap(testMap) {
  const testMapKeys = Object.keys(testMap);
  const numTestEntries = testMapKeys
    .reduce((list, testKey) => list.concat(testMap[testKey]), []).length;

  const canvas = document.createElement('canvas');
  window.testEmojiCanvas = canvas;
  canvas.width = 2 * fontSize;
  canvas.height = numTestEntries * fontSize;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#000000';
  ctx.textBaseline = 'top';
  ctx.font = `${fontSize}px "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"`;
  // Write each emoji to the canvas vertically
  let writeIndex = 0;
  testMapKeys.forEach((testKey) => {
    const testEntry = testMap[testKey];
    [].concat(testEntry).forEach((emojiUnicode) => {
      ctx.fillText(emojiUnicode, 0, writeIndex * fontSize);
      writeIndex += 1;
    });
  });

  // Read from the canvas
  const resultMap = {};
  let readIndex = 0;
  testMapKeys.forEach((testKey) => {
    const testEntry = testMap[testKey];
    const isTestSatisifed = [].concat(testEntry).every(() => {
      // Sample along the vertical-middle for a couple of characters
      const imageData = ctx.getImageData(
          0,
          (fontSize / 2) + (readIndex * fontSize),
          2 * fontSize,
          1,
        ).data;

      let isValidEmoji = false;
      for (let currentPixel = 0; currentPixel < 64; currentPixel += 1) {
        const isLookingAtFirstChar = currentPixel < fontSize;
        const isLookingAtSecondChar = currentPixel >= (fontSize + (fontSize / 2));
        // Check for the emoji somewhere along the row
        if (isLookingAtFirstChar && checkPixelInImageDataArray(currentPixel, imageData)) {
          isValidEmoji = true;

        // Check to see that nothing is rendered next to the first character
        // to ensure that the ZWJ sequence rendered as one piece
        } else if (isLookingAtSecondChar && checkPixelInImageDataArray(currentPixel, imageData)) {
          isValidEmoji = false;
          break;
        }
      }

      readIndex += 1;
      return isValidEmoji;
    });

    resultMap[testKey] = isTestSatisifed;
  });

  return resultMap;
}

const chromeMatches = navigator.userAgent.match(/Chrom(?:e|ium)\/([0-9]+)\./);
const isChrome = chromeMatches && chromeMatches.length > 0;
const chromeVersion = chromeMatches && chromeMatches[1] && parseInt(chromeMatches[1], 10);

// On Windows, flags render as two-letter country codes, see http://emojipedia.org/flags/
const flagACodePoint = 127462; // parseInt('1F1E6', 16)
const flagZCodePoint = 127487; // parseInt('1F1FF', 16)
function isFlagEmoji(emojiUnicode) {
  const cp = emojiUnicode.codePointAt(0);
  return cp >= flagACodePoint && cp <= flagZCodePoint;
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

let unicodeSupportMap;
const userAgentFromCache = window.localStorage.getItem('gl-emoji-user-agent');
try {
  unicodeSupportMap = JSON.parse(window.localStorage.getItem('gl-emoji-unicode-support-map'));
} catch (err) {
  // swallow
}
if (!unicodeSupportMap || userAgentFromCache !== navigator.userAgent) {
  unicodeSupportMap = testUnicodeSupportMap(unicodeSupportTestMap);
  window.localStorage.setItem('gl-emoji-user-agent', navigator.userAgent);
  window.localStorage.setItem('gl-emoji-unicode-support-map', JSON.stringify(unicodeSupportMap));
}

function isEmojiUnicodeSupported(emojiUnicode, unicodeVersion) {
  return unicodeSupportMap[unicodeVersion] &&
    // See https://bugs.chromium.org/p/chromium/issues/detail?id=632294
    // Same issue on Windows also fixed in Chrome 57, http://i.imgur.com/rQF7woO.png
    !(isChrome && chromeVersion < 57 && isKeycapEmoji(emojiUnicode)) &&
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
  const fallbackCssClass = this.dataset.fallbackCssClass;
  const isEmojiUnicode = this.childNodes && Array.prototype.every.call(
    this.childNodes,
    childNode => childNode.nodeType === 3,
  );
  const hasImageFallback = fallbackSrc && fallbackSrc.length > 0;
  const hasCssSpriteFalback = fallbackCssClass && fallbackCssClass.length > 0;

  if (isEmojiUnicode && !isEmojiUnicodeSupported(emojiUnicode, unicodeVersion)) {
    // CSS sprite fallback takes precedence over image fallback
    if (hasCssSpriteFalback) {
      // IE 11 doesn't like adding multiple at once :(
      this.classList.add('emoji-icon');
      this.classList.add(fallbackCssClass);
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
};
