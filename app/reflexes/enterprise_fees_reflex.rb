# frozen_string_literal: true

class EnterpriseFeesReflex < ApplicationReflex
  def delete
    enterprise_fee = EnterpriseFee.find_by id: element.dataset["enterprise_fee_id"]
    return unless can? :destroy, enterprise_fee

    if enterprise_fee.destroy
      flash[:success] = I18n.t(:successfully_removed, resource: enterprise_fee.name)
    else
      flash[:error] = enterprise_fee.errors.full_messages.first
    end
  end
end
