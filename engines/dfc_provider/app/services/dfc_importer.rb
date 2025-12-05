# frozen_string_literal: true

# Fetch data from another platform and store it locally.
class DfcImporter
  def import_enterprise_profiles(platform)
    raise "unsupported platform" if platform != "lf-dev"

    endpoint = "https://api.beta.litefarm.org/dfc/enterprises/"
    api = DfcPlatformRequest.new(platform)
    body = api.call(endpoint)
    graph = DfcIo.import(body).to_a
    farms = graph.select { |item| item.semanticType == "dfc-b:Enterprise" }
    farms.each { |farm| import_profile(farm) }
  end

  def import_profile(farm)
    owner = find_or_import_user(farm)
    EnterpriseImporter.new.import(owner, farm)
  end

  def find_or_import_user(farm)
    email = farm.mainContact.emails.first
    user = Spree::User.find_by(email:)

    return user if user

    Spree::User.create!(
      email:,
      password: SecureRandom.base58(64),
    )
  end
end
