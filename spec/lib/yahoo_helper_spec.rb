describe YahooHelper do
  subject { YahooHelper }

  describe ".get_consumer" do
    let(:consumer) { double('consumer') }
    before do
      allow(OAuth::Consumer).to receive(:new).and_return(consumer)
      stub_const('YAHOO_CREDENTIALS',
                 {
                   :app_id => "123",
                   :app_secret => "xyz"
                 })
      stub_const('YahooHelper::CLIENT_OPTIONS',
                 {
                   :access_token_path  => '/fakeoauth/v2/get_token',
                   :authorize_path     => '/fakeoauth/v2/request_auth',
                   :request_token_path => '/fakeoauth/v2/get_request_token',
                   :site               => 'https://fakeapi.login.yahoo.com'
                 })
    end

    it "initializes oauth consumer with app id and secret" do
      expect(OAuth::Consumer).to receive(:new).with(
        YAHOO_CREDENTIALS[:app_id], YAHOO_CREDENTIALS[:app_secret], YahooHelper::CLIENT_OPTIONS
      )

      expect(subject.get_consumer).to eq(consumer)
    end
  end

  context "vcr stubbed responses" do
    let(:fake_user) do
      User.find_or_create_by(yahoo_id: '123') do |user|
        user.email = "test@example.com"
        user.yahoo_token = "abc123"
        user.yahoo_session_handle = "def890"
        user.yahoo_secret = "xyz123"
        user.password = Devise.friendly_token[0,20]
      end
    end
    let(:vcr_league_key)    { "346.l.115003" }
    let(:vcr_team_key)      { "346.l.115003.t.7" }
    let(:vcr_date)          { "2015-09-09" }
    let(:vcr_pitcher_count) { 12 }

    describe '.get_user_league' do
      it "returns the league" do
        VCR.use_cassette("yahoo/user_league") do
          league = subject.get_user_league(fake_user)

          expect(league["league_key"]).to eq(vcr_league_key)
        end
      end
    end

    describe '.get_user_team' do
      it "returns the team" do
        VCR.use_cassette("yahoo/user_team") do
          team = subject.get_user_team(fake_user)

          expect(team["team_key"]).to eq(vcr_team_key)
        end
      end
    end

    describe '.get_league_settings' do
      it "returns the league settings" do
        VCR.use_cassette("yahoo/league_settings") do
          league_settings = subject.get_league_settings(fake_user, { "league_key" => vcr_league_key })

          expect(league_settings["roster_positions"]["roster_position"].count).to eq(vcr_pitcher_count)
        end
      end
    end

    describe ".get_user_team_roster" do
      it "returns the user team roster" do
        VCR.use_cassette("yahoo/user_team_roster") do
          roster = subject.get_user_team_roster(fake_user, vcr_team_key, vcr_date)
          pitchers = roster.select{ |p| p["display_position"] =~ /(SP)|(RP)/ }

          expect(pitchers.count).to eq(vcr_pitcher_count)
        end
      end
    end
  end
end
