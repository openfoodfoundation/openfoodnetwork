Rails.application.reloader.to_prepare do
  ActiveModel::ArraySerializer.root = false
  ActiveModel::Serializer.root = false
end
