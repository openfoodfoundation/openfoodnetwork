require "tasks/sample_data/addressing"
require "tasks/sample_data/logging"

class GroupFactory
  include Logging
  include Addressing

  def create_samples
    log "Creating groups"
    return if EnterpriseGroup.where(name: "Producer group").exists?

    create_group(
      name: "Producer group",
      owner: enterprises.first.owner,
      on_front_page: true,
      description: "The seed producers",
      address: "6 Rollings Road, Upper Ferntree Gully, 3156"
    )
  end

  private

  def create_group(params)
    group = EnterpriseGroup.new(params)
    group.address = address(params[:address])
    group.enterprises = enterprises
    group.save!
  end

  def enterprises
    @enterprises ||= Enterprise.where(
      name: [
        "Fred's Farm",
        "Freddy's Farm Shop",
        "Fredo's Farm Hub"
      ]
    )
  end
end
