require 'responders'

module API
  # Root level API controller that establishes configuration and endpoints that are not versioned
  class ApplicationController < Caprese::Controller
    respond_to :json

    # Return a null session if CSRF secret token is not provided
    # Instead, authenticate individual requests
    protect_from_forgery with: :null_session
    skip_before_filter :verify_authenticity_token
  end
end
