class EnterpriseConfigRefactor < ActiveRecord::Migration
  def up
    add_column :enterprises, :sells, :string, null: false, default: 'none'
    add_index :enterprises, :sells
    add_index :enterprises, [:is_primary_producer, :sells]

    # Combine is_distributor and type into sells.
    db.select_values("SELECT id FROM enterprises").each do |enterprise_id|
      distributor = db.select_values("SELECT is_distributor FROM enterprises WHERE id = #{db.quote(enterprise_id)}")
      primary_producer = db.select_value("SELECT is_distributor FROM enterprises WHERE id = #{db.quote(enterprise_id)}")
      type = db.select_value("SELECT type FROM enterprises WHERE id = #{db.quote(enterprise_id)}")
      if type == "single" && (distributor || primary_producer)
        sells = "own" 
      elsif !distributor || type == "profile"
        sells = "none"
      else
        sells = "any"
      end
      db.update("UPDATE enterprises SET sells = #{db.quote(sells)} WHERE id = #{db.quote(enterprise_id)}")
    end

    remove_column :enterprises, :type
    remove_column :enterprises, :is_distributor
  end

  def down
    # This process is lossy. Producer profiles wont exist.
    add_column :enterprises, :type, :string, null: false, default: 'profile'
    add_column :enterprises, :is_distributor, :boolean

    # Combine is_distributor and type into sells.
    db.select_values("SELECT id FROM enterprises").each do |enterprise_id|
      sells = db.select_value("SELECT sells FROM enterprises WHERE id = #{db.quote(enterprise_id)}")
      case sells
      when "own"
        type = "single" 
      when "any"
        type = "full"
      else
        type = "profile"
      end
      distributor = sells != "none"
      db.update("UPDATE enterprises SET type = #{db.quote(type)}, is_distributor = #{db.quote(distributor)}  WHERE id = #{db.quote(enterprise_id)}")
    end

    remove_column :enterprises, :sells
  end

  def db
    ActiveRecord::Base.connection
  end
end
