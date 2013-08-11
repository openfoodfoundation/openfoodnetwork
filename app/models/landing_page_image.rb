class LandingPageImage < ActiveRecord::Base
  attr_accessible :photo
  has_attached_file :photo, styles: { max_common_res: ["1920x1080#", :jpg] },
                    :convert_options => { max_common_res: "-quality 75" }

  validates_attachment_presence :photo

  def self.random
    offset(rand(LandingPageImage.count)).first
  end
end
