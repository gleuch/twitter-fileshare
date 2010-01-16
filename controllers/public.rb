# Public controllers

# Homepage
get '/' do
  # cache "homepage/#{@user.blank? ? 'guest' : 'user'}", :expiry => 600, :compress => true do
    @current_files = UserFile.all(:conditions => ["finished_at IS NULL AND active=?", true], :order => [:started_at.asc]) rescue nil
    @completed_files = UserFile.all(:conditions => ["finished_at IS NOT NULL AND active=?", true], :order => [:finished_at.desc]) rescue nil
    @tweet = Tweet.first(:order => [:updated_at.desc]) rescue nil

    haml :'public/home'
  # end
end

get '/leech/:id' do
  @file = UserFile.first(:id => params[:id]) rescue nil
  unless @file.blank?
    if @file.finished_at == nil || !@file.active
      @error = 'This file has not finished seeding to Twitter.'
    else
      haml :'public/leech'
    end
  else
    @error = "Could not find file."
    haml :fail
  end
end

get '/download/:id' do
  @file = UserFile.first(:id => params[:id]) rescue nil

  unless @file.blank?
    if (params[:uid].to_i * 2) > (Time.now.to_i - 60)
      path = find_file(@file.file.name)
      unless path.blank?
        attachment(path)
        send_file(path)
      else
        @error = 'Sorry, but there was a problem downloading this file from Twitter. Please try again.'
        haml :fail
      end
    else
      @error = "You do not have permission to download #{@file.file.name}."
      haml :fail
    end
  else
    @error = "Could not find file."
    haml :fail
  end
end