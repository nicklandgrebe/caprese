require 'caprese/error'

module Caprese
  # Thrown when a record was attempted to be persisted and was invalidated
  #
  # @param [ActiveRecord::Base] record the record that is invalid
  class RecordInvalidError < Error
    attr_reader :record, :aliases

    def initialize(record, engaged_field_aliases)
      super()
      @record = record
      @aliases = engaged_field_aliases
      @header = { status: :unprocessable_entity }
    end

    def as_json
      record.errors.as_json
    end
  end

  # Thrown when a record could not be found
  #
  # @param [Symbol] field the field that we searched with
  # @param [String] model the name of the model we searched for a record of
  # @param [Value] value the value we searched for a match with
  class RecordNotFoundError < Error
    def initialize(model: nil, value: nil)
      super field: :id, code: :not_found, t: { model: model, value: value }
      @header = { status: :not_found }
    end

    def full_message
      I18n.t("#{i18n_scope}.parameters.not_found", t)
    end
  end

  # Thrown when an association was not found when calling `record.association()`
  #
  # @param [String] name the name of the association
  class AssociationNotFoundError < Error
    def initialize(name)
      super field: :name, code: :not_found, t: { model: 'relationship', value: name }
      @header = { status: :not_found }
    end

    def full_message
      I18n.t("#{i18n_scope}.parameters.not_found", t)
    end
  end

  # Thrown when an action that is forbidden was attempted
  class ActionForbiddenError < Error
    def initialize
      super code: :forbidden
      @header = { status: :forbidden }
    end
  end

  # Thrown when an attempt was made to delete a record, but the record could not be deleted
  # because of restrictions
  #
  # @param [String] reason the reason for the restriction
  class DeleteRestrictedError < Error
    def initialize(reason)
      super code: :delete_restricted, t: { reason: reason }
      @header = { status: :forbidden }
    end
  end
end
