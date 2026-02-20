# frozen_string_literal: true

# Fetch data from another platform and store it locally.
class DfcImporter
  attr_reader :errors

  def import_enterprise_profiles(platform, enterprises_url)
    raise "unsupported platform" if platform != "lf-dev"

    api = DfcPlatformRequest.new(platform)
    body = api.call(enterprises_url)
    graph = DfcIo.import(body).to_a
    farms = graph.select { |item| item.semanticType == "dfc-b:Enterprise" }
    farms.each { |farm| import_profile(farm) }
  end

  def import_profile(farm)
    owner = find_or_import_user(farm)
    enterprise = EnterpriseImporter.new(owner, farm).import
    enterprise.save! if enterprise.changed?
    enterprise.address.save! if enterprise.address.changed?
  rescue ActiveRecord::RecordInvalid => e
    Alert.raise(e, farm: DfcIo.export(farm))
    @errors ||= []
    @errors << e
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
