class DistributorsController < ApplicationController
  force_ssl

  respond_to :html

  helper 'spree/admin/navigation'
  layout '/spree/layouts/admin'

  def index
    @distributors = Distributor.all
    respond_with(@distributors)
  end

  def new
    @distributor = Distributor.new
  end

  def edit
    @distributor = Distributor.find(params[:id])
  end

  def update
    @distributor = Distributor.find(params[:id])

    if @distributor.update_attributes(params[:distributor])
      redirect_to distributors_path
    else
      render :action => "edit"
    end
  end

  def show
    @distributor = Distributor.find(params[:id])
    respond_with(@distributor)
  end

  def create
    @distributor = Distributor.new(params[:distributor])
    if @distributor.save
      redirect_to distributors_path
    else
      render :action => "new"
    end
  end
end