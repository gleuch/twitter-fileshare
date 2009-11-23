# Public controllers

# Homepage
get '/' do
  # cache "homepage/#{@user.blank? ? 'guest' : 'user'}", :expiry => 600, :compress => true do
    haml :'public/home'
  # end
end