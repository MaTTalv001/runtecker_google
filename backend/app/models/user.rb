class User < ApplicationRecord
  has_many :past_nicknames, dependent: :destroy
  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  has_many :user_social_services, dependent: :destroy
  has_many :social_services, through: :user_social_services
  belongs_to :term
  belongs_to :prefecture
  has_one :user_authentication
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # スコープ周りはDRY的にまとめられそう
  scope :with_nickname, ->(nickname) {
    where('nickname LIKE ?', "%#{nickname}%")
  }

  scope :with_term, ->(term_id) {
    where(term_id: term_id)
  }

  scope :with_prefecture, ->(prefecture_id) {
    where(prefecture_id: prefecture_id)
  }

  scope :with_tag_by_id, ->(tag_id) {
    where(tags: { id: tag_id }).references(:tags)
  }

  scope :with_tag_by_name, ->(tag_name) {
    where(tags: { name: tag_name }).references(:tags)
  }

  def pastname
    past_nicknames.last.nickname unless past_nicknames.empty? # past_nicknamesが空でなければ最新のnicknameを返す
  end

  # ユーザーのデフォルトのソーシャルサービスを取得
  def default_social_services
    social_services.where(service_type: 'default')
  end

  # TODO : 検索用クラスを別途設ける
  def self.search(params)
    # 検索条件を受け取る
    nickname = params[:nickname]
    term = params[:term]
    prefecture = params[:prefecture]
    tag_id = params[:tag_id]
    tag_name = params[:tag_name]

    users = User.distinct.includes(:tags, :prefecture, :term)

    # ニックネームの検索
    users = users.with_nickname(nickname) if nickname.present?

    # 都道府県のid検索
    users = users.with_prefecture(prefecture) if prefecture.present?

    # 入学期のid検索
    users = users.with_term(term) if term.present?

    # タグ検索がない場合はそのまま返す
    # タグ検索のとき、ユーザーデータを再度取得しているのが重くなる可能性があったため、
    # タグ検索以外は個々で返却するようにしています
    return users.order(created_at: :desc) if tag_id.blank? && tag_name.blank?

    # タグidの検索
    users = users.with_tag_by_id(tag_id) if tag_id.present?

    # タグネームの検索
    users = users.with_tag_by_name(tag_name) if tag_name.present?

    # タグ検索したときに、ユーザーが持つタグを全て取得するためにこのように書きました
    # もっといい方法あったら教えて下さい
    return User.includes(:tags).where(id: users.map(&:id)).order(created_at: :desc)
  end

  # ユーザーの情報をカスタムJSON形式で返す
  # これでいいのか分からん
  def as_custom_json_index
    as_json(
      only: %i[id nickname avatar],
      include: {
        prefecture: {
          only: %i[id name]
        },
        term: {
          only: %i[id name]
        },
        tags: {
          only: %i[id name]
        },
        social_services: {
          only: %i[name],
          include:{
            only: %i[account_name]
          }
        }
      }
    ).merge(social_services: default_social_services.map do |service|
      service.as_json(only: %i[id name]).merge(
        user_social_services: service.user_social_services.as_json(only: %i[account_name])
      )
    end)
  end
end