class UpdateEnterpriseSociaLinks < ActiveRecord::Migration
  def instagram_regex
    %r{\A(?:https?://)?(?:www\.)?instagram\.com/([a-zA-Z0-9._@-]{1,30})/?\z}
  end
  def change
    say_with_time "Updating enterprises..." do
      count = 0
      Enterprise.find_each do |enterprise|
        unless enterprise.instagram.nil?
          say "Update enterprise: #{enterprise.id}"
          enterprise.update(instagram: enterprise.instagram.downcase.try(:gsub, instagram_regex, '\1').gsub('@', ''))
          count += 1
        end
      end
      count
    end
  end
end
