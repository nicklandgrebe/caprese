require 'active_support/concern'
require 'caprese/adapter/json_api'

module Caprese
  module Rendering
    extend ActiveSupport::Concern

    # Override render so we can automatically use our adapter and find the appropriate serializer
    # instead of requiring that they be explicity stated
    def render(options = {})
      options[:adapter] = Caprese::Adapter::JsonApi

      if options[:json].respond_to?(:to_ary)
        if options[:json].first.is_a?(Error)
          options[:each_serializer] ||= Serializer::ErrorSerializer
        elsif options[:json].any?
          options[:each_serializer] ||= serializer_for(options[:json].first)
        end
      else
        if options[:json].is_a?(Error)
          options[:serializer] ||= Serializer::ErrorSerializer
        elsif options[:json].present?
          options[:serializer] ||= serializer_for(options[:json])
        end
      end

      super
    end

    private

    # Finds a versioned serializer for a given resource
    #
    # @example
    #   serializer_for(post) => API::V1::PostSerializer
    #
    # @param [ActiveRecord::Base] record the record to find a serializer for
    # @return [Serializer,Nil] the serializer for the given record
    def serializer_for(record)
      version_module("#{record.class.name}Serializer").constantize
    end
  end
end
