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

end

class File
  include DataMapper::Resource

  property :id,               Serial
  property :name,             String
  property :path,             String
  property :created_at,       DateTime
  property :updated_at,       DateTime

end


class UserFile
  include DataMapper::Resource

  property :id,               Serial
  property :user_id,          Integer
  property :file_id,          Integer
  property :cursor,           Integer

  property :started_at,       DateTime
  property :finished_at,      DateTime
  property :created_at,       DateTime
  property :updated_at,       DateTime

end