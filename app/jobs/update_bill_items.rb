UpdateBillItems = Struct.new(:lala) do
  def perform
    # If it is the first of the month, calculate turnover for the previous month up until midnight last night
    # Otherwise, calculate turnover for the current month
    start_date = (Time.now - 1.day).beginning_of_month
    end_date = Time.now.beginning_of_day

    enterprises = Enterprise.select([:id, :name, :owner_id, :sells, :shop_trial_start_date, :created_at])

    # Cycle through enterprises
    enterprises.each do |enterprise|
      # Cycle through previous versions of this enterprise
      versions = enterprise.versions.where('created_at >= (?)', start_date)
      bill_items = []

      trial_start = enterprise.shop_trial_start_date
      trial_expiry = enterprise.shop_trial_expiry

      versions.each do |version|
        begins_at = bill_items.last.andand.ends_at || [start_date, enterprise.created_at].max
        ends_at = version.created_at

        split_for_trial(version.reify, begins_at, ends_at, trial_start, trial_expiry).each do |bill_item|
          bill_items << bill_item
        end
      end

      # Update / create bill_item for current start
      begins_at = bill_items.last.andand.ends_at || [start_date, enterprise.created_at].max
      ends_at = end_date

      split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry).each do |bill_item|
        bill_items << bill_item
      end
    end
  end

  def split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
    bill_items = []

    trial_start = trial_expiry = begins_at-1.day if trial_start.nil? || trial_expiry.nil?

    # If the trial begins after ends_at, create a bill for the entire period
    # Otherwise, create a normal bill_item from the begins_at until the start of the trial
    if trial_start > begins_at
      bill_items << update_bill_item(enterprise, begins_at, [ends_at, trial_start].min, false)
    end

    # If all or some of the trial occurs between begins_at and ends_at
    # Create a trial bill_item from the from begins_at or trial_start, whichever occurs last, until ends_at, or trial_expiry whichever occurs first
    if trial_expiry >= begins_at && trial_start <= ends_at
      bill_items << update_bill_item(enterprise, [trial_start, begins_at].max, [ends_at, trial_expiry].min, true)
    end

    # If the trial finishes before begins_at, or trial has not been set, create a bill for the entire period
    # Otherwise, create a normal bill_item from the end of the trial until ends_at
    if trial_expiry < ends_at
      bill_items << update_bill_item(enterprise, [trial_expiry, begins_at].max, ends_at, false)
    end

    bill_items
  end

  def update_bill_item(enterprise, begins_at, ends_at, trial)
    owner_id = enterprise.owner_id
    sells = enterprise.sells
    orders = Spree::Order.where('distributor_id = (?) AND completed_at >= (?) AND completed_at < (?)', enterprise.id, begins_at, ends_at)

    bill_item = BillItem.where(begins_at: begins_at, sells: sells, trial: trial, owner_id: owner_id, enterprise_id: enterprise.id).first
    bill_item ||= BillItem.new(begins_at: begins_at, sells: sells, trial: trial, owner_id: owner_id, enterprise_id: enterprise.id)
    bill_item.update_attributes({ends_at: ends_at, turnover: orders.sum(&:total)})

    bill_item
  end
end
