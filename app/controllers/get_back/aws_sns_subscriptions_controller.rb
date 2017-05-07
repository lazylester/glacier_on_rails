module GetBack
  class AwsSnsSubscriptionsController < ApplicationController
    skip_before_action :verify_authenticity_token, :check_permissions, :only=>[:create]
    def create
      logger.info request.headers.env
      logger.info request.raw_post
      if request.headers["x-amz-sns-message-type"] == "SubscriptionConfirmation"
        subscribe_url = JSON.parse(request.raw_post)["SubscribeURL"]
        raise MessageWasNotAuthentic unless subscribe_url =~ /^https.*amazonaws\.com\//
        HTTParty.get sns.subscribe_url
        head :ok and return
      end
    end
  end
end
