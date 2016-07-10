require 'rails_helper'

describe Gitlab::DependencyLinker::PodfileLinker, lib: true do
  describe '.support?' do
    it 'supports Podfile' do
      expect(described_class.support?('Podfile')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('Podfile.lock')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "Podfile" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        target 'MyApp'
        pod 'AFNetworking', '~> 1.0'
        pod "RestKit/CoreData"
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content, nowrap: false) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer" target="_blank">#{name}</a>}
    end

    it "links dependencies" do
      expect(subject).to include(link("AFNetworking", "https://cocoapods.org/pods/AFNetworking"))
      expect(subject).to include(link("RestKit/CoreData", "https://cocoapods.org/pods/RestKit"))
    end
  end
end
