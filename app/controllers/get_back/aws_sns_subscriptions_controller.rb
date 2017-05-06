module GetBack
  class AwsSnsSubscriptionsController < ApplicationController
    skip_before_action :check_permissions, :only=>[:create]
    def create
      logger.info request.headers
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
