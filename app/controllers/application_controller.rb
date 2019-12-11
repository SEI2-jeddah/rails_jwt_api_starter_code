class ApplicationController < ActionController::API
 include Authenticable

def not_found
  render json: { error: 'not_found' }
end

end
