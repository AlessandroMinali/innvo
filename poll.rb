# frozen_string_literal: true

require 'sinatra'
require 'hamlit'
require 'sequel'
require 'mail'
if development?
  require 'sinatra/reloader'
  require 'pry'
end

require_relative 'model'

# push notifications
# style: https://codepen.io/cbp/pen/XJGQqZ?limit=all&page=3&q=form
# alt style: https://codepen.io/matmarsiglio/pen/HLIor?q=form&limit=all&type=type-pens

# https://devcenter.heroku.com/articles/config-vars

# support admins

options = { address: 'smtp.gmail.com',
            port: 587,
            user_name: ENV.fetch('EMAIL_USERNAME'),
            password: ENV.fetch('EMAIL_PASSWORD'),
            authentication: 'plain',
            enable_starttls_auto: true }

ROLES = {
  admin: 1,
  support: 2
}.freeze

Mail.defaults do
  delivery_method :smtp, options
end

helpers do
  def current_user
    User.find(email: current_email)
  end

  def current_email
    session[:email]
  end

  def login_or_idea?
    %w[/login /login/thanks /login/reject /idea/new].include? request.path_info
  end

  def admin?
    ROLES.value?(current_user.role) || current_user.email == 'aminali@degica.com'
  end
end

enable :sessions

set :haml, escape_html: false
set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
# set :static_cache_control, [:public, :max_age => 259200]

configure do
  set team: ENV.fetch('EMAIL_DOMAIN') { 'degica.com' }
end

before do
  return if request.path_info.include?('/login')
  redirect to('/login') if current_user.nil?
end

get '/' do
  @ideas = Idea.all.sort_by { |i| i.likes + i.super_likes * 2 - i.dislikes * 1.5 }.reverse
  haml :index
end

get '/login' do
  haml :login
end

get '/login/thanks' do
  haml :thanks
end

get '/login/reject' do
  haml :reject
end

get '/login/:token' do
  user = User.find(token: params[:token])
  unless user.nil?
    session[:email] = user.email
    user.update(token: nil)
  end
  redirect to('/')
end

post '/login' do
  if params[:email].split('@').last == settings.team
    token = SecureRandom.uuid
    user = User.find(email: params[:email])
    user = User.create(email: params[:email], uuid: SecureRandom.uuid) if user.nil?
    user.update(token: token)

    @link = "#{request.scheme}://"\
            "#{request.host}"\
            "#{(':' + request.port.to_s) if settings.development?}"\
            "/login/#{token}"
    @team = settings.team
    template = ERB.new(File.read('./views/mailer/one_time_pass.html.erb')).result(binding)

    mail = Mail.new do
      subject 'Innovo Login'

      html_part do
        content_type 'text/html; charset=UTF-8'
        body template
      end
    end

    mail[:to] = params[:email]
    mail[:from] = 'innovo-d@degica.com'
    mail.deliver!

    redirect to('/login/thanks')
  else
    redirect to('/login/reject')
  end
end

get '/idea/new' do
  haml :new
end

get '/idea/:uuid' do
  @idea = Idea.find(uuid: params[:uuid])
  @vote = Vote.find(user_id: current_user.id, idea_id: @idea.id)&.vote
  haml :show
end

post '/idea' do
  wanted_keys = %w[title desc]
  params.keep_if { |key, _| wanted_keys.include? key }
        .merge!(user_id: current_user.id, uuid: SecureRandom.uuid)

  id = Idea.create(params).uuid
  redirect to("/idea/#{id}")
end

post '/idea/:uuid/vote' do
  @idea = Idea.find(uuid: params[:uuid])
  halt 404 if @idea.nil?

  @user = User.find(uuid: params[:user])
  halt 404 if @user.nil?

  halt 404 unless %w[up heart down].include?(params[:vote])

  @user_vote = Vote.find(user_id: @user.id, idea_id: @idea.id)

  if @user_vote
    @user_vote.update(vote: params[:vote])
  else
    Vote.create(user_id: @user.id, idea_id: @idea.id, vote: params[:vote])
  end
end

get '/idea/:uuid/destroy' do
  admin? && Idea.find(uuid: params[:uuid]).destroy
  redirect to('/')
end
