require 'active_support/concern'

# Defines callbacks like `before_create`, `after_create` to be called in abstracted persistence methods
# like `create`, so there is no need to override `create`, which won't work properly because of the `render`
# call in it
module Caprese
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :before_query, :after_query,
      :after_initialize,
      :before_create, :after_create,
      :before_update_assign, :before_update, :after_update,
      :before_save, :after_save,
      :before_destroy, :after_destroy
    ]

    included do
      CALLBACKS.each do |method_name|
        instance_variable_name = "@#{method_name}_callbacks"

        # Defines instance method like `execute_before_create_callbacks` to be called with the resource
        # being created passed in as an argument, to perform actions before saving the resource using
        # callbacks defined at the class level
        # @see below `define_single_method method_name`
        #
        # @note In the instance of `before_create`, the resource to be created will be passed in to callbacks,
        #   but in cases like `before_query`, nothing will be passed in, or `after_query`, the result of the
        #   query will be passed in
        #
        # @param [ActiveRecord::Base] resource the resource to perform actions on/with
        define_method "execute_#{method_name}_callbacks" do |arg = nil|
          self.class.instance_variable_get(instance_variable_name).try(:each) do |callback|
            if self.class.instance_method(callback).arity > 0
              send(callback, arg)
            else
              send(callback)
            end
          end
        end

        # Defines class method like `before_create` that takes in symbols that specify
        # callbacks to call at a certain even like before creating a resource
        #
        # @example
        #   before_create :do_something, :do_another_thing
        #   after_create :do_more_things, :do_other_things
        #
        # @param [Symbol,Array<Symbol>] callbacks the name(s) of callbacks to add to list of callbacks
        define_singleton_method method_name do |*callbacks|
          all_callbacks = self.instance_variable_get(instance_variable_name) || []
          all_callbacks.push *callbacks
          self.instance_variable_set(instance_variable_name, all_callbacks)
        end
      end
    end

    module ClassMethods
      # Is called when any controller class inherits from a parent controller, copying to the child controller
      # all of the callbacks that have been stored in instance variables on the parent
      #
      # @param [Class] subclass the child class that is to inherit the callbacks
      def inherited(subclass)
        CALLBACKS.each do |method_name|
          instance_variable_name = "@#{method_name}_callbacks"
          subclass.instance_variable_set(instance_variable_name, instance_variable_get(instance_variable_name))
        end
      end
    end
  end
end
