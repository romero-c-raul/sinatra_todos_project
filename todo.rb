# frozen_string_literal: true

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all the lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Renders the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size                              # Validates character length
    'The list name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }  # Validates repeated titles
    'List name must be unique.'
  end
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size                              # Validates character length
    'The list name must be between 1 and 100 characters.'
  end
end

# Creates a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)       # Checking if error is truthy

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Displays a single list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)       # Checking if error is truthy
  id = params[:id].to_i
  @list = session[:lists][id]

  if error  
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{id}"
  end
end

post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted"
  redirect "/lists"
end

# Adds a todo to a list
post "/lists/:list_id/todos" do
  text = params[:todo].strip
  error = error_for_todo(text)       # Checking if error is truthy
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    redirect "/lists/#{@list_id}"
  end
end

# Deletes a todo from list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:id].to_i

  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted"

  redirect "/lists/#{@list_id}"
end

# Update status of todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:id].to_i

  is_completed = params[:completed] == "true"

  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated"

  redirect "/lists/#{@list_id}"
end

# Complete all todos 
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  
  @list[:todos].each do |current_todo|
    current_todo[:completed] = true
  end

  session[:success] = "All todos have been completed"
  redirect "/lists/#{@list_id}"
end