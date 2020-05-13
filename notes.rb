
require_relative 'config/environment'
require_relative 'models/text_analyzer.rb'

class App < Sinatra::Base
  get '/' do
    erb :index
  end

  post '/' do
    @analyzed_text = TextAnalyzer.new(params[:user_text])
   
    erb :results
  end
end






post '/' do
    text_from_user = params[:user_text]
   
    @analyzed_text = TextAnalyzer.new(text_from_user)
   
    erb :results
  end

  We can shorten this to:
  
  post '/' do
    @analyzed_text = TextAnalyzer.new(params[:user_text])
   
    erb :results
  end


  Update
  To implement the update action, we need a controller action that renders an update form, and we need a controller action to catch the post request sent by that form.
  
  The get '/models/:id/edit' controller action will render the edit.erb view page.
  The edit.erb view page will contain the form for editing a given instance of a model. This form will send a PATCH request to patch '/models/:id'.
  The patch '/models/:id' controller action will find the instance of the model to update, using the id from params, update and save that instance.
  We'll need to update config.ru to use the Sinatra Middleware that lets our app send patch requests.
  
  config.ru:
  
  use Rack::MethodOverride
  run ApplicationController
  From there, you'll need to add a line to your form.
  
  edit.erb:
  
  <form action="/models/<%= @model.id %>" method="post">
      <input id="hidden" type="hidden" name="_method" value="patch">
      <input type="text" ...>
  </form>
  The MethodOverride middleware will intercept every request sent and received by our application. If it finds a request with name="_method", it will set the request type based on what is set in the value attribute, which in this case is patch.
  
  Delete
The delete part of CRUD is a little tricky. It doesn't get its own view page but instead is implemented via a "delete button" on the show page of a given instance. This "delete button", however, isn't really a button; it's a form! The form should send a DELETE request to delete '/models/:id' and should contain only a "submit" button with a value of "delete". That way, it will appear as only a button to the user. Here's an example:

<form method="post" action="/models/<%= @model.id %>">
  <input id="hidden" type="hidden" name="_method" value="DELETE">
  <input type="submit" value="delete">
</form>
The hidden input field is important to note here. This is how you can submit PATCH and DELETE requests via Sinatra. The form tag method attribute will be set to post, but the hidden input field sets it to DELETE.


The Routes
Index Action
get '/articles' do
  @articles = Article.all
  erb :index
end
The controller action above responds to a GET request to the route '/articles'. This action is the index action and allows the view to access all the articles in the database through the instance variable @articles.

New Action
get '/articles/new' do
  erb :new
end
 
post '/articles' do
  @article = Article.create(:title => params[:title], :content => params[:content])
  redirect to "/articles/#{@article.id}"
end
Above, we have two controller actions. The first one is a GET request to load the form to create a new article. The second action is the create action. This action responds to a POST request and creates a new article based on the params from the form and saves it to the database. Once the item is created, this action redirects to the show page.

Show Action
get '/articles/:id' do
  @article = Article.find_by_id(params[:id])
  erb :show
end
In order to display a single article, we need a show action. This controller action responds to a GET request to the route '/articles/:id'. Because this route uses a dynamic URL, we can access the ID of the article in the view through the params hash.

Edit Action
get '/articles/:id/edit' do  #load edit form
    @article = Article.find_by_id(params[:id])
    erb :edit
  end
 
patch '/articles/:id' do #edit action
  @article = Article.find_by_id(params[:id])
  @article.title = params[:title]
  @article.content = params[:content]
  @article.save
  redirect to "/articles/#{@article.id}"
end
The first controller action above loads the edit form in the browser by making a GET request to articles/:id/edit.

The second controller action handles the edit form submission. This action responds to a PATCH request to the route /articles/:id. First, we pull the article by the ID from the URL, then we update the title and content attributes and save. The action ends with a redirect to the article show page.


We do have to do a little extra work to get the edit form to submit via a PATCH request.

Your form must include a hidden input field that will submit our form via patch.

<form action="/articles/<%= @article.id %>" method="post">
  <input id="hidden" type="hidden" name="_method" value="patch">
  <input type="text" name="title">
  <input type="text" name="content">
  <input type="submit" value="submit">
</form>
The second line above <input type="hidden" name="_method" value="patch"> is what does this for us.

Using PATCH, PUT and DELETE requests with Rack::MethodOverride Middleware
The hidden input field shown above uses Rack::MethodOverride, which is part of Sinatra middleware.

In order to use this middleware, and therefore use PATCH, PUT, and DELETE requests, you must tell your app to use the middleware.

In the config.ru file, you'll need the following line to be placed above the run ApplicationController line:

use Rack::MethodOverride
In an application with multiple controllers, use Rack::MethodOverride must be placed above all controllers in which you want access to the middleware's functionality.

This middleware will then run for every request sent by our application. It will interpret any requests with name="_method" by translating the request to whatever is set by the value attribute. In this example, the post gets translated to a patch request. The middleware handles put and delete in the same way.

Many developers are confused about the difference between PATCH and PUT. Imagine a car with a license plate (id). Now let's say we wanted to change the car's color from red to green. We could:

Pull our our disintegrating raygun and zap the car ZZZZAP and build a new car that was identical to the first car in all aspects except that it was green instead of red. We could slap the old license plate (id) on it and, from a certain point of view, we have "updated the Car with given license plate with id equal to params[:id]
Find a given car and repaint it
Option 1 is like PUT a replace of all fields. Option 2 is like a PATCH. The subtler question of what differentiates the two hinges on a fancy Latin-esque word: idempotent. If you're really curious about the subtleties here, check out this Stack Overflow question. It may suffice to say that PATCH is relatively new and in the early days of REST we only used PUT (We were zapping all day long !).

Delete Action
delete '/articles/:id' do #delete action
  @article = Article.find_by_id(params[:id])
  @article.delete
  redirect to '/articles'
end
On the article show page, we have a form to delete it. The form is submitted via a DELETE request to the route /articles/:id. This action finds the article in the database based on the ID in the url parameters, and deletes it. It then redirects to the index page /articles.

Again, this delete form needs the hidden input field:

<form action="/articles/<%= @article.id %>" method="post">
  <input id="hidden" type="hidden" name="_method" value="delete">
  <input type="submit" value="delete">
</form>