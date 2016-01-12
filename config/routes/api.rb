API::API.logger Rails.logger
mount API::API => '/api'
mount GrapeSwaggerRails::Engine => '/apidoc'
