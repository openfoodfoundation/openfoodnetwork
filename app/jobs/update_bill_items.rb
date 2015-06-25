UpdateBillItems = Struct.new(:lala) do
  def perform
    # If it is the first of the month, calculate turnover for the previous month up until midnight last night
    # Otherwise, calculate turnover for the current month
    start_date = (Time.now - 1.day).beginning_of_month
    end_date = Time.now.beginning_of_day

    enterprises = Enterprise.select([:id, :name, :owner_id, :sells, :shop_trial_start_date])

    # Cycle through users
    enterprises.each do |enterprise|
      # Cycle through owned_enterprises
      versions = enterprise.versions.where('created_at >= (?)', start_date)
      bill_items = []

      versions.each do |version|
        begins_at = bill_items.last.andand.ends_at || start_date
        ends_at = version.created_at
        bill_items << update_bill_item(version.reify, begins_at, ends_at)
      end

      # Update / create bill_item for current start
      begins_at = bill_items.last.andand.ends_at || start_date
      ends_at = end_date
      update_bill_item(enterprise, begins_at, ends_at)
    end
  end

  def update_bill_item(enterprise, begins_at, ends_at)
    trial_start = enterprise.shop_trial_start_date || begins_at
    trial_expiry = enterprise.shop_trial_expiry || begins_at
    owner_id = enterprise.owner_id
    sells = enterprise.sells
    orders = Spree::Order.where('distributor_id = (?) AND completed_at >= (?) AND completed_at < (?)', enterprise.id, begins_at, ends_at)

    if trial_start > begins_at
      before_trial_orders = orders.where('completed_at < (?)', trial_start)
      bill_item = BillItem.where(begins_at: begins_at, sells: sells, trial: false, owner_id: owner_id, enterprise_id: enterprise.id).first
      bill_item ||= BillItem.new(begins_at: begins_at, sells: sells, trial: false, owner_id: owner_id, enterprise_id: enterprise.id)
      bill_item.update_attributes({ends_at: [ends_at, trial_start].min, turnover: before_trial_orders.sum(&:total)})
    end

    if trial_expiry > begins_at && trial_start <= ends_at
      trial_orders = orders.where('completed_at >= (?) AND completed_at < (?)', trial_start, trial_expiry)
      bill_item = BillItem.where(begins_at: [trial_start, begins_at].max, sells: sells, trial: true, owner_id: owner_id, enterprise_id: enterprise.id).first
      if bill_item && bill_item.begins_at != [trial_start, begins_at].max
        # TODO: #Bugsnag
      end
      bill_item ||= BillItem.new(begins_at: [trial_start, begins_at].max, sells: sells, trial: true, owner_id: owner_id, enterprise_id: enterprise.id)
      bill_item.update_attributes({ends_at: [ends_at, trial_expiry].min, turnover: trial_orders.sum(&:total)})
    end

    if trial_expiry <= ends_at
      after_trial_orders = orders.where('completed_at >= (?)', trial_expiry)
      bill_item = BillItem.where(begins_at: [trial_expiry, begins_at].max, sells: sells, trial: false, owner_id: owner_id, enterprise_id: enterprise.id).first
      bill_item ||= BillItem.new(begins_at: [trial_expiry, begins_at].max, sells: sells, trial: false, owner_id: owner_id, enterprise_id: enterprise.id)
      bill_item.update_attributes({ends_at: ends_at, turnover: after_trial_orders.sum(&:total)})
    end

    bill_item
  end
end
