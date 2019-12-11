# Rails JWT Token from scratch

Add the following to your `Gemfile`

```
gem 'jwt'
gem 'bcrypt', '~> 3.1.7'
```

### JWT class

Create a file in `lib` folder called `json_web_token.rb`

In the first line we encoded a payload with the secret key my_secret_key. So we get a token we can simply decode. The second line decodes the token and we see that we find our payload well.

We will now include all this logic in a JsonWebToken class in a new file located in `lib/`. This will allow us to avoid duplicating the code. This class will just encode and decode the JWT tokens. So here is the implementation.

```ruby
class JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new decoded
  end
end
```

- the method JsonWebToken.encode takes care of encoding the payload by adding an expiration date of 24 hours by default. We also use the same encryption key as the one configured with Rails

- the method JsonWebToken.decode decodes the JWT token and gets the payload. Then we use the HashWithIndifferentAccess class provided by Rails which allows us to retrieve a value of a Hash with a Symbol or String.

There you go. In order to load the file into our application, you must specify the lib folder in the list of Ruby on Rails \_autoload_s. To do this, add the following configuration to the `config/application.rb` file: lib/

```ruby
# ...
class Application < Rails::Application
# ...
  config.autoload_paths << Rails.root.join('lib')
 end
end
```

### Create User Model

Note: password field must be name `password_digest`

```
 rails g model user name:string email:string password_digest:string
```

Add this to the `app/model/user.rb` file,
this will hash the password on save

```
has_secure_password
```

```ruby
# Basic Migration template
class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :username
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end

```

### Sign Up

```
 rails g controller users index create show
```

```ruby
class UsersController < ApplicationController
 before_action :check_login, except: :create
 before_action :find_user, except: %i[create index]

 # GET /users
 def index
   @users = User.all
   render json: @users, status: :ok
 end

 # GET /users/{username}
 def show
   render json: @user, status: :ok
 end

 # POST /users
 def create
   @user = User.new(user_params)
   if @user.save
     render json: @user, status: :created
   else
     render json: { errors: @user.errors.full_messages },
            status: :unprocessable_entity
   end
 end

 # PUT /users/{username}
 def update
   unless @user.update(user_params)
     render json: { errors: @user.errors.full_messages },
            status: :unprocessable_entity
   end
 end

 # DELETE /users/{username}
 def destroy
   @user.destroy
 end

 private

 def find_user
   @user = User.find_by_username!(params[:_username])
   rescue ActiveRecord::RecordNotFound
     render json: { errors: 'User not found' }, status: :not_found
 end

 def user_params
   params.permit(
     :name, :email, :password, :password_confirmation
   )
 end
end

```

### Encode Token

#### Create and Authentication controller

This controller will manage login and if successful it will create a JSON Web Token

```terminal
 rails g controller authentication
```

```ruby
class AuthenticationController < ApplicationController
 before_action :authorize_request, except: :login

  # POST /auth/login
  def login
   #find user
    @user = User.find_by_email(params[:email])
    if @user&.authenticate(params[:password])

     token = JsonWebToken.encode(user_id: @user.id)
     time = Time.now + 24.hours.to_i

      render json: { token: token, exp: time.strftime("%m-%d-%Y %H:%M"), username: @user.username }, status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end

```

### Modules

Think of the module as a helper file, like in NodeJS, an exported method that can be imported(required) and used when needed.

```ruby
# create this file
# app/controllers/concerns/authenticable.rb
module Authenticable

 def current_user
  # if there is a current user return the user
  return @current_user if @current_user

  # check the request header to get the token
  # from Authorization
  header = request.headers['Authorization']
  header = header.split(' ').last if header

  begin
    # token decode
    @decoded = JsonWebToken.decode(header)
    # get user id from token
    @current_user = User.find(@decoded[:user_id])
    # if record not found return error
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: e.message, msg: 'record not found' }, status: :unauthorized
  # if record found and error with token return error
  rescue JWT::DecodeError => e
    render json: { errors: e.message, msg: 'Token Error: Check token' }, status: :unauthorized
  end
 end

 def check_login
  #make current_user global
  head :forbidden unless self.current_user
  end
end
```

```ruby
# To lock controller
# add to controller

 before_action :check_login
```

---

References

- API on Rails 6 by Alexandre Rousseau
