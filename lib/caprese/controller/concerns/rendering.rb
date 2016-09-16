require 'active_support/concern'

module Caprese
  module Rendering
    extend ActiveSupport::Concern

    def render(options = {})
      options[:adapter] = Caprese.config.interface

      if options[:json].respond_to?(:to_ary)
        options[:each_serializer] ||=
          version_module("#{options[:json].first.class.name}Serializer")
          .constantize
      else
        options[:serializer] ||=
          version_module("#{options[:json].class.name}Serializer")
          .constantize
      end

      super
    end
  end
end
