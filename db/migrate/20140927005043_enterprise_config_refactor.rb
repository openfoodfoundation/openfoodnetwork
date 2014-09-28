class EnterpriseConfigRefactor < ActiveRecord::Migration
  def up
    add_column :enterprises, :sells, :string, null: false, default: 'none'

    Enterprise.all.each do |enterprise|
      enterprise.sells = sells_what?(enterprise)
      enterprise.save!
    end

    remove_column :enterprises, :type
    remove_column :enterprises, :is_distributor
  end

  def down
  end

  def sells_what?(enterprise)
    is_distributor = enterprise.read_attribute(:is_distributor)
    type = enterprise.read_attribute(:type)
    return "none" if !is_distributor || type == "profile"
    return "own" if type == "single" || enterprise.suppliers == [enterprise]
    return "any"
  end
end
