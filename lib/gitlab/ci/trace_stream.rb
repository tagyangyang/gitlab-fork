module Gitlab
  module Ci
    # This was inspired from: http://stackoverflow.com/a/10219411/1520132
    class TraceStream
      BUFFER_SIZE = 4096
      LIMIT_SIZE = 60

      attr_reader :stream

      delegate :read, :close, :tell, :seek, :size, :path, :truncate, to: :stream, allow_nil: true

      def initialize
        @stream = yield
      end

      def use
        yield self
      ensure
        close if valid?
      end

      def valid?
        self.stream&.ready?
      end

      def file?
        self.path.present?
      end

      def limit(max_bytes = LIMIT_SIZE)
        stream_size = size
        if stream_size < max_bytes
          max_bytes = stream_size
        end
        stream.seek(-max_bytes, IO::SEEK_END)
      end

      def append(data, offset)
        stream.truncate(offset)
        stream.seek(0, IO::SEEK_END)
        stream.write(data)
        stream.flush()
      end

      def set(data)
        truncate(0)
        stream.write(data)
        stream.flush()
      end

      def read_last_lines(max_lines)
        chunks = []
        pos = lines = 0
        max = file.size

        # We want an extra line to make sure fist line has full contents
        while lines <= max_lines && pos < max
          pos += BUFFER_SIZE

          buf =
            if pos <= max
              stream.seek(-pos, IO::SEEK_END)
              stream.read(BUFFER_SIZE)
            else # Reached the head, read only left
              stream.seek(0)
              stream.read(BUFFER_SIZE - (pos - max))
            end

          lines += buf.count("\n")
          chunks.unshift(buf)
        end

        chunks.join.lines.last(max_lines).join
          .force_encoding(Encoding.default_external)
      end

      def html_with_state(state = nil)
        ::Ci::Ansi2html.convert(stream, state)
      end

      def html_last_lines(max_lines)
        text = read_last_lines(max_lines)
        stream = StringIO.new(text)
        ::Ci::Ansi2html.convert(stream).html
      end

      def coverage(regex)
        return unless valid?
        return unless regex

        regex = Regexp.new(regex)

        match = ""

        stream.each_line do |line|
          matches = line.scan(regex).last
          match = matches.last if matches.is_a?(Array)
        end

        coverage = match.gsub(/\d+(\.\d+)?/).first

        if coverage.present?
          coverage.to_f
        end
      rescue
        # if bad regex or something goes wrong we dont want to interrupt transition
        # so we just silentrly ignore error for now
      end
    end
  end
end
