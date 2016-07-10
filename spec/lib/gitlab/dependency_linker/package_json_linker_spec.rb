require 'rails_helper'

describe Gitlab::DependencyLinker::PackageJsonLinker, lib: true do
  describe '.support?' do
    it 'supports package.json' do
      expect(described_class.support?('package.json')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('package.json.example')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "package.json" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        {
          "name": "module-name",
          "version": "10.3.1",
          "dependencies": {
            "primus": "*",
            "async": "~0.8.0",
            "express": "4.2.x",
            "winston": "git://github.com/flatiron/winston#master",
            "bigpipe": "bigpipe/pagelet",
            "plates": "https://github.com/flatiron/plates/tarball/master"
          },
          "devDependencies": {
            "vows": "^0.7.0",
            "assume": "<1.0.0 || >=2.3.1 <2.4.5 || >=2.5.2 <3.0.0",
            "pre-commit": "*"
          },
          "license": "MIT"
        }
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content, nowrap: false) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer" target="_blank">#{name}</a>}
    end

    it "links the module name" do
      expect(subject).to include(link("module-name", "https://npmjs.com/package/module-name"))
    end

    it "links the license" do
      expect(subject).to include(link("MIT", "http://spdx.org/licenses/MIT.html"))
    end

    it "links dependencies" do
      expect(subject).to include(link("primus", "https://npmjs.com/package/primus"))
      expect(subject).to include(link("async", "https://npmjs.com/package/async"))
      expect(subject).to include(link("express", "https://npmjs.com/package/express"))
      expect(subject).to include(link("winston", "https://npmjs.com/package/winston"))
      expect(subject).to include(link("bigpipe", "https://npmjs.com/package/bigpipe"))
      expect(subject).to include(link("plates", "https://npmjs.com/package/plates"))
      expect(subject).to include(link("vows", "https://npmjs.com/package/vows"))
      expect(subject).to include(link("assume", "https://npmjs.com/package/assume"))
      expect(subject).to include(link("pre-commit", "https://npmjs.com/package/pre-commit"))
    end

    it "links GitHub repos" do
      expect(subject).to include(link("bigpipe/pagelet", "https://github.com/bigpipe/pagelet"))
    end
  end
end
