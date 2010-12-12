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
  has n, :files, :through => :user_files, :model => 'ShareFile'
  
  def self.seeders
    all(:conditions => ["oauth_token IS NOT NULL AND oauth_secret IS NOT NULL AND oauth_token!='' AND oauth_secret!='' AND active=?", true])
  end
    
end

class ShareFile
  include DataMapper::Resource

  property :id,               Serial
  property :name,             String
  property :use_b64,          Boolean,    :default => false
  property :path,             Text
  property :created_at,       DateTime
  property :updated_at,       DateTime

  has n, :user_files, :child_key => [:file_id]
  has n, :users, :through => :user_files
end


class UserFile
  include DataMapper::Resource

  property :id,               Serial
  property :user_id,          Integer
  property :file_id,          Integer
  property :cursor_position,  Integer, :required =>false
  property :cursor_length,    Integer, :required =>false
  property :tweet_count,      Integer, :required =>false
  property :active,           Boolean
  property :started_at,       DateTime, :required =>false
  property :finished_at,      DateTime, :required =>false
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :user
  belongs_to :file, :model => 'ShareFile'

end

class Tweet
  include DataMapper::Resource

  property :id,               Serial
  property :tweet_id,         String # So large, needs to be string!
  property :tweet_message,    Text
  property :cursor_position,  Integer
  property :user_id,          Integer
  property :file_id,    Integer
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :user
  belongs_to :file, :model => 'ShareFile'

end