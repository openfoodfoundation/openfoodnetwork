class ChangeSuburbPostcodeToString < ActiveRecord::Migration
  def up
    change_column :suburbs, :postcode,  :string
  end

  def down
    change_column :suburbs, :postcode,  'integer USING (postcode::integer)'
  end
end
