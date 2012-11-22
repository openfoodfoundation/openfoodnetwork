class EnterpriseFeePresenter
  def initialize(controller, enterprise_fee)
    @controller = controller
    @enterprise_fee = enterprise_fee
  end

  delegate :id, :enterprise_id, :fee_type, :name, :calculator_type, :to => :enterprise_fee

  def enterprise_fee
    @enterprise_fee
  end


  def enterprise_name
    @enterprise_fee.enterprise.andand.name
  end

  def calculator_description
    @enterprise_fee.calculator.andand.description
  end

  def calculator_settings
    result = nil

    @controller.send(:with_format, :html) do
      result = @controller.render_to_string :partial => 'admin/enterprise_fees/calculator_settings', :locals => {:enterprise_fee => @enterprise_fee}
    end

    result
  end

end
