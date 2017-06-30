module Admin
  module FloatStringHelper
    def float_string_field(attribute, options={})
      render partial: 'admin/shared/float_string_input', locals: { attribute: attribute.to_s }.merge(options)
    end
  end
end
