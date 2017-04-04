module Gitlab
  module Ci
    class Trace
      attr_reader :job

      delegate :old_trace, to: :job

      def initialize(job)
        @job = job
      end

      def has_trace?
        current_trace_path.present? || old_trace.present?
      end

      def html(max_lines: nil)
        read do |stream|
          stream.html(max_lines: max_lines)
        end
      end

      def raw(max_lines: nil)
        read do |stream|
          stream.raw(max_lines: max_lines)
        end
      end

      def extract_coverage(regex)
        read do |stream|
          stream.extract_coverage(regex)
        end
      end

      def set(data)
        write do |stream|
          stream.set(data)
        end
      end

      def erase_trace!
        trace_paths.find do |trace_path|
          File.rm(trace_path, force: true)
        end

        job.erase_old_trace!
      end

      def read
        stream = Gitlab::Ci::Trace::Stream.new do
          if current_trace_path
            File.open(current_trace_path, "rb")
          elsif old_trace
            StringIO.new(old_trace)
          end
        end

        yield stream
      ensure
        stream&.close
      end

      def write
        stream = Gitlab::Ci::Trace::Stream.new do
          File.open(ensure_trace_path, "a+b")
        end

        yield stream
      ensure
        stream&.close
      end

      private

      def ensure_trace_path
        return current_trace_path if current_trace_path

        ensure_trace_directory
        default_trace_path
      end

      def ensure_trace_directory
        unless Dir.exist?(default_trace_directory)
          FileUtils.mkdir_p(default_trace_directory)
        end
      end

      def current_trace_path
        @current_trace_path ||= trace_paths.find do |trace_path|
          File.exist?(trace_path)
        end
      end

      def trace_paths
        [
          default_trace_path,
          deprecated_trace_path
        ].compact
      end

      def default_trace_directory
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project_id.to_s
        )
      end

      def default_trace_path
        File.join(default_trace_directory, "#{job.id}.log")
      end

      def deprecated_trace_path
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project.ci_id.to_s,
          "#{job.id}.log"
        ) if job.project&.ci_id
      end
    end
  end
end
