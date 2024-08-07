# frozen_string_literal: true

module Spree
  module Admin
    class TaxonsController < ::Admin::ResourceController
      before_action :set_taxon, except: %i[create index new]

      def index
        @taxons = Taxon.order(:name)
      end

      def new
        @taxon = Taxon.new
      end

      def edit; end

      def create
        @taxon = Spree::Taxon.new(taxon_params)
        if @taxon.save
          flash[:success] = flash_message_for(@taxon, :successfully_created)
          redirect_to edit_admin_taxon_path(@taxon.id)
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        if @taxon.update(taxon_params)
          flash[:success] = flash_message_for(@taxon, :successfully_updated)
          redirect_to edit_admin_taxon_path(@taxon.id)
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        status = if @taxon.destroy
                   flash_message = t('.delete_taxon.success')
                   status = :ok
                 else
                   flash_message = t('.delete_taxon.error')
                   status = :unprocessable_entity
                 end

        respond_to do |format|
          format.html {
            flash[:success] = flash_message if status == :ok
            flash[:error] = flash_message if status == :unprocessable_entity
            redirect_to admin_taxons_path
          }
          format.turbo_stream {
            flash[:success] = flash_message if status == :ok
            flash[:error] = flash_message if status == :unprocessable_entity
            render :destroy_taxon, status:
          }
        end
      end

      private

      def set_taxon
        @taxon = Taxon.find(params[:id])
      end

      def taxon_params
        params.require(:taxon).permit(
          :name, :position, :icon, :description, :permalink,
          :meta_description, :meta_keywords, :meta_title, :dfc_id
        )
      end
    end
  end
end
