class Api::Admin::ScheduleSerializer < ActiveModel::Serializer
  attributes :id, :name, :order_cycle_ids, :viewing_as_coordinator

  has_many :order_cycles, serializer: Api::Admin::IdSerializer

  def viewing_as_coordinator
    options[:editable_schedule_ids].include? object.id
  end
end
