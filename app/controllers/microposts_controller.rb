class MicropostsController < ApplicationController
  before_action :signed_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy
  before_action :prepare_foods, only: :create
  before_action :set_content, only: :create
  before_action :create_post_food, only: :create
  after_action  :handle_foods, only: :create

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.save
      flash[:success] = "Micropost created!"
      redirect_to root_url
    else
      @feed_items = current_user.feed.paginate(page: params[:page])
      render 'static_pages/home'
    end
  end

  def destroy
    @micropost.destroy
    redirect_to root_url
  end

  private

    def prepare_foods
      @foods = Array.new
      params[:foods].each do |food_info|
        @foods << Food.new(food_info)
      end if params[:foods]
      params[:food_ids].each do |food_id|
        food = Food.find_by_id(food_id)
        @foods << food if food
      end if params[:food_ids]
    end
       
    def set_content
      return unless params[:micropost][:content] == ""
      params[:micropost][:content] = "I've ate:" unless @foods.empty?
    end
 
    def create_post_food
      return if @foods.empty?
      info = {prot:0, carb:0, fat:0}
      @foods.each do |food|
        info[:prot] += food.prot
        info[:carb] += food.carb
        info[:fat] += food.fat
      end
      params[:micropost][:post_food_id] = Food.create(info).id
    end
    
    def handle_foods
      @foods.each do |food|
        food.save if food.id == nil
        PostFoodRelationship.
          create(food_id: food.id, post_id: @micropost.id) if food.id
      end
    end

    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end

    def micropost_params
      params.require(:micropost).
             permit(:content,     :comment_id,  
                    :original_id, :shared_id, :post_food_id)
    end
end 
