# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe SocialMediaBuilder do
  let(:enterprise) do
    create(
      :enterprise,
      id: 10_000,

      # These formats are requested by our UI:
      facebook: "www.facebook.com/user",
      instagram: "handle",
      linkedin: "www.linkedin.com/company/name",
    )
  end

  describe ".social_media" do
    it "links to Facebook" do
      result = SocialMediaBuilder.social_media(enterprise, "facebook")
      expect(result.url).to eq "https://www.facebook.com/user"
    end

    it "links to Instagram" do
      result = SocialMediaBuilder.social_media(enterprise, "instagram")
      expect(result.url).to eq "https://www.instagram.com/handle/"
    end

    it "links to Linkedin" do
      result = SocialMediaBuilder.social_media(enterprise, "linkedin")
      expect(result.url).to eq "https://www.linkedin.com/company/name"
    end
  end
end
