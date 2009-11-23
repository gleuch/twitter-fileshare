# OAuth helpers

helpers do
  def twitter_connect(user={})
    @twitter_client = TwitterOAuth::Client.new(:consumer_key => configatron.twitter_oauth_token, :consumer_secret => configatron.twitter_oauth_secret, :token => (!user.blank? ? user.oauth_token : nil), :secret => (!user.blank? ? user.oauth_secret : nil)) rescue nil
  end

  def twitter_fail(msg=false)
    @error = (!msg.blank? ? msg : 'An error has occured while trying to talk to Twitter. Please try again.')
    return haml :fail
  end


  def user_profile_url(screen_name, at=true); "<a href='http://www.twitter.com/#{screen_name || ''}' target='_blank'>#{at ? '@' : ''}#{screen_name || '???'}</a>"; end

  def parse_tweet(tweet)
    tweet = tweet.gsub(/(http|https)(\:\/\/)([A-Z0-9\.\-\_\:]+)(\/?)([\w\=\+\-\.\?\&\%\#\~\/\[\]]+)/i, '<a href="\1\2\3\4\5" target="_blank" rel="nofollow">\1\2\3\4\5</a>')
    tweet = tweet.gsub(/(@)([A-Z0-9\_]+)/i, '<a href="http://www.twitter.com/\2" target="_blank" rel="nofollow">\1\2</a>')
    tweet = tweet.gsub(/(#[A-Z0-9\_]+)/i, '<a href="http://twitter.com/search?q=\1" target="_blank" rel="nofollow">\1</a>')
    tweet
  end

end