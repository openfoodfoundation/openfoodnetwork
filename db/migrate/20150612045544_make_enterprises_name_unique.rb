class MakeEnterprisesNameUnique < ActiveRecord::Migration
  def up
    dup_names = Enterprise.group('name').select('name, COUNT(*) AS num_enterprises')

    dup_names.each do |data|
      (data.num_enterprises.to_i - 1).times do |i|
        e = Enterprise.find_by_name data.name
        new_name = "#{data.name}-#{i+1}"
        e.update_column :name, new_name
        say "Renamed enterprise #{data.name} to #{new_name}"
      end
    end

    add_index :enterprises, :name, unique: true
  end

  def down
    remove_index :enterprises, :name
  end
end
