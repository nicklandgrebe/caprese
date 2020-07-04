require 'active_support/concern'
require 'caprese/error'
require 'caprese/serializer/error_serializer'

module Caprese
  module Errors
    extend ActiveSupport::Concern

    included do
      before_action :enable_caprese_style_errors
      rescue_from(StandardError) { |e| handle_exception(e) }
    end


    # Fail with a controller action error
    #
    # @param [Symbol] field the field (a controller param) that caused the error
    # @param [Symbol] code the code for the error
    # @param [Hash] t the interpolation params to be passed into I18n.t
    def error(field: nil, code: :invalid, t: {})
      Error.new(
        controller: unnamespace(params[:controller]),
        action: params[:action],
        field: field,
        code: code,
        t: t
      )
    end

    private

    # Temporarily render model errors as Caprese::Record::Errors instead of ActiveModel::Errors
    def enable_caprese_style_errors
      Current.caprese_style_errors = true
    end

    # Gracefully handles exceptions raised during Caprese controller actions.
    # Override this method in your controller to add your own exception handlers
    def handle_exception(e)
      if e.is_a?(Caprese::Error)
        output = { json: e }
        render output.merge(e.header)
      else
        logger.info e.inspect
        logger.info e.backtrace.join("\n")
        render json: Caprese::Error.new(code: :server_error), status: 500
      end
    end
  end
end
