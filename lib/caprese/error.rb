# TODO: Remove in favor of Rails 5 error details and dynamically setting i18n_scope
module Caprese
  class Error < StandardError
    attr_reader :field, :code, :header, :t

    # Initializes a new error
    #
    # @param [Symbol] model a symbol representing the model that the error occurred on
    # @param [String] controller the name of the controller the error occurred in
    # @param [String] action the name of the controller action the error occurred in
    # @param [Symbol,String] field a symbol or string representing the field (model attribute or controller param) that the error occurred on
    #   if Symbol, a shallow field name. EX: :password
    #   if String, a nested field name.  EX: 'order_items.amount'
    # @param [Symbol] code the error code
    # @param [Hash] t the interpolation variables to supply to I18n.t when creating the full error message
    def initialize(model: nil, controller: nil, action: nil, field: nil, code: :invalid, t: {})
      @model = model

      @controller = controller
      @action = action

      @field = field
      @code = code

      # field is nil if :base
      field_name = field || model
      @t = { field: field_name.to_s, field_title: field_name.to_s.titleize }.merge t

      @header = { status: :bad_request }
    end

    # @return [String] The scope to look for I18n translations in
    def i18n_scope
      Caprese.config.i18n_scope
    end

    # The full error message based on the different attributes we initialized the error with
    #
    # @return [String] the full error message
    def full_message
      if @model
        if field
          if i18n_set? "#{i18n_scope}.models.#{@model}.#{field}.#{code}", t
            I18n.t("#{i18n_scope}.models.#{@model}.#{field}.#{code}", t)
          elsif i18n_set?("#{i18n_scope}.field.#{code}", t)
            I18n.t("#{i18n_scope}.field.#{code}", t)
          elsif i18n_set? "#{i18n_scope}.#{code}", t
            I18n.t("#{i18n_scope}.#{code}", t)
          else
            code.to_s
          end
        else
          if i18n_set? "#{i18n_scope}.models.#{@model}.#{code}", t
            I18n.t("#{i18n_scope}.models.#{@model}.#{code}", t)
          elsif i18n_set? "#{i18n_scope}.#{code}", t
            I18n.t("#{i18n_scope}.#{code}", t)
          else
            code.to_s
          end
        end
      elsif @controller && @action
        if field && i18n_set?("#{i18n_scope}.controllers.#{@controller}.#{@action}.#{field}.#{code}", t)
          I18n.t("#{i18n_scope}.controllers.#{@controller}.#{@action}.#{field}.#{code}", t)
        elsif i18n_set?("#{i18n_scope}.controllers.#{@controller}.#{@action}.#{code}", t)
          I18n.t("#{i18n_scope}.controllers.#{@controller}.#{@action}.#{code}", t)
        elsif i18n_set? "#{i18n_scope}.#{code}", t
          I18n.t("#{i18n_scope}.#{code}", t)
        else
          code.to_s
        end
      elsif field && i18n_set?("#{i18n_scope}.field.#{code}", t)
        I18n.t("#{i18n_scope}.field.#{code}", t)
      elsif i18n_set? "#{i18n_scope}.#{code}", t
        I18n.t("#{i18n_scope}.#{code}", t)
      else
        code.to_s
      end
    end
    alias_method :message, :full_message

    # Allows us to add to the response header when we are failing
    #
    # @note Should be used as such: fail Error.new(...).with_headers(...)
    #
    # @param [Hash] headers the headers to supply in the error response
    # @option [Symbol] status the HTTP status code to return
    # @option [String, Path] location the value for the Location header, useful for redirects
    def with_header(header = {})
      @header = header
      @header[:status] ||= :bad_request
      self
    end

    # Creates a serializable hash for the error so we can serialize and return it
    #
    # @return [Hash] the serializable hash of the error
    def as_json
      {
        code: code,
        field: field,
        message: full_message
      }
    end

    private

    # Checks whether or not a translation exists
    #
    # @param [String] key the I18n translation key
    # @param [Hash]   params any params to pass into the translations so we only raise NotFound
    #   exception we're looking for missing params would cause this to return false improperly
    # @return [Boolean] whether or not the translation exists in I18n
    def i18n_set?(key, params = {})
      I18n.t key, params, :raise => true rescue false
    end
  end
end
