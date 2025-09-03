class Api::V1::RecipientsController < ApplicationController
    include JwtAuthenticatable
    include RateLimitable
    
    before_action :authenticate_user_from_token!
    after_action :add_rate_limit_headers

    # Custom rate limits for recipients endpoints
    def ip_rate_limit
      case action_name
      when 'index'
        1000 # 1000 requests per hour for listing
      when 'create'
        100 # 100 requests per hour for creating
      when 'update'
        200 # 200 requests per hour for updating
      else
        100 # Default
      end
    end

    def ip_rate_period
      1.hour
    end

    def user_rate_limit
      case action_name
      when 'index'
        2000 # 2000 requests per hour for listing
      when 'create'
        200 # 200 requests per hour for creating
      when 'update'
        500 # 500 requests per hour for updating
      else
        1000 # Default
      end
    end

    def user_rate_period
      1.hour
    end

    # GET /api/v1/recipients - Get paginated list of recipients
    def index
        @recipients = current_user.care_recipients
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 .per(params[:per_page] || 25)
        
        render json: {
            status: 'success',
            data: {
                recipients: @recipients,
                pagination: {
                    current_page: @recipients.current_page,
                    total_pages: @recipients.total_pages,
                    total_count: @recipients.total_count,
                    per_page: @recipients.limit_value,
                    next_page: @recipients.next_page,
                    prev_page: @recipients.prev_page
                }
            }
        }, status: :ok
    end

    def create
        @recipient = current_user.care_recipients.build(recipient_params)

        if @recipient.save
            render json: {
                status: 'success',
                message: 'Care recipient created successfully',
                data: @recipient
            }, status: :created
        else
            render json: {
                status: 'error',
                message: 'Failed to create care recipient',
                errors: @recipient.errors.full_messages
            }, status: :unprocessable_entity
        end
    end

    def update
        @recipient = current_user.care_recipients.find(params[:id])

        if @recipient.update(recipient_params)
            render json: {
                status: 'success',
                message: 'Care recipient updated successfully',
                data: @recipient
            }, status: :ok
        else
            render json: {
                status: 'error',
                message: 'Failed to update care recipient',
                errors: @recipient.errors.full_messages
            }, status: :unprocessable_entity
        end
    end
    
    private

    def recipient_params
        params.require(:recipient).permit(:name, :relationship, :insurance_info, conditions: [])
    end
end
