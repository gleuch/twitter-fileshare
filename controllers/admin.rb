# Admin controllers

# OAuth /connect & /auth are under controllers/oauth.rb

# Admin dashboard
get '/admin' do
  require_administrative_privileges

  @queue = UserFile.all(:conditions => ["finished_at IS NULL AND active=?", true], :order => [:started_at.asc]) rescue nil

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

    # begin
      twitter_connect(user)

      if userfile.started_at.nil?
        md5 = md5_file(file.name)
        info = @twitter_client.update("New file: #{file.name} (MD5: #{md5})")

        if info && (info['id'].to_s || '').match(/\d+/)
          userfile.update(:started_at => Time.now)
        else
          (@errors ||= []) << "Could not sent BOF tweet to #{user.screen_name}."
        end

        sleep 5 # Slow us down for a sec
      end

      tweet = read_from_file(file, (userfile.cursor_position || 0))

      # Start tweet if there is something to tweet.
      unless tweet[:msg].blank?
        info = @twitter_client.update(tweet[:msg].to_s)
        if info && (info['id'].to_s || '').match(/\d+/)
          userfile.update(:active => true, :cursor_position => tweet[:cursor])
          Tweet.new(:tweet_id => info['id'], :tweet_message => tweet[:msg], :cursor_position => tweet[:cursor], :user_id => user.id, :file_id => file.id)
        else
          (@errors ||= []) << "Could not sent tweet to #{user.screen_name}."
        end
         
      # Otherwise, asssume it is the end of the file.
      else
        md5 = md5_file(file.name)
        info = @twitter_client.update("End of file: #{file.name} (MD5: #{md5})")
        if info && (info['id'].to_s || '').match(/\d+/)
          userfile.update(:finished_at => Time.now)
        else
          (@errors ||= []) << "Could not sent EOF tweet to #{user.screen_name}."
        end
      end
    # rescue
    #   (@errors ||= []) << "There was an error sending a file for @#{user.screen_name}."
    # end
  end


  @error = @errors.join('<br />') rescue nil
  @error ||= 'This page coming soon.'

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