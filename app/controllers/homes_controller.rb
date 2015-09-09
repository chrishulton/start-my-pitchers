class HomesController < ApplicationController
  def index
    unless current_user
      return redirect_to new_user_session_path
    end

    @league = ::YahooHelper.get_user_league(current_user)
    @team = ::YahooHelper.get_user_team(current_user)
    @week_pitchers = {}

    @today = Time.now.in_time_zone("Eastern Time (US & Canada)").to_date

    (@today.beginning_of_week..@today.end_of_week).each do |date|
      players = ::YahooHelper.get_user_team_roster(current_user, @team['team_key'], date)
      @week_pitchers[date] = get_pitchers(players)
    end
  end

  def set_pitchers
    today = Time.now.in_time_zone("Eastern Time (US & Canada)").to_date
    dates = params[:date] ? [ params[:date] ] : (today.beginning_of_week..today.end_of_week).to_a

    #XXX todo -- initialize helper with user and cache
    # league = ::YahooHelper.get_user_league(current_user)
    # league_settings = ::YahooHelper.get_league_settings(current_user, league)

    team = ::YahooHelper.get_user_team(current_user)
    starters_set = 0

    dates.each do |date|
      players = ::YahooHelper.get_user_team_roster(current_user, team['team_key'], date)
      pitchers = get_pitchers(players)

      startable_pitchers = pitchers.select{ |p|
        p["is_editable"] == "1" && p["eligible_positions"]["position"].include?("SP")
      }

      off_starters_starting = startable_pitchers.select{ |p|
        !(p["starting_status"] && p["starting_status"]["is_starting"] == "1") && ["P","SP"].include?(p["selected_position"]["position"])
      }
      starters_on_bench = startable_pitchers.select{ |p|
        p["starting_status"] && p["starting_status"]["is_starting"] == "1" && "BN" == p["selected_position"]["position"]
      }

      starters_on_bench.each do |benched_starter|
        break if off_starters_starting.empty? # what can you do?

        ::YahooHelper.swap_players(current_user, team, benched_starter, off_starters_starting.shift, date)
        starters_set += 1
      end
    end

    flash[:notice] = "#{starters_set} pitchers moved to starting"
    redirect_to root_path
  end

  private

  def get_pitchers(players)
    players.select{ |p| p["display_position"] =~ /(SP)|(RP)/ }
  end
end
