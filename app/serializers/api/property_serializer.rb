# frozen_string_literal: true

class Api::PropertySerializer < ActiveModel::Serializer
  attributes :id, :name, :presentation

  # Client-side we don't care about the property name. Send the presentation
  # since this is what we want to show to the user.
  def name
    object.presentation
  end
end
