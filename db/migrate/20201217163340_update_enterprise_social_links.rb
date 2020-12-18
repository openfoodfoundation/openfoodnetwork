class UpdateEnterpriseSocialLinks < ActiveRecord::Migration
  def up
    say_with_time "Updating enterprises..." do
      count = 0
      Enterprise.find_each do |enterprise|
        unless enterprise.instagram.nil?
          say "Update enterprise: #{enterprise.id}"
          enterprise.update(instagram: enterprise.instagram)
          count += 1
        end
      end
      count
    end
  end
end
