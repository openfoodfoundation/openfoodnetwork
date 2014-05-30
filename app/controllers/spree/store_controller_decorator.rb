class Spree::StoreController
  layout 'darkswarm'

  def unauthorized
    render 'shared/unauthorized', :status => 401
  end
end
