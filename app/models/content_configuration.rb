class ContentConfiguration < Spree::Preferences::Configuration
  preference :home_tagline_cta, :string, default: "Browse Open Food Network Australia"
  preference :home_whats_happening, :string, default: "Thanks for making the Open Food Network possible. Our vision is a better food system, and we're proud of what we're achieving together."

  preference :footer_facebook_url, :string, default: "https://www.facebook.com/OpenFoodNet"
  preference :footer_twitter_url, :string, default: "https://twitter.com/OpenFoodNet"
  preference :footer_instagram_url, :string, default: ""
  preference :footer_linkedin_url, :string, default: "http://www.linkedin.com/groups/Open-Food-Foundation-4743336"
  preference :footer_googleplus_url, :string, default: ""
  preference :footer_pinterest_url, :string, default: ""
  preference :footer_email, :string, default: "hello@openfoodnetwork.org"
  preference :footer_links_md, :text, default: <<-EOS
[Newsletter sign-up](/)

[Blog](/)

[Calendar](/)
EOS

  preference :footer_about_url, :string, default: "http://www.openfoodnetwork.org/ofn-local/open-food-network-australia/"
end
