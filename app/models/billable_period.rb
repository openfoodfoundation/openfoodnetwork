class BillablePeriod < ActiveRecord::Base
  belongs_to :enterprise
  belongs_to :owner, class_name: 'Spree::User', foreign_key: :owner_id

  def bill
    # Will make this more sophisicated in the future in that it will use global config variables to calculate
    return 0 if trial?
    if ['own', 'any'].include? sells
      bill = (turnover * 0.02)
      bill > 50 ? 50 : bill
    else
      0
    end
  end
end
