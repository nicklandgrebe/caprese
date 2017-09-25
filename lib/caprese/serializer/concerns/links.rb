require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    module Links
      extend ActiveSupport::Concern

      included do
        # Add a links[:self] to this resource
        #
        # @example
        #   object = Order<@token='asd27h'>
        #   links = { self: '/api/v1/orders/asd27hß' }
        link :self do
          if(url = serializer.class.route_for(object))
            serializer.url_helpers.send(
              url,
              object.read_attribute(Caprese.config.resource_primary_key),
              host: serializer.class.send(:caprese_default_url_options_host)
            )
          end
        end
      end

      module ClassMethods
        # Fetches the host from Caprese.config.default_url_options or fails if it is not set
        # @note default_url_options[:host] is used to render the host in links that are serialized in the response
        def caprese_default_url_options_host
          Caprese.config.default_url_options.fetch(:host) do
            fail 'Caprese requires that config.default_url_options[:host] be set when rendering links.'
          end
        end
      end
    end
  end
end
