module Api
  module V1
    class HealthController < ApplicationController
      def check
        render json: {
          status: 'healthy',
          timestamp: Time.current.iso8601,
          uptime: Process.clock_gettime(Process::CLOCK_MONOTONIC),
          environment: Rails.env
        }, status: :ok
      end
    end
  end
end
