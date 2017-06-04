require 'rspec/core/shared_context'

module DummyAppDb
  extend RSpec::Core::SharedContext
  before do
    create_table
    add_models_with_files
  end

  def create_table
    sql =<<-SQL
      drop table if exists fake_model;
      create table fake_model ( file_id varchar(255));
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def add_models_with_files
    FakeModel.create(:file_id => '1234abc')
    FakeModel.create(:file_id => '4567def')
    FakeModel.create(:file_id => '8899bin')
  end
end
