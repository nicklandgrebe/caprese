require 'active_support/concern'

module Caprese
  module UrlHelpers
    extend ActiveSupport::Concern

    # Returns the proper route URL helpers based on whether or not Caprese is being used in an engine's
    # isolated_namespace or just a regular application
    def url_helpers
      mod =
        if namespace = Caprese.config.isolated_namespace
          namespace::Engine
        else
          Rails.application
        end

      mod.routes.url_helpers
    end
  end
end
