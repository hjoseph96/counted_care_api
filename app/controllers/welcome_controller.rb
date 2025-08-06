class WelcomeController < ApplicationController
    def index
        render json: { message: 'Welcome to the Counted Care API' }
    end
end