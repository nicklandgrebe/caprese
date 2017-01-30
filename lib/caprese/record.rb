require 'active_model'
require 'active_support/concern'
require 'active_support/dependencies'
require 'caprese/errors'
require 'caprese/record/associated_validator'
require 'caprese/record/errors'

module Caprese
  module Record
    extend ActiveSupport::Concern

    mattr_accessor :caprese_style_errors
    @@caprese_style_errors = true

    # @return [Errors] a cached instance of the model errors class
    def errors
      @errors ||= (Caprese::Record.caprese_style_errors ? Caprese::Record : ActiveModel)::Errors.new(self)
    end
  end
end
