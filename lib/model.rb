class User
  include DataMapper::Resource

  property :id,               Serial
  property :account_id,       Integer
  property :screen_name,      String
  property :oauth_token,      String
  property :oauth_secret,     String
  property :active,           Boolean,    :default => true
  property :created_at,       DateTime
  property :updated_at,       DateTime

  has n, :user_files
  has n, :files, :through => :user_files
end

class File
  include DataMapper::Resource

  property :id,               Serial
  property :name,             String
  property :path,             String
  property :created_at,       DateTime
  property :updated_at,       DateTime

  has n, :user_files
  has n, :users, :through => :user_files
end


class UserFile
  include DataMapper::Resource

  property :id,               Serial
  property :user_id,          Integer
  property :file_id,          Integer
  property :cursor,           Integer, :nullable => true
  property :active,           Boolean
  property :started_at,       DateTime, :nullable => true
  property :finished_at,      DateTime, :nullable => true
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :user
  belongs_to :file

end

class Tweet
  include DataMapper::Resource

  property :id,               Serial
  property :tweet_id,         String # So large, needs to be string!
  property :tweet_message,    Text
  property :cursor,           Integer
  property :user_id,          Integer
  property :file_id,          Integer
  property :created_at,       DateTime

  belongs_to :user
  belongs_to :file

end