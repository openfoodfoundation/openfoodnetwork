# frozen_string_literal: true

module DataFoodConsortium::Connector::SKOSHelper
  def addAttribute(name, value)
    self.instance_variable_set("@#{name}", value)
    self.define_singleton_method(name) do
      instance_variable_get("@#{name}")
    end
  end

  def hasAttribute(name)
    self.methods.include?(:"#{name}")
  end
end
