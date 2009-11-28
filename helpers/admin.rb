# Admin helpers

helpers do

  include Sinatra::Authorization


  def read_from_file(file, cursor=0)
    path = find_file(file)
    raise 'File not found.' unless path

    str, incr = '', 0

    fr = File.new(path)
    fr.seek(cursor, IO::SEEK_SET)
    fragment = fr.read(160) # Get out at least enough for a tweet.

    fragment.each_byte do |b|
      break if (str.length + "#{b}".length) >= 140 # Twitter length
      str << b; incr += 1
    end

    return {:msg => str, :cursor => (cursor+incr)}
  end

  def find_file(file)
    fpath = "#{configatron.folder_path}/#{file}".gsub(/\/\//, '/')
    return (File.file?(fpath) ? fpath : false)
  end
end