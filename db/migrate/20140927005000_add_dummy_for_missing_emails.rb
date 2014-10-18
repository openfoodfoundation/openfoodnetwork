class AddDummyForMissingEmails < ActiveRecord::Migration
  def up
    Enterprise.all.each do |enterprise|
      enterprise.update_column(:email, "missing@example.com") if enterprise.read_attribute(:email).blank?
    end
  end
end
