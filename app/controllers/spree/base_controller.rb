# frozen_string_literal: true

require 'cancan'

module Spree
  class BaseController < ApplicationController
    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::RespondWith
    include Spree::Core::ControllerHelpers::SSL
    include Spree::Core::ControllerHelpers::Common

    respond_to :html
  end
end

require 'spree/i18n/initializer'
