require 'active_support/concern'
require 'caprese/adapter/json_api'

module Caprese
  module Rendering
    extend ActiveSupport::Concern

    def render(options = {})
      options[:adapter] = Caprese::Adapter::JsonApi

      if options[:json].respond_to?(:to_ary)
        if options[:json].first.is_a?(Error)
          options[:each_serializer] ||= Serializer::ErrorSerializer
        end

        options[:each_serializer] ||=
          version_module("#{options[:json].first.class.name}Serializer")
          .constantize
      else
        if options[:json].is_a?(Error)
          options[:serializer] ||= Serializer::ErrorSerializer
        end

        options[:serializer] ||=
          version_module("#{options[:json].class.name}Serializer")
          .constantize
      end

      super
    end
  end
end
