class SessionsController < ApplicationController
  skip_before_action :authenticate_request, only: [:create]

  def create
    frontend_url = ENV['FRONT_URL']
    Rails.logger.info(frontend_url)
    # OmniAuthで提供される認証情報を取得
    user_info = request.env['omniauth.auth']

    # GitHubのユーザーIDを使ってトークンを生成
    token = generate_token_with_github_user_id(github_user_id, provider)

    # GitHubのユーザーIDを使ってUserAuthenticationテーブルを検索
    user_authentication = UserAuthentication.find_by(uid: github_user_id, provider: provider)
    Rails.logger.info(user_authentication)

    if user_authentication
      # 既に存在する場合は、特定のページにリダイレクト
      Rails.logger.info("RunteqのGithubメンバーで、かつアプリユーザー登録されている")
      redirect_to "#{frontend_url}/users?token=#{token}", allow_other_host: true
    else
      # ユーザー登録フォームページにリダイレクト
      Rails.logger.info("RunteqのGithubメンバーで、まだアプリユーザー登録されていない")
      redirect_to "#{frontend_url}/users/new?token=#{token}", allow_other_host: true
    end
  end

  private

  # Json Web Tokenを暗号化の上で生成する
  def generate_token_with_github_user_id(github_user_id, provider)
    # Json Web Tokenの有効期間は1日限り
    exp = Time.now.to_i + 24 * 3600
    payload = { github_user_id: github_user_id, provider: provider, exp: exp }
    hmac_secret = ENV['JWT_SECRET_KEY']
    JWT.encode(payload, hmac_secret, 'HS256')
  end

end
