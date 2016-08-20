require 'open_food_network/paperclippable'

class ContentConfiguration < Spree::Preferences::FileConfiguration
  include OpenFoodNetwork::Paperclippable

  # Header
  preference :logo, :file
  preference :logo_mobile, :file
  preference :logo_mobile_svg, :file
  has_attached_file :logo, default_url: "/assets/ofn-logo.png"
  has_attached_file :logo_mobile
  has_attached_file :logo_mobile_svg, default_url: "/assets/ofn-logo-mobile.svg"

  # Home page
  preference :home_hero, :file
  preference :home_show_stats, :boolean, default: true
  has_attached_file :home_hero, default_url: "/assets/home/home.jpg"

  # Producer sign-up page
  preference :producer_signup_pricing_table_html, :text, default: "(TODO: Pricing table)"
  preference :producer_signup_case_studies_html, :text, default: "(TODO: Case studies)"
  preference :producer_signup_detail_html, :text, default: "(TODO: Detail)"

  # Hubs sign-up page
  preference :hub_signup_pricing_table_html, :text, default: "(TODO: Pricing table)"
  preference :hub_signup_case_studies_html, :text, default: "(TODO: Case studies)"
  preference :hub_signup_detail_html, :text, default: "(TODO: Detail)"

  # Groups sign-up page
  preference :group_signup_pricing_table_html, :text, default: "(TODO: Pricing table)"
  preference :group_signup_case_studies_html, :text, default: "(TODO: Case studies)"
  preference :group_signup_detail_html, :text, default: "(TODO: Detail)"

  # Footer
  preference :footer_logo, :file
  has_attached_file :footer_logo, default_url: "/assets/ofn-logo-footer.png"

  #Other
  preference :footer_facebook_url, :string, default: "https://www.facebook.com/OpenFoodNet"
  preference :footer_twitter_url, :string, default: "https://twitter.com/OpenFoodNet"
  preference :footer_instagram_url, :string, default: ""
  preference :footer_linkedin_url, :string, default: "http://www.linkedin.com/groups/Open-Food-Foundation-4743336"
  preference :footer_googleplus_url, :string, default: ""
  preference :footer_pinterest_url, :string, default: ""
  preference :footer_email, :string, default: "hello@openfoodnetwork.org"
  preference :community_forum_url, :string, default: "http://community.openfoodnetwork.org"
  preference :footer_links_md, :text, default: <<-EOS
[Newsletter sign-up](/)

[News](/)

[Calendar](/)
EOS

  preference :footer_about_url, :string, default: "http://www.openfoodnetwork.org/ofn-local/open-food-network-australia/"
  preference :footer_tos_url, :string, default: "/Terms-of-service.pdf"
end
