class Api::V1::RecipientsController < ApplicationController
    def create
        @recipient = CareRecipient.new(recipient_params)

        if @recipient.save
            render json: @recipient, status: :created
        else
            render json: @recipient.errors, status: :unprocessable_entity
        end
    end

    def update
        @recipient = CareRecipient.find(params[:id])

        if @recipient.update(recipient_params)
            render json: @recipient, status: :ok
        else
            render json: @recipient.errors, status: :unprocessable_entity
        end
    end
    
    private

    def recipient_params
        params.require(:recipient).permit(:name, :relationship, :insurance_info, conditions: [])
    end
end
