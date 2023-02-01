# frozen_string_literal: true

class EnterpriseFeesReflex < ApplicationReflex
  def delete
    return unless can? :destroy, enterprise_fee

    if enterprise_fee.destroy
      flash[:success] = I18n.t(:successfully_removed, resource: enterprise_fee.name)
    else
      flash[:error] = enterprise_fee.errors.full_messages.first
    end
  end

  def calculator_changed
    id = element.dataset["enterprise_fee_id"]
    calculator = if enterprise_fee && element.value == enterprise_fee.calculator_type
                   enterprise_fee.calculator
                 else
                   EnterpriseFee.calculators.find { |c| c.name == element.value }.new
                 end

    morph "#calculator-settings-#{id}",
          with_locale {
            render(partial: "admin/enterprise_fees/calculator_form",
                   locals: { calculator: calculator, I18n: I18n })
          }
  end

  # private
  def enterprise_fee
    @enterprise_fee ||= EnterpriseFee.find_by id: element.dataset["enterprise_fee_id"]
  end
end
