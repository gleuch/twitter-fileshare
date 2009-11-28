# Admin controllers

# OAuth /connect & /auth are under controllers/oauth.rb

# Admin dashboard
get '/admin' do
  require_administrative_privileges

  info = read_from_file('04 The Five Alive Song.mp3')
  
  @tweet = info[:msg]
  @cursor = info[:cursor]


  STDERR.puts "Tweet (#{@cursor}): #{@tweet}"

  haml :'admin/index'
end


# Be a pirate!
get '/admin/run' do
  require_administrative_privileges
  raise 'This page coming soon.'
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