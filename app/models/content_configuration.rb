class ContentConfiguration < Spree::Preferences::Configuration
  preference :home_tagline_cta, :string, default: "Browse Open Food Network Australia"
  preference :home_whats_happening, :string, default: "Thanks for making the Open Food Network possible. Our vision is a better food system, and we're proud of what we're achieving together."

  preference :footer_about_url, :string, default: "http://global.openfoodnetwork.org/ofn-local/open-food-network-australia/"
end
