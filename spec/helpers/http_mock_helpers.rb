require 'rspec/core/shared_context'

module HttpMockHelpers
  extend RSpec::Core::SharedContext
  before do
    get_vault_list_request
    create_vault_request
    upload_archive_post
    initiate_retrieve_job
    fetch_archive_retrieval_job_output
    fetch_file_archive_retrieval_job_output
    fetch_db_archive_retrieval_job_output
    delete_archive
  end

  def stub_errored_response_for_initiate_retrieval
    response_body = ' { "Type" : "Notification", "MessageId" : "b221d7d9-73c3-5e6d-9caf-8649cb198736", "TopicArn" : "arn:aws:sns:us-east-1:918359762546:retrieve_archive", "Message" : "{\"Action\":\"ArchiveRetrieval\",\"ArchiveId\":\"_vs0qWot3GIg7I3bsBomHTheu73qNkCW28_B1hKjXhvOMR5vh7rGQs4Ra_UEYdXCA1N6-F8aF-lN7SMqLl6pRyy7HX6mA0DPwhpXSPoOA7FixG1roXtx7O7QN8gFiz_GAyMR8OeqpQ\",\"ArchiveSHA256TreeHash\":\"0c47aee75a9587d83648fc1ea05d52646a67f704fbd23952c134d89776eccbe6\",\"ArchiveSizeInBytes\":285544,\"Completed\":true,\"CompletionDate\":\"2017-05-13T07:32:42.098Z\",\"CreationDate\":\"2017-05-13T03:40:19.264Z\",\"InventoryRetrievalParameters\":null,\"InventorySizeInBytes\":null,\"JobDescription\":\"put anything here\",\"JobId\":\"krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK\",\"RetrievalByteRange\":\"0-285543\",\"SHA256TreeHash\":\"0c47aee75a9587d83648fc1ea05d52646a67f704fbd23952c134d89776eccbe6\",\"SNSTopic\":\"arn:aws:sns:us-east-1:918359762546:retrieve_archive\",\"StatusCode\":\"Succeeded\",\"StatusMessage\":\"Succeeded\",\"Tier\":\"Standard\",\"VaultARN\":\"arn:aws:glacier:us-east-1:918359762546:vaults/demo\"}" }'
    success = {status: 200, body: response_body, headers: {'x-amz-job-id': 'the archive retrieval job id'}}
    fail = {status: 400}
    stub_request(:post, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/jobs").
         with(body: "{\"Type\":\"archive-retrieval\",\"ArchiveId\":\"random_archive_id\",\"Description\":\"put anything here\",\"SNSTopic\":\"arn:aws:sns:us-east-1:abc123:retrieve_archive\",\"Tier\":\"Standard\"}").
         to_return(success, success, success, fail)
  end

  #get vault list
  def get_vault_list_request
    stub_request(:get, "https://glacier.us-east-1.amazonaws.com/-/vaults").
       to_return(:status => 200, :body =>"{ \"VaultList\": [{ \"CreationDate\": \"2015-04-06 21:23:45 UTC\", \"LastInventoryDate\": \"2015-04-07 00:26:19 UTC\", \"NumberOfArchives\": 1, \"SizeInBytes\": 3178496, \"VaultArn\": \"arn:aws:glacier:us-west-2:0123456789012:vaults/my-vault\", \"VaultName\": \"my-vault\" }]}")
  end

  def create_vault_request
    stub_request(:put, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ").
       to_return(status: 200, body: "", headers: {})
  end

  # see http://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-post.html
  #
  # HTTP/1.1 201 Created
  # x-amzn-RequestId: x-amzn-RequestId
  # Date: Date
  # x-amz-sha256-tree-hash: ChecksumComputedByAmazonGlacier
  # Location: Location
  # x-amz-archive-id: ArchiveId
  def upload_archive_post
    upload_response_body = "{
      \"archiveId\": \"kKB7ymWJVpPSwhGP6ycSOAekp9ZYe_--zM_mw6k76ZFGEIWQX-ybtRDvc2VkPSDtfKmQrj0IRQLSGsNuDp-AJVlu2ccmDSyDUmZwKbwbpAdGATGDiB3hHO0bjbGehXTcApVud_wyDw\",
      \"checksum\": \"969fb39823836d81f0cc028195fcdbcbbe76cdde932d4646fa7de5f21e18aa67\",
      \"location\": \"/0123456789012/vaults/my-vault/archives/kKB7ymWJVpPSwhGP6ycSOAekp9ZYe_--zM_mw6k76ZFGEIWQX-ybtRDvc2VkPSDtfKmQrj0IRQLSGsNuDp-AJVlu2ccmDSyDUmZwKbwbpAdGATGDiB3hHO0bjbGehXTcApVud_wyDw\"
    }"

    response_headers = {'x-amz-archive-id':'random_archive_id', 'x-amz-sha256-tree-hash':'bar', 'Location':'bosh'}

    stub_request(:post, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/archives").
      to_return(status: 201, body:upload_response_body, headers: response_headers)
  end

  # HTTP/1.1 400 Bad Request
  # x-amzn-RequestId: AAABaZ9N92Iiyv4N7sru3ABEpSQkuFtmH3NP6aAC51ixfjg
  # Content-Type: application/json
  # Content-Length: 141
  # Date: Sun, 23 Nov 2014 12:00:00 GMT
  # {
  #   "code": "InvalidParameterValueException",
  #   "message": "The job status code is not valid: finished",
  #   "type: "Client"
  # }
  def upload_archive_post_with_error_response
    body = '{ "code": "InvalidParameterValueException",
              "message": "Invalid Content-Length: 0",
              "type": "Client" }'
    stub_request(:post, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/archives").
      to_return(status: 400, body: body)
  end

  # response headers (see http://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html)
  # HTTP/1.1 202 Accepted
  # x-amzn-RequestId: x-amzn-RequestId
  # Date: Date
  # Location: Location
  # x-amz-job-id: JobId
  #
  # response body
  #  {
  #    "Type" : "Notification",
  #    "MessageId" : "b221d7d9-73c3-5e6d-9caf-8649cb198736",
  #    "TopicArn" : "arn:aws:sns:us-east-1:918359762546:retrieve_archive",
  #    "Message" : "{\"Action\":\"ArchiveRetrieval\",\"ArchiveId\":\"_vs0qWot3GIg7I3bsBomHTheu73qNkCW28_B1hKjXhvOMR5vh7rGQs4Ra_UEYdXCA1N6-F8aF-lN7SMqLl6pRyy7HX6mA0DPwhpXSPoOA7FixG1roXtx7O7QN8gFiz_GAyMR8OeqpQ\",\"ArchiveSHA256TreeHash\":\"0c47aee75a9587d83648fc1ea05d52646a67f704fbd23952c134d89776eccbe6\",\"ArchiveSizeInBytes\":285544,\"Completed\":true,\"CompletionDate\":\"2017-05-13T07:32:42.098Z\",\"CreationDate\":\"2017-05-13T03:40:19.264Z\",\"InventoryRetrievalParameters\":null,\"InventorySizeInBytes\":null,\"JobDescription\":\"put anything here\",\"JobId\":\"krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK\",\"RetrievalByteRange\":\"0-285543\",\"SHA256TreeHash\":\"0c47aee75a9587d83648fc1ea05d52646a67f704fbd23952c134d89776eccbe6\",\"SNSTopic\":\"arn:aws:sns:us-east-1:918359762546:retrieve_archive\",\"StatusCode\":\"Succeeded\",\"StatusMessage\":\"Succeeded\",\"Tier\":\"Standard\",\"VaultARN\":\"arn:aws:glacier:us-east-1:918359762546:vaults/demo\"}",
  #  }
  def initiate_retrieve_job
    response_body = ' { "Type" : "Notification", "MessageId" : "b221d7d9-73c3-5e6d-9caf-8649cb198736", "TopicArn" : "arn:aws:sns:us-east-1:918359762546:retrieve_archive", "Message" : "{\"Action\":\"ArchiveRetrieval\",\"ArchiveId\":\"_vs0qWot3GIg7I3bsBomHTheu73qNkCW28_B1hKjXhvOMR5vh7rGQs4Ra_UEYdXCA1N6-F8aF-lN7SMqLl6pRyy7HX6mA0DPwhpXSPoOA7FixG1roXtx7O7QN8gFiz_GAyMR8OeqpQ\",\"ArchiveSHA256TreeHash\":\"0c47aee75a9587d83648fc1ea05d52646a67f704fbd23952c134d89776eccbe6\",\"ArchiveSizeInBytes\":285544,\"Completed\":true,\"CompletionDate\":\"2017-05-13T07:32:42.098Z\",\"CreationDate\":\"2017-05-13T03:40:19.264Z\",\"InventoryRetrievalParameters\":null,\"InventorySizeInBytes\":null,\"JobDescription\":\"put anything here\",\"JobId\":\"krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK\",\"RetrievalByteRange\":\"0-285543\",\"SHA256TreeHash\":\"0c47aee75a9587d83648fc1ea05d52646a67f704fbd23952c134d89776eccbe6\",\"SNSTopic\":\"arn:aws:sns:us-east-1:918359762546:retrieve_archive\",\"StatusCode\":\"Succeeded\",\"StatusMessage\":\"Succeeded\",\"Tier\":\"Standard\",\"VaultARN\":\"arn:aws:glacier:us-east-1:918359762546:vaults/demo\"}" }'
    stub_request(:post, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/jobs").
         with(body: "{\"Type\":\"archive-retrieval\",\"ArchiveId\":\"random_archive_id\",\"Description\":\"put anything here\",\"SNSTopic\":\"arn:aws:sns:us-east-1:abc123:retrieve_archive\",\"Tier\":\"Standard\"}").
         to_return(status: 200, body: response_body, headers: {'x-amz-job-id': 'the archive retrieval job id'})
  end

  def receive_notification
    data = { "Type" => "Notification",
             "TopicArn" => "arn:aws:sns:us-east-1:918359762546:retrieve_archive",
             "Message" => "{\"JobId\":\"the archive retrieval job id\"}" }.to_json

    post :create, :body => data
  end

  def fetch_archive_retrieval_job_output
    stub_request(:get, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/jobs/validJobId/output")
  end

  def fetch_file_archive_retrieval_job_output
    stub_request(:get, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/jobs/validFileRetrievalJobId/output")
  end

  def fetch_db_archive_retrieval_job_output
    @db_contents = ApplicationDatabase.new.contents
    stub_request(:get, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/jobs/validDbRetrievalJobId/output").
      to_return(status: 200, body: @db_contents)
  end

  def fetch_expired_archive
    response_body = '{ "code": "ResourceNotFoundException",
                       "message": "The job ID was not found: fSv4ZKei5cI0yIcfan24WnJbtz_oYv4PsPjGQspjteDfOG3zIxh5ZcQVbhn0tF6-s4IfYeo6xXiPzMUBGJY4NfzxHp4q",
                       "type": "Client" }'

    stub_request(:get, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/jobs/expiredJobId/output").
      to_return(status: 404, body: response_body)
  end

  # http://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html
  # DELETE /AccountId/vaults/VaultName/archives/ArchiveID HTTP/1.1
  # Host: glacier.Region.amazonaws.com
  # x-amz-Date: Date
  # Authorization: SignatureValue
  # x-amz-glacier-version: 2012-06-01
  def delete_archive
    stub_request(:delete, "https://glacier.us-east-1.amazonaws.com/-/vaults/OZ/archives/random_archive_id").
      to_return(:status => 204)
  end
end
