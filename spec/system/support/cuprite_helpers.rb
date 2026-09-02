# frozen_string_literal: true

module CupriteHelpers
  # Drop #debug anywhere in a test to open a Chrome inspector and pause the execution
  def debug(*)
    page.driver.debug(*)
  end
end
