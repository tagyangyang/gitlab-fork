
const unicodeSupportTestMap = {
  // man, student (emojione does not have any of these yet), http://emojipedia.org/emoji-zwj-sequences/
  // occupationZwj: '\u{1F468}\u{200D}\u{1F393}',
  // woman, biking (emojione does not have any of these yet), http://emojipedia.org/emoji-zwj-sequences/
  // sexZwj: '\u{1F6B4}\u{200D}\u{2640}',
  // US flag, http://emojipedia.org/flags/
  flag: '\u{1F1FA}\u{1F1F8}',
  // dark skin tone, spy, http://emojipedia.org/modifiers/
  skinToneModifier: '\u{1F575}\u{1F3FF}',
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
  // soccer, http://emojipedia.org/unicode-5.2/
  5.2: '\u{26BD}',
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

  const canvas = document.createElement('canvas');
  canvas.width = 2 * fontSize;
  canvas.height = testMapKeys.length * fontSize;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#000000';
  ctx.textBaseline = 'top';
  ctx.font = `${fontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"`;
  // Write each emoji to the canvas vertically
  testMapKeys.forEach((testKey, index) => {
    const emojiUnicode = testMap[testKey];
    ctx.fillText(emojiUnicode, 0, index * fontSize);
  });

  // Read from the canvas
  const resultMap = {};
  testMapKeys.forEach((testKey, index) => {
    // Sample along the vertical-middle for a couple of characters
    const imageData = ctx.getImageData(
        0,
        (fontSize / 2) + (index * fontSize),
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

    resultMap[testKey] = isValidEmoji;
  });

  return resultMap;
}


const isWindows = /\bWindows\b/.test(navigator.userAgent);
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

const unicodeSupportMap = testUnicodeSupportMap(unicodeSupportTestMap);
console.log('unicodeSupportMap', unicodeSupportMap);

function isEmojiUnicodeSupported(emojiUnicode, unicodeVersion) {
  return unicodeSupportMap[unicodeVersion] &&
    // See https://bugs.chromium.org/p/chromium/issues/detail?id=632294
    // Same issue on Windows also fixed in Chrome 57, http://i.imgur.com/rQF7woO.png
    !(isChrome && chromeVersion < 57 && isKeycapEmoji(emojiUnicode)) &&
    !(isWindows && isFlagEmoji(emojiUnicode));
}

/* */
class GlEmojiElement extends HTMLElement {
  // See https://github.com/WebReflection/document-register-element#v1-caveat
  constructor(argSelf) {
    const self = super(argSelf);
    return self;
  }
  connectedCallback() {
    const emojiUnicode = this.textContent.trim();
    const unicodeVersion = this.dataset.unicodeVersion;
    const emojiSrc = this.dataset.fallbackSrc;
    const isEmojiUnicode = this.childNodes.length === 1 && this.childNodes[0].nodeType === 3;
    const hasFallback = emojiSrc && emojiSrc.length > 0;

    if (isEmojiUnicode && hasFallback && !isEmojiUnicodeSupported(emojiUnicode, unicodeVersion)) {
      const emojiName = this.dataset.name;
      this.innerHTML = `<img class="emoji" title=":${emojiName}:" alt=":${emojiName}:" src="${emojiSrc}" width="20" height="20" align="absmiddle" />`;
    }
  }
}

customElements.define('gl-emoji', GlEmojiElement);
/* */
