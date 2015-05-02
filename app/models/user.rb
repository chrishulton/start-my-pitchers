class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:yahoo]
  # field :yahoo_id
  # field :yahoo_access_token,      :type => Hash, :default => {}

  validates :yahoo_id, :yahoo_token, :yahoo_secret,
    :presence => true


  validates :yahoo_id, :uniqueness => { :message => "Yahoo account is already registered" }

  # def self.initialize_from_auth_hash(auth)
    # user = self.new
    # user.yahoo_id = auth.uid
    # user.yahoo_token = auth.credentials.token
    # user.yahoo_secret = auth.credentials.secret
    # user
  # end

  def self.initialize_from_auth_hash(auth)
    where(yahoo_id: auth.uid).first_or_create! do |user|
      # user.provider = auth.provider
      user.yahoo_id = auth.uid
      user.email = auth.info.email || "#{auth.info.nickname.gsub!(" ","")}#{rand}@fake.com"
      user.password = Devise.friendly_token[0,20]
      user.yahoo_token = auth.credentials.token
      user.yahoo_secret = auth.credentials.secret
    end
  end
end
