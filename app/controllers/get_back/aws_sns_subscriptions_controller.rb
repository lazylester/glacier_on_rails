require 'httparty'

module GetBack
  class AwsSnsSubscriptionsController < ApplicationController
    skip_before_action :verify_authenticity_token, :check_permissions, :only=>[:create]
    def create
      if request.headers["x-amz-sns-message-type"] == "SubscriptionConfirmation"
        subscribe_url = JSON.parse(request.raw_post)["SubscribeURL"]
        raise MessageWasNotAuthentic unless subscribe_url =~ /^https.*amazonaws\.com\//
        HTTParty.get subscribe_url
        head :ok and return
      else
        puts request.raw_post
        GlacierArchive.first.update_attribute(:notification, JSON.parse(request.raw_post))
        head :ok and return
      end
    end
  end
end
