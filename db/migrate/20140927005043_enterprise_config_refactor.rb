class EnterpriseConfigRefactor < ActiveRecord::Migration
  def up
    add_column :enterprises, :sells, :string, null: false, default: 'none'
    add_index :enterprises, :sells
    add_index :enterprises, [:is_primary_producer, :sells]

    Enterprise.all.each do |enterprise|
      enterprise.update_attributes!({:sells => sells_what?(enterprise)})
    end

    remove_column :enterprises, :type
    remove_column :enterprises, :is_distributor
  end

  def down
    # This process is lossy. Producer profiles wont exist.
    add_column :enterprises, :type, :string, null: false, default: 'profile'
    add_column :enterprises, :is_distributor, :boolean

    Enterprise.all.each do |enterprise|
      enterprise.update_attributes!({
        :type => type?(enterprise),
        :is_distributor => distributes?(enterprise)
      })
    end

    remove_column :enterprises, :sells
    remove_index :enterprises, :sells
    remove_index :enterprises, [:is_primary_producer, :sells]
  end

  def sells_what?(enterprise)
    is_distributor = enterprise.read_attribute!(:is_distributor)
    is_primary_producer = enterprise.read_attribute!(:is_primary_producer)
    type = enterprise.read_attribute!(:type)
    return "own" if type == "single" && (is_distributor || is_primary_producer)
    return "none" if !is_distributor || type == "profile"
    return "any"
  end

  def distributes?(enterprise)
    enterprise.read_attribute!(:sells) != "none"
  end

  def type?(enterprise)
    sells = enterprise.read_attribute!(:sells)
    return "profile" if sells == "none"
    return "single" if sells == "own"
    return "full"
  end
end
