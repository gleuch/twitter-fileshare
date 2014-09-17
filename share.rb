# Tweet Fileshare
# idea by Theo Watson, developed by Greg Leuch


configure :development do
  # set :raise_errors, Proc.new { false }
  # set :show_exceptions, false

  class Sinatra::Reloader < Rack::Reloader
     def safe_load(file, mtime, stderr = $stderr)
       if file == __FILE__
         ::Sinatra::Application.reset!
         stderr.puts "#{self.class}: reseting routes"
       end
       super
     end
  end
  use Sinatra::Reloader
end


configure do
  ROOT = File.expand_path(File.dirname(__FILE__))

  # Libraries, etc.
  %w(twitter_oauth configatron haml ROOT/lib/spork ROOT/lib/authenticate digest/md5 base64).each{|lib| require lib.gsub(/ROOT/, ROOT)}

  # Configatron settings
  configatron.configure_from_yaml("#{ROOT}/settings.yml", :hash => Sinatra::Application.environment.to_s)
  configatron.directory_path = '' if configatron.directory_path == '/'

  # Controllers and helpers
  %w(admin oauth public).each do |lib|
    require "#{ROOT}/controllers/#{lib}"
    require "#{ROOT}/helpers/#{lib}"
  end

  # Models
  %w(dm-core dm-types dm-timestamps dm-aggregates dm-ar-finders ROOT/lib/model).each{|lib| require lib.gsub(/ROOT/, ROOT)}
  DataMapper.setup(:default, configatron.db_connection.gsub(/ROOT/, ROOT))
  DataMapper.auto_upgrade!

  # require 'sinatra/memcached'
  # set :cache_enable, (configatron.enable_memcache && Sinatra::Application.environment.to_s == 'production')
  # set :cache_logging, false # causes problems if using w/ partials! :/

  # If you want to run this as a cron job, set up the conf file or pass this ENV param (CRON=1 ruby share.rb)
  # if configatron.spawn_cron_job || ENV['CRON'] == 1
  #   require 'spork'
  #   Spork.spork do
  #     require "helpers/admin"
  #
  #     spawn_loop = true
  #     sleep 2 # Let Sinatra load up first!
  #     while spawn_loop
  #       STDERR.puts "Running seeder..."
  #       begin
  #         run_seeder
  #         unless @errors.blank?
  #           STDERR.puts "** ERRORS:"
  #           @errors.each do |e|
  #             STDERR.puts "   * #{e}"
  #           end
  #         end
  #         unless @success.blank?
  #           @sucess.each do |s|
  #             STDERR.puts "#{s} !"
  #           end
  #         end
  #         @success, @errors = nil, nil
  #         STDERR.puts "-"*30
  #         STDERR.puts "\n"
  #         sleep 10 # Sleep one minute
  #       rescue Timeout::Erro
  #         spawn_loop = false
  #         STDERR.puts "\n\nQutting seeder. (Timeout error.)\n\n"
  #       rescue
  #         spawn_loop = false
  #         STDERR.puts "\n\nQutting seeder. (Unknown Error!)\n\n"
  #       end
  #     end
  #   end
  # end

  set :sessions, true
  set :views, File.dirname(__FILE__) + '/views/'+ configatron.template_name
  set :public, File.dirname(__FILE__) + '/public/'+ configatron.template_name
end


helpers do
  def dev?; (Sinatra::Application.environment.to_s != 'production'); end
  # def dev?; false; end

  def partial(name, options = {})
    item_name, counter_name = name.to_sym, "#{name}_counter".to_sym
    options = {:cache => true, :cache_expiry => 300}.merge(options)

    if collection = options.delete(:collection)
      collection.enum_for(:each_with_index).collect{|item, index| partial(name, options.merge(:locals => { item_name => item, counter_name => index + 1 }))}.join
    elsif object = options.delete(:object)
      partial(name, options.merge(:locals => {item_name => object, counter_name => nil}))
    else
      path, file = name.gsub(/^(.*\/)([A-Z0-9_\-\.]+)$/i, '\1'), name.gsub(/^(.*\/)([A-Z0-9_\-\.]+)$/i, '\2')
      # unless options[:cache].blank?
      #   cache "_#{name}", :expiry => (options[:cache_expiry].blank? ? 300 : options[:cache_expiry]), :compress => false do
      #     haml "_#{name}".to_sym, options.merge(:layout => false)
      #   end
      # else
        haml "#{path}_#{file}".to_sym, options.merge(:layout => false)
      # end
    end
  end

  # Modified from Rails ActiveSupport::CoreExtensions::Array::Grouping
  def in_groups_of(item, number, fill_with = nil)
    if fill_with == false
      collection = item
    else
      padding = (number - item.size % number) % number
      collection = item.dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      returning [] do |groups|
        collection.each_slice(number) { |group| groups << group }
      end
    end
  end

  def flash; @_flash ||= {}; end

  def redirect(uri, *args)
    session[:_flash] = flash unless flash.empty?
    status 302
    response['Location'] = uri
    halt(*args)
  end

end




before do
  @_flash, session[:_flash] = session[:_flash], nil if session[:_flash]

  prefix = Regexp.new("^#{configatron.directory_path}")
  not_found && halt unless prefix.match(request.path_info)
  request.path_info = request.path_info.gsub(prefix, (configatron.directory_path == request.path_info ? '/' : ''))
end



# 404 (file not found) errors
not_found do
  @error = 'Sorry, but the page you were looking for could not be found.</p><p><a href="/">Click here</a> to return to the homepage.'
  haml :fail
end

# 500 (unspecific) errors
error do
  @error = request.env['sinatra.error'].message || "You've hit an undocumented error."
  haml :fail
end