# Admin controllers

get '/admin' do
  require_administrative_privileges
  haml :'admin/index'
end