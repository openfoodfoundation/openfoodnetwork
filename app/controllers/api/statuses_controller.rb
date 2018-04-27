module Api
  class StatusesController < ::BaseController
    respond_to :json

    def job_queue
      render json: {alive: job_queue_alive?}
    end


    private

    def job_queue_alive?
      Spree::Config.last_job_queue_heartbeat_at.present? &&
        Time.parse(Spree::Config.last_job_queue_heartbeat_at) > 6.minutes.ago
    end
  end
end
