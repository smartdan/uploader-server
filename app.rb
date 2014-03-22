require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'haml'
require "sinatra/activerecord"
require "fileutils"
require "json"
require "base64"

set :database, "sqlite3:///uploader.db"

 
class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 3 }
  validates :body, presence: true
end

enable :sessions
set :environment, :production
set :port, 8080

helpers do
  def protected!
    if !is_logged_in?    
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
      @error_message = "Not authorized."
      return 
    end
  end

  def validate(username, password)
    # Put your real validation logic here
    return (username == "admin" and password == "admin" ) 
  end
  
  def is_logged_in?
    session["logged_in"] == true
  end
  
  def clear_session
    session.clear
  end
  
   def last_images
     last_images = Dir.glob("public/uploads/*").sort_by {|f| File.mtime(f)}.reverse.first(10)
	 last_images.map! { |m| File.basename(m) }
     return last_images
  end

  def the_user_name
    if is_logged_in? 
      session["username"] 
    else
      "not logged in"
    end
  end
  
  def encode_image(filename)
	File.open(filename, 'r') do |image_file|
		Base64.encode64(image_file.read)
	end
  end
end

get '/' do
  haml :index
end

get '/about' do
  haml :about
end

get '/upload' do
  haml :upload
end

get '/look' do  
  
  if is_logged_in?    
    haml :look
  else
    puts "error"
    # See note above
    @error_message = "Please login."
    haml :login
  end
end

post '/upload' do
  unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    return haml(:upload)
  end

  file = params[:file]
  File.open(File.join(Dir.pwd,"public/uploads", name), 'wb') {|f| f.write tmpfile.read}

  @error_message = "Image loaded."
  redirect :look
end

post '/upload_single' do
  unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    return "KO"
  end

  file = params[:file]
  filename = File.join(Dir.pwd,"public/uploads", name)
  
  File.open(filename, 'wb') {|f| f.write tmpfile.read}
  
  now = Time.now
  
  recents = File.join(Dir.pwd,"public/uploads", "recent_#{now.hour.to_s}_#{now.min.to_s}.jpg")
  FileUtils.cp(filename, recents)
  
  @error_message = "Image loaded."
  
  `ruby old_file_killer.rb public/uploads '*.jpg' 2`
  
  return	"OK"
end

get '/last_image_name' do
 last_image  = Dir.glob("public/uploads/*.jpg").max_by {|f| File.mtime(f)}
 return File.basename(last_image).to_json
end

get '/last_images_names' do
 images = last_images
 return images.to_json
end

get '/last_image' do
 last_image  = Dir.glob("public/uploads/*.jpg").max_by {|f| File.mtime(f)}
 return encode_image(last_image).to_json
end
 
get '/last_images' do
 images = last_images
 return Dir.glob("public/uploads/*").sort_by {|f| File.mtime(f)}.reverse.first(10).map! { |m| encode_image(m) }.to_json
end

get '/login' do
  haml :login
end

post '/login' do
  if(validate(params["username"], params["password"]))
    puts "ok..."
    session["logged_in"] = true
    session["username"] = params["username"]
    # NOTE the right way to do messages like this is to use Rack::Flash
    # https://github.com/nakajima/rack-flash
    @message = "You've been logged in.  Welcome back, #{params["username"]}"
    redirect '/look'
  else
    puts "error"
    # See note above
    @error_message = "Sorry, those credentials aren't valid."
    haml :login
  end
end

get '/logout' do
  clear_session
  @message = "You've been logged out."
  redirect '/'
end

not_found do
  'This is nowhere to be found.'
end

error do
  'Sorry there was an internal error - ' + env['sinatra.error'].name
end