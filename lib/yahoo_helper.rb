class YahooHelper
  CLIENT_OPTIONS = {
    :access_token_path  => '/oauth/v2/get_token',
    :authorize_path     => '/oauth/v2/request_auth',
    :request_token_path => '/oauth/v2/get_request_token',
    :site               => 'https://api.login.yahoo.com'
  }

  def self.get_consumer
    @consumer = ::OAuth::Consumer.new(YAHOO_CREDENTIALS[:app_id], YAHOO_CREDENTIALS[:app_secret], CLIENT_OPTIONS)
  end

  def self.get_request_token(user)
    OAuth::RequestToken.new(self.get_consumer, user.yahoo_token, user.yahoo_secret)
  end

  def self.get_access_token(user)
    OAuth::AccessToken.new(self.get_consumer, user.yahoo_token, user.yahoo_secret)
  end

  def self.refresh_access_token!(user)
    request_token = get_request_token(user)
    new_access_token = request_token.get_access_token(oauth_session_handle: user.yahoo_session_handle)
    new_token_creds = new_access_token.params
    user.yahoo_token = new_token_creds[:oauth_token]
    user.yahoo_secret = new_token_creds[:oauth_token_secret]
    user.yahoo_session_handle = new_token_creds[:oauth_session_handle]
    user.save!
  end

  def self.get_user_league(user)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games;is_available=1;game_keys=mlb/leagues"
    resp_body = self.make_user_api_request(user, url)
    resp_body["fantasy_content"]["users"]["user"]["games"]["game"]["leagues"]["league"]
  end

  def self.get_league_settings(user, league)
   url = "http://fantasysports.yahooapis.com/fantasy/v2/league/#{league['league_key']}/settings"
   resp_body = self.make_user_api_request(user, url)
   resp_body["fantasy_content"]["league"]["settings"]
  end

  def self.get_user_team(user)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games;is_available=1;game_keys=mlb/teams"
    resp_body = self.make_user_api_request(user, url)
    team_data = resp_body["fantasy_content"]["users"]["user"]["games"]["game"]["teams"]["team"]
  end

  def self.swap_players(user, team, swap_in, swap_out, date)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/team/#{team['team_key']}/roster"
    req_hash = {
      "roster"=> {
        "coverage_type"=> "date",
        "date"         => "#{date}",
        "players"      => [
          {
            "player_key"=> "#{swap_in['player_key']}",
            "position"  => "#{swap_out['selected_position']['position']}"
          },
          {
            "player_key"=> "#{swap_out['player_key']}",
            "position"  => "#{swap_in['selected_position']['position']}"
          }
        ]
      }
    }
    req = req_hash.to_xml({ :skip_types => true, :dasherize  => false, :root => "fantasy_content"})
    access_token = self.get_access_token(user)
    header = { 'Content-Type' => 'application/xml' }

    access_token.put(url, req, header)
  end

  def self.get_user_team_roster(user, team_key, date)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/team/#{team_key}/roster;date=#{date}/players"
    resp_body = self.make_user_api_request(user, url)
    resp_body["fantasy_content"]["team"]["roster"]["players"]["player"]
  end

  private

  def self.make_user_api_request(user, url)
    begin
      access_token = self.get_access_token(user)
      resp = access_token.get(url)
      Hash.from_xml(resp.body)
    rescue OAuth::Problem => error
      if error.message == "token_expired"
        self.refresh_access_token!(user)
        self.make_user_api_request(user, url)
      end
    end
  end
end
