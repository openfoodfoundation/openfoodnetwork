class AddTermsAndConditionsToEnterprises < ActiveRecord::Migration[4.2]
  def change
    add_attachment :enterprises, :terms_and_conditions
  end
end
