require 'action_dispatch/routing/mapper'

class ActionDispatch::Routing::Mapper
  def caprese_resources(*resources, &block)
    options = resources.extract_options!

    options[:only] ||= %i[index show create update destroy]

    resources.each do |r|
      resources r, options do
        yield if block_given?

        member do
          get 'relationships/:relationship',
            to: "#{parent_resource.name}#get_relationship_definition",
            as: :relationship_definition

          match 'relationships/:relationship',
            to: "#{parent_resource.name}#update_relationship_definition",
            via: [:patch, :post, :delete]

          get ':relationship(/:relation_primary_key_value)',
            to: "#{parent_resource.name}#get_relationship_data",
            as: :relationship_data
        end
      end
    end
  end
end
