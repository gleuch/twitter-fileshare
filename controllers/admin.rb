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
  run_seeder

  @errors = @errors.join('<br />') rescue nil
  @success = @success.join('<br />') rescue nil

  haml :'admin/run'
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

# View current queue
get '/admin/queue' do
  require_administrative_privileges

  @queue = UserFile.all(:conditions => ["finished_at IS NULL AND active=?", true], :order => [:started_at.asc]) rescue nil
  haml :'admin/queue'
end

# Add a file to pirate
get '/admin/files' do
  require_administrative_privileges

  # Check for new files
  queued_files = (ShareFile.all.collect(&:name) || []).push('.', '..')

  @files = (Dir.entries(configatron.file_folder_path) || []).reject{|f| queued_files.include?(f)}
  # @files = ShareFile.all(:order => [:name.asc]) rescue nil

  @users = User.seeders.all(:order => [:screen_name.asc]) rescue nil

  haml :'admin/files'
end

# Save queued file
post '/admin/queue' do
  require_administrative_privileges

  # @error ||= 'You must select a file.' if params[:file].nil? || params[:file] == ''
  @error ||= 'You must select a user.' if params[:user].nil? || params[:user] == ''
  @error ||= 'You must select a file.' unless find_file(params[:file])
  @error ||= 'You must select a tweeting method.' if params[:tweet_method].nil? || params[:tweet_method] == ''

  unless @error
    @file = ShareFile.create(:name => params[:file], :tweet_method => params[:tweet_method], :path => "#{configatron.file_folder_path.gsub(/\/$/, '')}/#{params[:file]}")
    # @file = ShareFile.first(:id => params[:file]) rescue nil
    @user = User.first(:id => params[:user]) rescue nil

    unless @file.nil? || @user.nil?
      begin
        userfile = UserFile.first_or_new(:user_id => @user.id, :file_id => @file.id)
        userfile.attributes = {:cursor_length => file_length(@file.name)}
        userfile.active = true if userfile.new?
        userfile.save

        # TODO : Add flash here...
        redirect '/admin'
      rescue; end
    end
  end

  @error ||= $!
  @error ||= 'Could not find file or user.'
  haml :fail
end