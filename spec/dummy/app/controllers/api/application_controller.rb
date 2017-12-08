module API
  # Root level API controller that establishes configuration and endpoints that are not versioned
  class ApplicationController < Caprese::Controller
    before_action do
      Caprese.config.default_url_options = { host: request.host_with_port }
    end
  end
end
