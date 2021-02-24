# frozen_string_literal: true

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
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

def load_list(id)
  list = session[:lists].find{ |list| list[:id] == id }
  return list if list

  session[:error] = "The specified list was not found"
  redirect "/lists"
end

def next_element_id(elements)
  max = elements.map { |element| element[:id] }.max || 0
  max + 1
end

# Creates a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)       # Checking if error is truthy

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    # Add a key value pair: id: id
    id = next_element_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end


# Displays a single list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)

  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)       # Checking if error is truthy
  id = params[:id].to_i
  @list = load_list(id)

  if error  
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].reject! { |list| list[:id] == id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted"
    redirect "/lists"
  end
end

# Adds a todo to a list
post "/lists/:list_id/todos" do
  text = params[:todo].strip
  error = error_for_todo(text)       # Checking if error is truthy
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_element_id(@list[:todos])
    @list[:todos] << {id: id, name: text, completed: false}

    session[:success] = "A todo has been added"
    redirect "/lists/#{@list_id}"
  end
end

# Deletes a todo from list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:id].to_i

  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted"
    redirect "/lists/#{@list_id}"
  end
end

# Update status of todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:id].to_i

  is_completed = params[:completed] == "true"

  todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  todo[:completed] = is_completed
  session[:success] = "The todo has been updated"

  redirect "/lists/#{@list_id}"
end

# Complete all todos 
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  
  @list[:todos].each do |current_todo|
    current_todo[:completed] = true
  end

  session[:success] = "All todos have been completed"
  redirect "/lists/#{@list_id}"
end

helpers do 
  def all_todos_complete?(list)
    return false unless list[:todos].size > 0

    list[:todos].all? do |current_todo|
      current_todo[:completed] == true
    end
  end

  def completed_todos(list) 
    list[:todos].count do |current_todo|
      current_todo[:completed] == true
    end
  end

  def list_class(list)
    "complete" if all_todos_complete?(list)
  end

  def remaining_todos_count(list)
    "#{completed_todos(list)} / #{(list[:todos].size)}"
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| all_todos_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list)}
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end