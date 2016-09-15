require 'active_support/concern'

module Caprese
  module Rendering
    extend ActiveSupport::Concern

    def render(options = {})
      options[:adapter] = Caprese.config.interface

      super
    end
  end
end
