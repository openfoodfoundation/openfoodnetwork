class UpdateEnterpriseSocialLinks < ActiveRecord::Migration
  INSTAGRAM_REGEX = %r{\A(?:https?://)?(?:www\.)?instagram\.com/([a-zA-Z0-9._@-]{1,30})/?\z}.freeze
  def up
      say_with_time "Updating enterprises..." do
        count = 0
        Enterprise.where("instagram IS NOT NULL").find_each do |enterprise|
          say "Update enterprise: #{enterprise.id}"
          enterprise[:instagram] = enterprise[:instagram].downcase.try(:gsub, INSTAGRAM_REGEX, '\1').delete('@')
          count += 1
        end
        count
      end
    end
  end