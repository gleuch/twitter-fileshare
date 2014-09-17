module Sinatra
  module Authorization

  def auth
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
  end

  def unauthorized!(realm='Administrative Area')
    header 'WWW-Authenticate' => %(Basic realm="#{realm}")
    throw :halt, [ 401, 'Authorization Required' ]
  end

  def bad_request!
    throw :halt, [ 400, 'Bad Request' ]
  end

  def authorized?
    (configatron.skip_auth === true ? true : request.env['REMOTE_USER'])
  end

  def authorize(username, password)
    configatron.auth_logins.each do |login|
      auth = login.split(':')
      return true if auth[0] == username && auth[1] == password
    end
    false
  end

  def require_administrative_privileges
    return if authorized?
    unauthorized! unless auth.provided?
    bad_request! unless auth.basic?
    unauthorized! unless authorize(*auth.credentials)
    request.env['REMOTE_USER'] = auth.username
  end

  def admin?
    authorized?
  end

  end
end