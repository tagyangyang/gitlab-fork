module API
  class GrapeRelationshipUri
    def self.build(entities, grape_request)
      new(entities, grape_request).build
    end

    def initialize(entities, grape_request)
      @entities = entities
      @base_url = grape_request.base_url
      @request_api_version = grape_request.env
        .fetch(Grape::Env::GRAPE_ROUTING_ARGS)
        .fetch(:version)
    end

    def build
      ::API::API.routes.flat_map do |route|
        if route.options.fetch(:method) == 'GET' &&
          route.pattern.capture.fetch(:version).include?(@request_api_version) &&
          entities_klasses.include?(route.entity)

          @entities.map do |entity_spec|
            # Tries to build the route if entity specification class matches
            # with existing defined Grape route.
            if entity_spec.fetch(:entity) == route.entity
              entity_params = entity_spec.fetch(:params, {}).merge(version: @request_api_version)
              route_name = entity_spec.fetch(:name)

              expand(route.pattern.origin, entity_params, route_name)
            end
          end.compact
        end
      end.compact.inject({}, :merge)
    end

    private

    # Returns a hash with route name and built URL if possible (expansible with
    # given params). Otherwise returns nil.
    def expand(route_string, params, route_name)
      begin
        expanded_route = Mustermann.new(route_string).expand(params)
        uri            = URI(@base_url)
        uri.path       = "/api#{expanded_route}"

        { route_name => uri.to_s }
      rescue Mustermann::ExpandError
        nil
      end
    end

    def entities_klasses
      @entities_klasses ||= @entities.map { |entity| entity.fetch(:entity) }
    end
  end
end
