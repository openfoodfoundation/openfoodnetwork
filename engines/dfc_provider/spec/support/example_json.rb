# frozen_string_literal: true

module ExampleJson
  def self.read(name)
    pathname = DfcProvider::Engine.root.join("spec/fixtures/files/#{name}.json")
    JSON.parse(pathname.read)
  end
end
