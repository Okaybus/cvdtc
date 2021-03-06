require 'grape-swagger'

module API
  module ErrorFormatter
    def self.call(message, _backtrace, _options, _env)
      { response_type: 'error', response: message }.to_json
    end
  end

  class Root < Grape::API
    prefix 'api'
    format :json

    logger.formatter = GrapeLogging::Formatters::Default.new
    use GrapeLogging::Middleware::RequestLogger, logger: logger

    rescue_from :all unless Rails.env.development?
    error_formatter :json, API::ErrorFormatter

    before do
      error!('401 Unauthorized', 401) unless authenticated
    end

    helpers do
      def warden
        env['warden']
      end

      def authenticated
        if warden.authenticated? || route.route_path.start_with?('/api/swagger_doc', '/api/:version/authentication/login', '/api/:version/authentication/password')
          return true
        end
        @user = User.find_by(authentication_token: request.headers['X-Auth-Token']) if request.headers['X-Auth-Token']
      end

      def current_user
        warden.user || @user
      end
    end

    mount API::V1::Root
  end
end
