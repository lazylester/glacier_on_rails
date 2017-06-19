#Rails.application.routes.draw do
GetBack::Engine.routes.draw do
  post :aws_subscription_notify, :to => 'aws_sns_subscriptions#create'
  post :aws_archive_retrieval_job_create, :to => 'aws_archive_retrieval_jobs#create'
  post :aws_fetch_archive, :to => 'application_data_backups#fetch'
  delete :aws_destroy_archive, :to => 'application_data_backups#destroy'
  post :aws_restore_archive, :to => 'application_data_backups#restore'
end
