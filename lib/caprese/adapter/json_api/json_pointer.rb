module Caprese
  module Adapter
    class JsonApi
      module JsonPointer
        module_function

        POINTERS = {
          attribute:    '/data/attributes/%s'.freeze,
          relationship_attribute: '/data/relationships/%s'.freeze,
          relationship_base: '/data/relationships/%s/data'.freeze,
          relationship_primary_data: '/data/relationships/%s/data/%s'.freeze,
          primary_data: '/data/%s'.freeze
        }.freeze

        # Iterates over the field of an error and converts it to a pointer in JSON API format
        #
        # @example
        #   new(:attribute, record, 'name')
        #   => '/data/attributes/name'
        #
        # @example
        #   new(:relationship, record, 'post')
        #   => '/data/attributes/name'
        #
        # @example
        #   new(:relationship_attribute, record, 'post.user.name')
        #   => '/data/relationships/post/data/relationships/user/data/attributes/name'
        #
        # @param [Symbol] pointer_type the type of pointer: :attribute, :relationship, :primary_data
        # @param [Record] the record that owns the errors
        # @param [Object,Array<Object>]
        def new(pointer_type, record, value)
          if pointer_type == :relationship_attribute
            value.to_s.split('.').inject('') do |pointer, v|
              pointer +
                if record.class.reflections.key?(v)
                  record =
                    if record.class.reflections[v].collection?
                      record.send(v).first
                    else
                      record.send(v)
                    end

                  format(POINTERS[:relationship_attribute], v)
                else
                  format(POINTERS[:attribute], v)
                end
            end
          else
            format(POINTERS[pointer_type], *[value].flatten)
          end
        end
      end
    end
  end
end
