require 'active_support/concern'
require 'caprese/error'

module Caprese
  module Errors
    extend ActiveSupport::Concern

    included do
      around_action :enable_caprese_style_errors

      rescue_from Error do |e|
        render { json: e.serialize }.merge(e.header)
      end
    end

    # Fail with a controller action error
    #
    # @param [Symbol] field the field (a controller param) that caused the error
    # @param [Symbol] code the code for the error
    # @param [Hash] t the interpolation params to be passed into I18n.t
    def error(field: nil, code: :invalid, t: {})
      fail Error.new(
        controller: unversion(params[:controller]),
        action: params[:action],
        field: field,
        code: code,
        t: t
      )
    end

    private

    # Temporarily render model errors as Caprese::Record::Errors instead of ActiveModel::Errors
    def enable_caprese_style_errors
      Caprese::Record.caprese_style_errors = true
      yield
      Caprese::Record.caprese_style_errors = false
    end
  end
end
