# frozen_string_literal: true

class TagListInputComponent < ViewComponent::Base
  # method in a "hidden_field" form helper and is the method used to get a list of tag on the model
  def initialize(form:, method:, tags:, placeholder: "Add a tag")
    @f = form
    @method = method
    @tags = tags
    @placeholder = placeholder
  end

  attr_reader :f, :method, :tags, :placeholder
end
