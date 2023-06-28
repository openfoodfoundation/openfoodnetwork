# frozen_string_literal: true

module ExampleJson
  def self.read(name)
    pathname = DfcProvider::Engine.root.join("spec/support/#{name}.json")
    JSON.parse(pathname.read)
  end
end
