class Api::V1::UsersController < ApplicationController
  # GET /api/v1/users
  def index
    users = search_params_values_present? ? User.search(search_params) : User.all.order(created_at: :desc)
    render json: users.map(&:as_custom_json_index), status: :ok
  end

  # GET /api/v1/users/:id
  def show
    @user = User.find(params[:id])
    render json: @user, include: {
      past_nicknames: {},
      user_social_services: {
        #include: :social_service # これでUserSocialService経由でSocialServiceのデータを含める
      },
      term: {},
      prefecture: {}
    }, methods: [:pastname]
  end

  # POST /api/v1/users
  def create
    @user = User.new(user_params)
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/users/:id
  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    head :no_content
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  # 検索用のパラメータを取得
  def search_params
    params.delete(:user) # なぜかuserが入ってくるので削除
    params.permit(:nickname, :term, :prefecture, :tag_id, :tag_name)
  end

  # 検索用のパラメータが存在するか
  def search_params_values_present?
    search_params.to_h.any?{ |_, value| value.present?}
  end
end