# frozen_string_literal: true

class UpdateEnterpriseInstagramLinks < ActiveRecord::Migration[6.1]
  class Enterprise < ActiveRecord::Base
    def strip_url(url)
      url&.sub(%r{(https?://)?}, '')
    end

    def correct_instagram_url(url)
      url && strip_url(url.downcase).sub(%r{www.instagram.com/}, '').sub(%r{instagram.com/},
                                                                         '').delete("@")
    end

    def instagram
      correct_instagram_url self[:instagram]
    end
  end

  def up
    Enterprise.where.not(instagram: nil).find_each do |enterprise|
      enterprise.update!(instagram: enterprise.instagram)
      enterprise.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
