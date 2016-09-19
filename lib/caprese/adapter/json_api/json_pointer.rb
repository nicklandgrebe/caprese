module Caprese
  module Adapter
    class JsonApi
      module JsonPointer
        module_function

        POINTERS = {
          attribute:    '/data/attributes/%s'.freeze,
          relationship: '/data/relationships/%s'.freeze,
          relationship_attribute: '/data/relationships/%s/attributes/%s'.freeze,
          primary_data: '/data%s'.freeze
        }.freeze

        def new(pointer_type, *values)
          format(POINTERS[pointer_type], *values)
        end
      end
    end
  end
end
