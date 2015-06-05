class AddUniqueIndexToEnterprisePermalink < ActiveRecord::Migration
  def change
    duplicates = Enterprise.group(:permalink).having('count(*) > 1').pluck(:permalink)
    duplicates.each { |p| resolve_permalink(p) };
    add_index :enterprises, :permalink, :unique => true
  end

  def resolve_permalink(permalink)
    conflicting = Enterprise.where(permalink: permalink)
    while conflicting.size > 1 do
      enterprise = conflicting.pop
      enterprise.permalink = nil
      enterprise.save
    end
  end
end
