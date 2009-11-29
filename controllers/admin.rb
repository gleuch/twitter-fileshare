# Admin controllers

# OAuth /connect & /auth are under controllers/oauth.rb

# Admin dashboard
get '/admin' do
  require_administrative_privileges



  # Not the right place for this, but great spot for quick testing of read_from_file helper func.
  # info = read_from_file('04 The Five Alive Song.mp3')

  info = md5_file('04 The Five Alive Song.mp3')
  STDERR.puts "MD5: #{info}"

  # 
  # @tweet = info[:msg]
  # @cursor = info[:cursor]
  # 
  # 
  # STDERR.puts "Tweet (#{@cursor}): #{@tweet}"

  haml :'admin/index'
end


# Be a pirate!
get '/admin/run' do
  require_administrative_privileges

  @users = User.all
  
  @users.each do |user|
    STDERR.puts "User: #{user.screen_name}..."
    file = user.files.first(:order => [:started_at.asc, :created_at.asc], :conditions => ['finished_at IS NOT NULL']) rescue nil
    next if file.nil? # Assume that user has no files queued.
    
    begin
      twitter_connect(user)
    
      unless file.active
        md5 = md5_file(file.name)
        @twitter_client.update("New file: #{name}. MD5: #{md5}")
        # file.update(:active => true)
      end
    
      # tweet = read_from_file(file.name, file.cursor)
      # info = @twitter_client.update(tweet[:msg])
      #
      # if info === true
      #   file.update(:active => true, :cursor => tweet[:cursor])
      #   Tweet.new(:tweet_id => info, :tweet_message => tweet[:msg], :cursor => tweet[:cursor], :user_id => user.id, :file_id => file.id)
      # end
      #     
      # # check if end of file... if so, close out
      # # file.update(:finished_at => Time.now) if false
    rescue
      STDERR.puts "There was an error sending a file for @#{user.screen_name}."
    end
  end



  @error = 'This page coming soon.'
  haml :fail
end


# Remove a Twitter account.
delete '/admin/users/:id' do
  require_administrative_privileges
  raise 'This page coming soon.'
end

# Get info about a Twitter account.
get '/admin/users/:id' do
  require_administrative_privileges
  @user = User.first(:id => params[:id]) rescue nil
  haml :'admin/user'
end


# Show queued file info
get '/admin/queue/:id' do
  require_administrative_privileges
  raise 'This page coming soon.'
end

# Delete a queue'd file
delete '/admin/queue/:id' do
  require_administrative_privileges
  raise 'This page coming soon.'
end

# Queue a file to pirate
get '/admin/queue' do
  require_administrative_privileges
  raise 'This page coming soon.'
end

# Save queued file
put '/admin/queue' do
  require_administrative_privileges
  # raise 'This page coming soon.'
end