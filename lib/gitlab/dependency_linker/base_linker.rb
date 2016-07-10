module Gitlab
  module DependencyLinker
    class BaseLinker
      def self.link(plain_text, highlighted_text)
        new(plain_text, highlighted_text).link
      end

      attr_accessor :plain_text, :highlighted_text

      def initialize(plain_text, highlighted_text)
        @plain_text = plain_text
        @highlighted_text = highlighted_text
      end

      def link
        link_dependencies

        highlighted_lines.join.html_safe
      end

      private

      def package_url(name)
        raise NotImplementedError
      end

      def link_dependencies
        raise NotImplementedError
      end

      def license_url(name)
        "http://spdx.org/licenses/#{name}.html" if name =~ /[A-Za-z0-9.-]+/
      end

      def package_link(name, url = package_url(name))
        return name unless url

        Nokogiri::HTML::Document.new.create_element(
          'a',
          name,
          href: url
        ).to_html
      end

      # Links package names in a method call or assignment string argument.
      #
      # Example:
      #   link_method_call("gem")
      #   # Will link `package` in `gem "package"`, `gem("package")` and `gem = "package"`
      #
      #   link_method_call("gem", "specific_package")
      #   # Will link `specific_package` in `gem "specific_package"`
      #
      #   link_method_call("github", /[^\/"]+\/[^\/"]+/)
      #   # Will link `user/repo` in `github "user/repo"`, but not `github "package"`
      #
      #   link_method_call(%w[add_dependency add_development_dependency])
      #   # Will link `spec.add_dependency "package"` and `spec.add_development_dependency "package"`
      #
      #   link_method_call("name")
      #   # Will link `package` in `self.name = "package"`
      def link_method_call(method_names, value = nil, &url_proc)
        value =
          case value
          when String
            Regexp.escape(value)
          when nil
            %{[^'"]+}
          else
            value
          end

        method_names = Array(method_names).map { |name| Regexp.escape(name) }
        link_regex(/#{Regexp.union(method_names)}\s*[(=]?\s*['"](?<name>#{value})['"]/, &url_proc)
      end

      # Links package names in a JSON key or values.
      #
      # Example:
      #   link_json("name")
      #   # Will link `package` in `"name": "package"`
      #
      #   link_json("name", "specific_package")
      #   # Will link `specific_package` in `"name": "specific_package"`
      #
      #   link_json("name", /[^\/]+\/[^\/]+/)
      #   # Will link `user/repo` in `"name": "user/repo"`, but not `"name": "package"`
      #
      #   link_json("specific_package", "1.0.1", package: :key)
      #   # Will link `specific_package` in `"specific_package": "1.0.1"`
      def link_json(key, value = nil, package: :value, &url_proc)
        key =
          case key
          when String
            Regexp.escape(key)
          when nil
            '[^"]+'
          else
            key
          end

        value =
          case value
          when String
            Regexp.escape(value)
          when nil
            '[^"]+'
          else
            value
          end

        if package == :value
          value = "(?<name>#{value})"
        else
          key = "(?<name>#{key})"
        end

        link_regex(/"#{key}":\s*"#{value}"/, &url_proc)
      end

      # Links package names based on regex.
      #
      # Example:
      #   link_regex(/(github:|:github =>)\s*['"](?<name>[^'"]+)['"]/)
      #   # Will link `user/repo` in `github: "user/repo"` or `:github => "user/repo"`
      def link_regex(regex, &url_proc)
        highlighted_lines.map!.with_index do |rich_line, i|
          marker = StringRegexMarker.new(plain_lines[i], rich_line.html_safe)

          marked_line = marker.mark(regex, group: :name) do |text, left:, right:|
            url = url_proc ? url_proc.call(text) : package_url(text)
            package_link(text, url)
          end

          marked_line
        end
      end

      def plain_lines
        @plain_lines ||= plain_text.lines
      end

      def highlighted_lines
        @highlighted_lines ||= highlighted_text.lines
      end
    end
  end
end
