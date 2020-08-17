class AddTermsAndConditionsToEnterprises < ActiveRecord::Migration
  def change
    add_attachment :enterprises, :terms_and_conditions
  end
end
