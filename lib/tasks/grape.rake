namespace :grape do
  desc 'Print compiled grape routes'
  task routes: :environment do
    API::API.routes.each do |route|
      puts "#{Rainbow(route.options[:method]).green} #{route.path} - #{Rainbow(route.entity).green} - #{route_description(route.options)}"
    end
  end

  def route_description(options)
    options[:settings][:description][:description] if options[:settings][:description]
  end
end
