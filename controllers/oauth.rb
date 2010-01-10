# OAuth controllers


# Initiate the conversation with Twitter
get '/admin/connect' do
  require_administrative_privileges

  @title = 'Connect to Twitter'
  twitter_connect

  begin
    request_token = @twitter_client.request_token(:oauth_callback => "http://#{request.env['HTTP_HOST']}/admin/auth")
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect request_token.authorize_url.gsub('authorize', 'authenticate')
  rescue
    # cache 'error/connect', :expiry => 600, :compress => false do
      twitter_fail('An error has occured while trying to authenticate with Twitter. Please try again.')
    # end
  end
end


# Callback URL to return to after talking with Twitter
get '/admin/auth' do
  require_administrative_privileges

  @title = 'Authenticate with Twitter'  

  unless params[:denied].blank?
    @error = "We are sorry that you decided to not use #{configatron.site_name}. <a href=\"/\">Click</a> to return."
    haml :fail
  else
    twitter_connect
    @access_token = @twitter_client.authorize(session[:request_token], session[:request_token_secret], :oauth_verifier => params[:oauth_verifier])

    if @twitter_client.authorized?
      begin
        info = @twitter_client.info rescue {}
      rescue
        return twitter_fail
      end

      @user = User.first_or_create(:account_id => info['id'])
      @user.attributes = {:active => true, :account_id => info['id'], :screen_name => info['screen_name'], :oauth_token => @access_token.token, :oauth_secret => @access_token.secret}
      @user.save
      

      # Set and clear session data
      session[:user], session[:account] = @user.id, @user.account_id
      session[:request_token] = session[:request_token_secret] = nil
    end

    redirect '/admin'
  end
end