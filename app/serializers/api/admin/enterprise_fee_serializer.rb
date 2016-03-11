class Api::Admin::EnterpriseFeeSerializer < ActiveModel::Serializer
  attributes :id, :enterprise_id, :fee_type, :name, :tax_category_id, :inherits_tax_category, :calculator_type
  attributes :enterprise_name, :calculator_description, :calculator_settings

  def enterprise_name
    object.enterprise.andand.name
  end

  def calculator_description
    object.calculator.andand.description
  end

  def calculator_settings
    return nil unless options[:include_calculators]

    result = nil

    options[:controller].send(:with_format, :html) do
      result = options[:controller].render_to_string :partial => 'admin/enterprise_fees/calculator_settings', :locals => {:enterprise_fee => object}
    end

    result.gsub('[0]', '[{{ $index }}]').gsub('_0_', '_{{ $index }}_')
  end

end
