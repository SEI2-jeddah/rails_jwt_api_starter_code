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