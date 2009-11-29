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
    userfile = user.user_files.first(:order => [:started_at.asc, :created_at.asc], :conditions => ['finished_at IS NULL']) rescue nil
    next if userfile.nil? || userfile.file.nil? # Assume that user has no files queued.

    file = userfile.file
    STDERR.puts "File: #{file.name}..."

    begin
      twitter_connect(user)
    
      if userfile.started_at.nil?
        md5 = md5_file(file.name)
        @twitter_client.update("New file: #{file.name} (MD5: #{md5})")
        userfile.update(:started_at => Time.now)
        sleep 1
      else
        tweet = read_from_file(file.name, (userfile.cursor || 0))
        unless tweet[:msg].blank?
          info = @twitter_client.update(tweet[:msg].to_s)
          if info && (info[:id] || '').match(/\d+/)
            userfile.update(:active => true, :cursor => tweet[:cursor])
            Tweet.new(:tweet_id => info[:id], :tweet_message => tweet[:msg], :cursor => tweet[:cursor], :user_id => user.id, :file_id => file.id)
          end
   
        # Otherwise, asssume it is the end of the file.
        else
          md5 = md5_file(file.name)
          @twitter_client.update("End of file: #{file.name} (MD5: #{md5})")
          file.update(:finished_at => Time.now)
        end
      end
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