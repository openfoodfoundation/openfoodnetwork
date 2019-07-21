class Api::RailsFlashSerializer < ActiveModel::Serializer
  attributes :info, :success, :error, :notice

  def info
    object.info
  end

  def success
    object.success
  end

  def error
    object.error
  end

  def notice
    object.notice
  end
end
