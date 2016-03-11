class SetEnterpriseEmailAddress < ActiveRecord::Migration
  def up
    Enterprise.all.each do |enterprise|
      enterprise.email_address = enterprise.email
      enterprise.save
    end
  end
end
