class UpdateEnterpriseSocialLinks < ActiveRecord::Migration
  INSTAGRAM_REGEX = %r{\A(?:https?://)?(?:www\.)?instagram\.com/([a-zA-Z0-9._@-]{1,30})/?\z}.freeze
  class Enterprise < ActiveRecord::Base
    def up
          Enterprise.where.not(instagram: nil).find_each do |enterprise|
            enterprise.update!(instagram: enterprise.instagram.downcase.gsub(INSTAGRAM_REGEX, '\1').delete('@'))         
          end
    end
  end
end