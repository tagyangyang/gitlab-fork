require "spec_helper"

describe Gitlab::Git::EncodingHelper do
  let(:ext_class) { Class.new { extend Gitlab::Git::EncodingHelper } }
  let(:binary_string) { File.join(SEED_STORAGE_PATH, 'gitlab_logo.png') }

  describe '#encode!' do
    [
      [
        'leaves ascii only string as is',
        'ascii only string',
        'ascii only string'
      ],
      [
        'leaves valid utf8 string as is',
        'multibyte string №∑∉',
        'multibyte string №∑∉'
      ],
      [
        'removes invalid bytes from ASCII-8bit encoded multibyte string. This can occur when a git diff match line truncates in the middle of a multibyte character. This occurs after the second word in this example. The test string is as short as we can get while still triggering the error condition when not looking at `detect[:confidence]`.',
        "mu ns\xC3\n Lorem ipsum dolor sit amet, consectetur adipisicing ut\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg kia elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non p\n {: .normal_pn}\n \n-Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\n# *Lorem ipsum\xC3\xB9l\xC3\xB9l\xC3\xA0 dolor\xC3\xB9k\xC3\xB9 sit\xC3\xA8b\xC3\xA8 N\xC3\xA8 amet b\xC3\xA0d\xC3\xAC*\n+# *consectetur\xC3\xB9l\xC3\xB9l\xC3\xA0 adipisicing\xC3\xB9k\xC3\xB9 elit\xC3\xA8b\xC3\xA8 N\xC3\xA8 sed do\xC3\xA0d\xC3\xAC*{: .italic .smcaps}\n \n \xEF\x9B\xA1 eiusmod tempor incididunt, ut\xC3\xAAn\xC3\xB9 labore et dolore. Tw\xC4\x83nj\xC3\xAC magna aliqua. Ut enim ad minim veniam\n {: .normal}\n@@ -9,5 +9,5 @@ quis nostrud\xC3\xAAt\xC3\xB9 exercitiation ullamco laboris m\xC3\xB9s\xC3\xB9k\xC3\xB9abc\xC3\xB9 nisi ".force_encoding('ASCII-8BIT'),
        "mu ns\n Lorem ipsum dolor sit amet, consectetur adipisicing ut\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg kia elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non p\n {: .normal_pn}\n \n-Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\n# *Lorem ipsum\xC3\xB9l\xC3\xB9l\xC3\xA0 dolor\xC3\xB9k\xC3\xB9 sit\xC3\xA8b\xC3\xA8 N\xC3\xA8 amet b\xC3\xA0d\xC3\xAC*\n+# *consectetur\xC3\xB9l\xC3\xB9l\xC3\xA0 adipisicing\xC3\xB9k\xC3\xB9 elit\xC3\xA8b\xC3\xA8 N\xC3\xA8 sed do\xC3\xA0d\xC3\xAC*{: .italic .smcaps}\n \n \xEF\x9B\xA1 eiusmod tempor incididunt, ut\xC3\xAAn\xC3\xB9 labore et dolore. Tw\xC4\x83nj\xC3\xAC magna aliqua. Ut enim ad minim veniam\n {: .normal}\n@@ -9,5 +9,5 @@ quis nostrud\xC3\xAAt\xC3\xB9 exercitiation ullamco laboris m\xC3\xB9s\xC3\xB9k\xC3\xB9abc\xC3\xB9 nisi ",
      ],
    ].each do |description, test_string, xpect|
      it description do
        expect(ext_class.encode!(test_string)).to eq(xpect)
      end
    end

    it 'leaves binary string as is' do
      expect(ext_class.encode!(binary_string)).to eq(binary_string)
    end
  end

  describe '#encode_utf8' do
    [
      [
        "encodes valid utf8 encoded string to utf8",
        "λ, λ, λ".encode("UTF-8"),
        "λ, λ, λ".encode("UTF-8"),
      ],
      [
        "encodes valid ASCII-8BIT encoded string to utf8",
        "ascii only".encode("ASCII-8BIT"),
        "ascii only".encode("UTF-8"),
      ],
      [
        "encodes valid ISO-8859-1 encoded string to utf8",
        "Rüby ist eine Programmiersprache. Wir verlängern den text damit ICU die Sprache erkennen kann.".encode("ISO-8859-1", "UTF-8"),
        "Rüby ist eine Programmiersprache. Wir verlängern den text damit ICU die Sprache erkennen kann.".encode("UTF-8"),
      ],
    ].each do |description, test_string, xpect|
      it description do
        r = ext_class.encode_utf8(test_string.force_encoding('UTF-8'))
        expect(r).to eq(xpect)
        expect(r.encoding.name).to eq('UTF-8')
      end
    end
  end

  describe '#clean' do
    [
      [
        'leaves ascii only string as is',
        'ascii only string',
        'ascii only string'
      ],
      [
        'leaves valid utf8 string as is',
        'multibyte string №∑∉',
        'multibyte string №∑∉'
      ],
      [
        'removes invalid bytes from ASCII-8bit encoded multibyte string.',
        "Lorem ipsum\xC3\n dolor sit amet, xy\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg".force_encoding('ASCII-8BIT'),
        "Lorem ipsum\n dolor sit amet, xyàyùabcdùefg",
      ],
    ].each do |description, test_string, xpect|
      it description do
        expect(ext_class.encode!(test_string)).to eq(xpect)
      end
    end
  end
end
