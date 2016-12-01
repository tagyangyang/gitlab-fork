class GitlabSpecListener
  def start(_notification)
    path = File.expand_path('../../tmp/', __dir__)

    @passed = File.open(File.join(path, "passed-#{Time.now.to_i}.txt"), 'w')
    @failed = File.open(File.join(path, "failed-#{Time.now.to_i}.txt"), 'w')
  end

  def stop(_notification)
    @passed.close
    @failed.close
  end

  def example_passed(notification)
    @passed.puts formatted_example(notification.example)
  end

  def example_failed(notification)
    @failed.puts formatted_example(notification.example)
  end

  private

  def formatted_example(example)
    command     = File.basename($0)
    rerun       = example.location_rerun_argument
    description = example.full_description

    "#{command} #{rerun} # #{description}"
  end
end

RSpec.configure do |config|
  config.reporter.register_listener(
    GitlabSpecListener.new,
    :start,
    :example_passed,
    :example_failed,
    :stop
  )
end
