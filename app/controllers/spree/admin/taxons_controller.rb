# frozen_string_literal: true

module Spree
  module Admin
    class TaxonsController < Spree::Admin::BaseController
      respond_to :html, :json, :js

      def edit
        @taxonomy = Taxonomy.find(params[:taxonomy_id])
        @taxon = @taxonomy.taxons.find(params[:id])
        @permalink_part = @taxon.permalink.split("/").last
      end

      def create
        @taxonomy = Taxonomy.find(params[:taxonomy_id])
        @taxon = @taxonomy.taxons.build(params[:taxon])
        if @taxon.save
          respond_with(@taxon) do |format|
            format.json { render json: @taxon.to_json }
          end
        else
          flash[:error] = Spree.t('errors.messages.could_not_create_taxon')
          respond_with(@taxon) do |format|
            format.html do
              if redirect_to @taxonomy
                spree.edit_admin_taxonomy_url(@taxonomy)
              else
                spree.admin_taxonomies_url
              end
            end
          end
        end
      end

      def update
        @taxonomy = Taxonomy.find(params[:taxonomy_id])
        @taxon = @taxonomy.taxons.find(params[:id])
        parent_id = params[:taxon][:parent_id]
        new_position = params[:taxon][:position]

        if parent_id || new_position # taxon is being moved
          new_parent = parent_id.nil? ? @taxon.parent : Taxon.find(parent_id.to_i)
          new_position = new_position.nil? ? -1 : new_position.to_i

          # Bellow is a very complicated way of finding where in nested set we
          # should actually move the taxon to achieve sane results,
          # JS is giving us the desired position, which was awesome for previous setup,
          # but now it's quite complicated to find where we should put it as we have
          # to differenciate between moving to the same branch, up down and into
          # first position.
          new_siblings = new_parent.children
          if new_position <= 0 && new_siblings.empty?
            @taxon.move_to_child_of(new_parent)
          elsif new_parent.id != @taxon.parent_id
            if new_position.zero?
              @taxon.move_to_left_of(new_siblings.first)
            else
              @taxon.move_to_right_of(new_siblings[new_position - 1])
            end
          elsif new_position < new_siblings.index(@taxon)
            @taxon.move_to_left_of(new_siblings[new_position]) # we move up
          else
            @taxon.move_to_right_of(new_siblings[new_position - 1]) # we move down
          end
          # Reset legacy position, if any extensions still rely on it
          new_parent.children.reload.each do |t|
            t.update_columns(
              position: t.position,
              updated_at: Time.zone.now
            )
          end

          if parent_id
            @taxon.reload
            @taxon.set_permalink
            @taxon.save!
            @update_children = true
          end
        end

        if params.key? "permalink_part"
          parent_permalink = @taxon.permalink.split("/")[0...-1].join("/")
          parent_permalink += "/" if parent_permalink.present?
          params[:taxon][:permalink] = parent_permalink + params[:permalink_part]
        end
        # check if we need to rename child taxons if parent name or permalink changes
        if params[:taxon][:name] != @taxon.name || params[:taxon][:permalink] != @taxon.permalink
          @update_children = true
        end

        if @taxon.update(taxon_params)
          flash[:success] = flash_message_for(@taxon, :successfully_updated)
        end

        # rename child taxons
        if @update_children
          @taxon.descendants.each do |taxon|
            taxon.reload
            taxon.set_permalink
            taxon.save!
          end
        end

        respond_with(@taxon) do |format|
          format.html { redirect_to spree.edit_admin_taxonomy_url(@taxonomy) }
          format.json { render json: @taxon.to_json }
        end
      end

      def destroy
        @taxon = Taxon.find(params[:id])
        @taxon.destroy
        respond_with(@taxon) { |format| format.json { render json: '' } }
      end

      private

      def taxon_params
        params.require(:taxon).permit(
          :name, :parent_id, :position, :icon, :description, :permalink,
          :taxonomy_id, :meta_description, :meta_keywords, :meta_title
        )
      end
    end
  end
end
