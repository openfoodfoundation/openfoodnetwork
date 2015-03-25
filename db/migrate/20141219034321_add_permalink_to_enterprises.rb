class AddPermalinkToEnterprises < ActiveRecord::Migration
  def up
    add_column :enterprises, :permalink, :string

    Enterprise.reset_column_information

    Enterprise.all.each do |enterprise|
      counter = 1
      permalink = enterprise.name.parameterize
      permalink = "my-enterprise-name" if permalink == ""
      while Enterprise.find_by_permalink(permalink) do
        permalink = enterprise.name.parameterize + counter.to_s
        counter += 1
      end

      enterprise.update_column :permalink, permalink
    end

    change_column :enterprises, :permalink, :string, null: false
  end

  def down
    remove_column :enterprises, :permalink
  end
end
