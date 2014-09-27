class EnterpriseConfigRefactor < ActiveRecord::Migration
  def up
    add_column :enterprises, :sells, :string, null: false, default: 'none'

    Enterprise.all do |enterprise|
      enterprise.sells = sells_what?(enterprise)
      enterprise.save!
    end

    remove_column :enterprises, :type
    remove_column :enterprises, :is_distributor
  end

  def down
  end

  #TODO make this work
  def sells_what?(enterprise)    
    return "none" if !enterprise.is_distributor || enterprise.type == "profile"
    return "own" if enterprise.type == "single" || enterprise.suppliers == [enterprise]
    return "any"
  end
end
