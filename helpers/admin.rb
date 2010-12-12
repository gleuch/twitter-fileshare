# Admin helpers

helpers do
  include Sinatra::Authorization

  def tweets_left(file)
    # Assume 1 tweet per minute.
    return 'Unknown' unless file.cursor_position && file.cursor_length
    return 'Paused' unless file.active
    return 'Not started' unless file.started_at
    return 'Calculating&hellip;' unless file.tweet_count > 3
    return 'Finished' if file.finished_at
    
    total = ((file.tweet_count * file.cursor_length ) / file.cursor_position.to_f).ceil

    "#{file.tweet_count} of about #{total}"
  # rescue
  #   "&#8734;"
  end

  def file_time_left(file)
    # Assume 1 tweet per minute.
    return 'Unknown' unless file.cursor_position && file.cursor_length
    return 'Paused' unless file.active
    return 'Not started' unless file.started_at
    return 'Calculating&hellip;' unless file.tweet_count > 3
    return 'Finished' if file.finished_at

    pct_now = (file.cursor_position/file.cursor_length.to_f)*100 rescue 0

    time_now = (Time.now.to_i - Time.parse(file.started_at.to_s).to_i)
    time_left = (time_now*100)/pct_now.to_f
    
    time = Time.at(Time.now.to_i + time_left).getutc
    "<span class='loctime' timestamp='#{time.iso8601}'>#{time}</span>"
  rescue
    "&#8734;"
  end

  def read_from_file(file, cursor=0)
    path = file.base64? ? find_tmp_file(file.name) : find_file(file.name)
    raise 'File not found.' unless path

    str, incr = "#{file.id}-#{cursor}:", 0 # Prepare inital vars, include unique id on string (Twitter duplicate tweet hack).

    fr = File.new(path)
    fr.seek(cursor, IO::SEEK_SET) # Move to position.
    fragment = fr.read(160) # Get out at least enough for a tweet.
    unless fragment.blank?
      if file.base64? || file.plain_text?
        fragment.split('').each do |b|
          break if (str.length + 1) > 140 # Twitter length, do not cross.
          str << b; incr += 1
        end
      else
        fragment.each_byte do |b|
          s = " #{b.to_s}"
          break if (str.length + s.length) >= 140 # Twitter length, do not cross.
          str << s; incr += 1
        end
      end

      return {:msg => str, :cursor => (cursor+incr)}
    else
      return false
    end
  end

  def find_file(file)
    fpath = "#{configatron.file_folder_path}/#{file}".gsub(/\/\//, '/')
    return (File.file?(fpath) ? fpath : false)
  end

  def find_tmp_file(file)
    fpath = "#{configatron.tmp_folder_path}/#{file}".gsub(/\/\//, '/')
    return (File.file?(fpath) ? fpath : false)
  end

  def md5_file(file)
    path = find_file(file)
    raise 'File not found.' unless path
    return Digest::MD5.hexdigest(File.new(path).read) rescue false
  end

  def file_length(file)
    path = find_file(file)
    raise 'File not found.' unless path
    File.size(path) rescue 0
  end

  def file_size(file, dec=false)
    size = file_length(file)
    fsize, pwr = size, 0

    # Determine its power (i guess?)
    while fsize > 1000
      fsize = fsize/1000.to_f
      pwr += 1
    end

    num = sprintf("%.01f", fsize)

    return num if dec # return as decimal 

    # Get the ending
    ending = case pwr
      when 5; 'PB'
      when 4; 'TB'
      when 3; 'GB'
      when 2; 'MB'
      when 1; 'KB'
      else; 'B'
    end

    return "#{num} #{ending}"
  end



  def run_seeder
    @users = User.all
    @users.each do |user|
      # STDERR.puts "User: #{user.screen_name}..."
      userfile = UserFile.first(:order => [:created_at.asc, :started_at.asc], :conditions => ['finished_at IS NULL AND user_id=?', user.id]) rescue nil
      next if userfile.nil? || userfile.file.nil? # Assume that user has no files queued.

      file = userfile.file
      # STDERR.puts "File: #{file.name}..."

      begin
        twitter_connect(user)

        if userfile.started_at.nil?
          # Make b64 encoded...
          if file.base64?
            tmp_file = "#{configatron.tmp_folder_path}/#{file.name}".gsub(/\/\//, '/')
            File.open(tmp_file, 'w'){|f| f.write [IO.read(find_file(file.name))].pack("m")}
          end

          md5 = md5_file(file.name)
          tweet = "New file: #{file.name} (MD5: #{md5})"
          tweet << " (Base64 encoded)" if file.base64?
          tweet << " (Byte string)" if file.byte_string?
          tweet << " (Plain text)" if file.plain_text?
          info = dev? ? false : @twitter_client.update(tweet)

          if (info && (info['id'].to_s || '').match(/\d+/)) || dev?
            userfile.update(:started_at => Time.now)
            (@success ||= []) << "Sent BOF tweet to #{user.screen_name}."
          else
            (@errors ||= []) << "Could not sent BOF tweet to #{user.screen_name}. (#{(info && info['error']) || 'Unknown Error'})"
          end

          sleep 5 # Slow us down for a sec
        end

        tweet = read_from_file(file, (userfile.cursor_position || 0))

        # Start tweet if there is something to tweet.
        unless tweet.blank? || tweet[:msg].blank?
          info = @twitter_client.update(tweet[:msg].to_s)

          if (info && (info['id'].to_s || '').match(/\d+/)) || dev?
            userfile.update(:active => true, :cursor_position => tweet[:cursor], :tweet_count => ((userfile.tweet_count || 0)+1) )
            Tweet.first_or_create.update(:tweet_id => ((info && info['id']) || 0), :tweet_message => tweet[:msg].to_s, :cursor_position => tweet[:cursor], :user_id => user.id, :file_id => file.id)
            (@success ||= []) << "Sent seed tweet to #{user.screen_name}."
          else
            (@errors ||= []) << "Could not sent tweet to #{user.screen_name}. (#{(info && info['error']) || 'Unknown Error'})"
          end

        # Otherwise, asssume it is the end of the file.
        else
          md5 = md5_file(file.name)
          info = dev? ? false : @twitter_client.update("End of file: #{file.name} (MD5: #{md5})")

          if (info && (info['id'].to_s || '').match(/\d+/)) || dev?
            userfile.update(:finished_at => Time.now)
            (@success ||= []) << "Sent EOF tweet to #{user.screen_name}."
            File.delete(find_tmp_file(file.name)) rescue nil if file.base64? # Get rid of tmp file!
          else
            (@errors ||= []) << "Could not sent EOF tweet to #{user.screen_name}. (#{(info && info['error']) || 'Unknown Error'})"
          end
        end
      rescue
        (@errors ||= []) << "<strong>#{$! || "There was an error sending a file"} for @#{user.screen_name}.</strong>"
      end
    end
  end

end