class AddCustomerTermsAndConditionsAccepted < ActiveRecord::Migration[4.2]
  def change
    add_column :customers, :terms_and_conditions_accepted_at, :datetime
  end
end
