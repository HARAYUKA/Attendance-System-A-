class User < ApplicationRecord
  has_many :attendances, dependent: :destroy
   # 「remember_token」という仮想の属性を作成します。
  attr_accessor :remember_token
  before_save { self.email = email.downcase }
   
  validates :name,  presence: true, length: { maximum: 50 }
  
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 100 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  validates :affiliation, length: { in: 2..30 }, allow_blank: true
  validates :basic_work_time, presence: true
  validates :designated_work_start_time, presence: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

   # 渡された文字列のハッシュ値を返します。
  def User.digest(string)
    cost = 
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返します。
  def User.new_token
    SecureRandom.urlsafe_base64
  end
  
  # 永続セッションのためハッシュ化したトークンをデータベースに記憶します。
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
  # トークンがダイジェストと一致すればtrueを返します。
  def authenticated?(remember_token)
    # ダイジェストが存在しない場合はfalseを返して終了します。
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end 
  
  # ユーザーのログイン情報を破棄します。
  def forget
    update_attribute(:remember_digest, nil)
  end
  
  def self.search(search)
    return User.all unless search
    User.where(['name LIKE ?', "%#{search}%"])
  end
  
  # #importメソッド
  # def self.import(file)
  #   imported_num = 0
  #   #文字コード変換のためにKernel#openとCSV#newを併用
  #   open(file.path, 'r:cp932:utf-8', undef: :replace) do |f|
  #     CSV.foreach(file.path, headers: true) do |row|
  #       next if row.header_row?
  #       #CSVの行情報をHASHに変換
  #       table = Hash[[row.headers, row.fields].transpose]
  #       # IDが見つかれば、レコードを呼び出し、見つかれなければ、新しく作成
  #       user = find_by(id: row["id"]) || new
  #       if user.nil?
  #         user = new
  #       end
  #       # CSVからデータを取得し、設定する
  #       user.attributes = row.to_hash.slice(*updatable_attributes)
  #       # バリデーションOKの場合は保存する
  #       if user.valid?
  #         user.save!
  #         imported_num += 1
  #       end
  #     end
  #   end
  #   # 更新件数を表す
  #   imported_num
  # end
  
  def self.import_by_csv(file)
    imported_num = 0
    open(file.path, 'r:cp932:utf-8', undef: :replace) do |f|
      csv = CSV.new(f, :headers => :first_row)
      caches = User.all.index_by(&:id)
      csv.each do |row|
        next if row.header_row?
        #CSVの行情報をHASHに変換
        table = Hash[[row.headers, row.fields].transpose]
        #登録済みデータ情報
        #登録されてなければ作成
        user = caches[table['id']]
        if user.nil?
           user = new
        end
        #データ情報更新
        user.attributes = table.slice(*table.except(:created_at, :updated_at).keys)
        #バリデーションokの場合は保存
        if user.valid?
          user.save!
          imported_num += 1
        end
      end
    end
    #更新件数を返す
    imported_num
  end
  
  # 更新を許可するカラムを定義
  def self.updatable_attributes
    ["name", "email", "affiliation", "employee_number", "uid", "basic_work_time", 
    "designated_work_start_time", "designated_work_end_time", "superior", "admin", "password"]
  end
  
end