class ProductsController < ApplicationController
  before_action :check_login, only: %i[create]
  before_action :set_product, only: %i[show update]
  # before_action :authorize_request #locks the controller
  before_action :check_login

  def index
    render json: Product.all
  end

  def show
  end

  def create
    # current_user is the user decoded from token
    product = current_user.products.build(product_params) 

    if product.save
      render json: product, status: :created 
    else
      render json: { errors: product.errors }, status: :unprocessable_entity
    end 
  end
    

  def update
  end

  def destroy
  end

  private
    def product_params
      params.require(:product).permit(:title, :price, :published)
    end

    def set_product
      @product = Product.find(params[:id])
    end
end
