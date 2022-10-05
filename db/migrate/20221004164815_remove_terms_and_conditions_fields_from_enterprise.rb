class RemoveTermsAndConditionsFieldsFromEnterprise < ActiveRecord::Migration[6.1]
  def change
    remove_column :enterprises, :terms_and_conditions_file_name, :string
    remove_column :enterprises, :terms_and_conditions_content_type, :string
    remove_column :enterprises, :terms_and_conditions_file_size, :integer
    remove_column :enterprises, :terms_and_conditions_updated_at, :datetime
  end
end
