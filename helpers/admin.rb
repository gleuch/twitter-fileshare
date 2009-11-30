# Admin helpers

helpers do
  include Sinatra::Authorization


  def file_time_left(file)
    # Assume 1 tweet per minute.
    return 'Unknown' unless file.cursor_position && file.cursor_length
    return 'Paused' unless file.active
    return 'Not started' unless file.started_at
    return 'Finished' if file.finished_at

    pct_now = (file.cursor_position/file.cursor_length.to_f)*100

    p Time.now.to_i
    p Time.parse(file.started_at.to_s).to_i

    time_now = (Time.now.to_i - Time.parse(file.started_at.to_s).to_i)
    time_left = (time_now*100)/pct_now.to_f
    
    str = Time.at(Time.now.to_i + time_left)
    "Left: #{str}"
  end

  def read_from_file(file, cursor=0)
    path = find_file(file.name)
    raise 'File not found.' unless path

    str, incr = "#{file.id}-#{cursor}:", 0 # Prepare inital vars, include unique id on string (Twitter duplicate tweet hack).

    fr = File.new(path)
    fr.seek(cursor, IO::SEEK_SET) # Move to position.
    fragment = fr.read(160) # Get out at least enough for a tweet.
    fragment.each_byte do |b|
      s = " #{b.to_s}"
      break if (str.length + s.length) >= 140 # Twitter length, do not cross.
      str << s; incr += 1
    end

    return {:msg => str, :cursor => (cursor+incr)}
  end

  def find_file(file)
    fpath = "#{configatron.folder_path}/#{file}".gsub(/\/\//, '/')
    return (File.file?(fpath) ? fpath : false)
  end

  def md5_file(file)
    path = find_file(file)
    raise 'File not found.' unless path
    return Digest::MD5.hexdigest(File.new(path).read) rescue false
  end

end