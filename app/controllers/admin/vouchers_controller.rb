# frozen_string_literal: true

module Admin
  class VouchersController < ResourceController

   def new
     @enterprise = Enterprise.find_by permalink: params[:enterprise_id]
   end
  end
end
