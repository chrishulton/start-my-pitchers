class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:yahoo]

  validates :yahoo_id, :yahoo_token, :yahoo_secret, :yahoo_session_handle,
    :presence => true

  validates :yahoo_id, :uniqueness => { :message => "Yahoo account is already registered" }

  def self.initialize_from_auth_hash(omniauth_hash)
    where(yahoo_id: omniauth_hash.uid).first_or_create! do |user|
      token_creds = omniauth_hash.extra.access_token.params
      # user.provider = auth.provider
      user.yahoo_id = omniauth_hash.uid
      user.email = omniauth_hash.info.email || "#{omniauth_hash.info.nickname.gsub!(" ","")}#{rand}@fake.com"
      user.password = Devise.friendly_token[0,20]
      user.yahoo_token = token_creds[:oauth_token]
      user.yahoo_secret = token_creds[:oauth_token_secret]
      user.yahoo_session_handle = token_creds[:oauth_session_handle]
    end
  end
end
