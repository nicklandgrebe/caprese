module Caprese
  module Record
    # Formats nested errors on associations in a more useful way than Rails alone
    #
    # @note BEFORE
    # POST /posts (with invalid resources) =>
    #   [
    #     { "key"=>"invalid", "field"=>"attachment", "message"=>"Attachment is invalid." }
    #   ]
    #
    # @note AFTER
    # POST /posts (with invalid resources) =>
    #   [
    #     { "key"=>"not_found", "field"=>"attachment.file", "message"=>"Could not find a file at ..."}
    #   ]
    class AssociatedValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        Array(value).reject { |r| r.marked_for_destruction? || r.valid? }.each do |invalid_record|
          invalid_record.errors.to_a.each do |error|
            field_name = error.field ? "#{attribute}.#{error.field}" : attribute
            record.errors.add(field_name, error.code, options.merge(value: invalid_record))
          end
        end
      end
    end

    module ClassMethods
      def validates_associated(*attr_names)
        validates_with AssociatedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
