require 'rails_helper'

describe Gitlab::DependencyLinker::PodspecJsonLinker, lib: true do
  describe '.support?' do
    it 'supports *.podspec.json' do
      expect(described_class.support?('Reachability.podspec.json')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('.podspec.json.example')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "AFNetworking.podspec.json" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        {
          "name": "AFNetworking",
          "version": "2.0.0",
          "license": "MIT",
          "summary": "A delightful iOS and OS X networking framework.",
          "homepage": "https://github.com/AFNetworking/AFNetworking",
          "authors": {
            "Mattt Thompson": "m@mattt.me"
          },
          "source": {
            "git": "https://github.com/AFNetworking/AFNetworking.git",
            "tag": "2.0.0",
            "submodules": true
          },
          "requires_arc": true,
          "platforms": {
            "ios": "6.0",
            "osx": "10.8"
          },
          "public_header_files": "AFNetworking/*.h",
          "subspecs": [
            {
              "name": "NSURLConnection",
              "dependencies": {
                "AFNetworking/Serialization": [

                ],
                "AFNetworking/Reachability": [

                ],
                "AFNetworking/Security": [

                ]
              },
              "source_files": [
                "AFNetworking/AFURLConnectionOperation.{h,m}",
                "AFNetworking/AFHTTPRequestOperation.{h,m}",
                "AFNetworking/AFHTTPRequestOperationManager.{h,m}"
              ]
            }
          ]
        }
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content, nowrap: false) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer" target="_blank">#{name}</a>}
    end

    it "links the gem name" do
      expect(subject).to include(link("AFNetworking", "https://cocoapods.org/pods/AFNetworking"))
    end

    it "links the license" do
      expect(subject).to include(link("MIT", "http://spdx.org/licenses/MIT.html"))
    end

    it "links dependencies" do
      expect(subject).to include(link("AFNetworking/Serialization", "https://cocoapods.org/pods/AFNetworking"))
      expect(subject).to include(link("AFNetworking/Reachability", "https://cocoapods.org/pods/AFNetworking"))
      expect(subject).to include(link("AFNetworking/Security", "https://cocoapods.org/pods/AFNetworking"))
    end

    it "doesn't link subspec names" do
      expect(subject).not_to include(link("NSURLConnection", "https://cocoapods.org/pods/NSURLConnection"))
    end
  end
end
