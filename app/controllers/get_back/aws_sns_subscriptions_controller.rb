require 'httparty'

module GetBack
  class AwsSnsSubscriptionsController < ApplicationController
    class MessageWasNotAuthentic < StandardError; end

    skip_before_action :verify_authenticity_token, :check_permissions, :only=>[:create]
    def create
      if request.headers["x-amz-sns-message-type"] == "SubscriptionConfirmation" # AWS sends a post to confirm subscription to notifications
        subscribe_url = JSON.parse(request.raw_post)["SubscribeURL"]
        raise MessageWasNotAuthentic unless subscribe_url =~ /^https.*amazonaws\.com\//
        HTTParty.get subscribe_url # confirms subscription
        head :ok
      else # this is the notification from AWS Glacier that the retrieval job is completed
        File.open(Rails.root.join('tmp','notification.txt'),'w') do |file|
          file.write(request.raw_post)
        end
        # the notification that the retrieve_archive job has completed
        message = JSON.parse(request.raw_post)["Message"]
        job_id = JSON.parse(message)["JobId"]
        glacier_archive = GlacierArchive.find_by(:archive_retrieval_job_id => job_id)
        glacier_archive.update_attributes(:archive_retrieval_job_id => nil, :notification => request.raw_post) if glacier_archive
        head :ok
      end
    end
  end
end
