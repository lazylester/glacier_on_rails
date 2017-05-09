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

#   {"Type"=>"Notification",
#    "MessageId"=>"836c0df7-d679-579b-8d3e-5c7e82980dbc",
#    "TopicArn"=>"arn:aws:sns:us-east-1:918359762546:retrieve_archive",
#    "Subject"=>"duude!",
#    "Message"=>"have a fabulous day",
#    "Timestamp"=>"2017-05-07T17:00:17.982Z",
#    "SignatureVersion"=>"1",
#    "Signature"=>"CMS3hpQzji9ON+rOAnxMj7W0qdDSjIBeHgQIwRWqjy620g0rAgDasOz/n6Kne+dR9/TbXss9f2UO6JgY3xSTbbz1+KMBqnp88MmGRA9US8ymhHL2DySXlTUqosAztHAooXQiRebnd8zBgdN/aEpN6NucBZ+bZeG2cQ818nmO29+Bo0eJ0RbXPXhlT6lMnDo4Byn5PXDcOh0GqhAPhjK24yqG8oewyTowZ6Hgzyx5KMo6NbWL1vbTyc0Ld9Sj2zuMv49R2rchmX4o8MsAHfot9i6RwtDGwNf2k3N/DDyYNzVNNkzDqWQtbkhS9nnLPTtVEyDYNnbGZKNuxvBQsNBSvg==",
#    "SigningCertURL"=>"https://sns.us-east-1.amazonaws.com/SimpleNotificationService-b95095beb82e8f6a046b3aafc7f4149a.pem",
#    "UnsubscribeURL"=>"https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:918359762546:retrieve_archive:fb8925ed-cc03-4f60-8301-27a4d5ad36d8"}
