class Api::V1::ReceipientsController < ApplicationController
    def create
        @recipient = Recipient.new(recipient_params)

        if @recipient.save
            render json: @recipient, status: :created
        else
            render json: @recipient.errors, status: :unprocessable_entity
        end
    end
    
    private

    def recipient_params
        params.require(:recipient).permit(:caregiver_id, :name, :relationship, conditions: [], :insurance_info)
    end
end
