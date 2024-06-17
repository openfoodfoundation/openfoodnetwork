# frozen_string_literal: true

require 'spree/core/controller_helpers/auth'

module Spree
  module Api
    module ControllerSetup
      def self.included(klass)
        klass.class_eval do
          include AbstractController::Rendering
          include ActionView::ViewPaths
          include AbstractController::Callbacks
          include AbstractController::Helpers

          include ActiveSupport::Rescuable

          include ActionController::Rendering
          include ActionController::ImplicitRender
          include ActionController::Rescue
          include ActionController::Head

          include CanCan::ControllerAdditions
          include Spree::Core::ControllerHelpers::Auth

          prepend_view_path "#{Rails.root}app/views"
          append_view_path File.expand_path("../../../app/views", File.dirname(__FILE__))
        end
      end
    end
  end
end
