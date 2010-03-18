require 'rubygems'
require 'active_support'
require 'active_support/test_case'
require 'test/unit'

ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'
env_rb = File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

if File.exists? env_rb
  require env_rb
else
  require 'mongo_mapper'
  require File.dirname(__FILE__) + '/../lib/acts_as_mongo_taggable'
  config = {'test' => {'database' => 'aamt-test'}}
  MongoMapper.setup(config, 'test')
end

class ActiveSupport::TestCase
  # Drop all columns after each test case.
  def teardown
    MongoMapper.database.collections.each do |coll|
      coll.drop  
    end
  end
 
  # Make sure that each test case has a teardown
  # method to clear the db after each test.
  def inherited(base)
    base.define_method teardown do 
      super
    end
  end
end

# kinda weird, but we have to do this so we can ignore the app's User class and use our own for testing
Object.send(:remove_const, :User) if Object.const_defined?(:User)

class User
  include MongoMapper::Document
  key :name, String
  has_many :widgets
  has_many :dongles
end

class Widget
  include MongoMapper::Document  
  include ActsAsMongoTaggable 

  belongs_to :user
  
  key :user_id, ObjectId
  key :name, String
end

class Dongle
  include MongoMapper::Document  
  include ActsAsMongoTaggable 

  belongs_to :user
  
  key :user_id, ObjectId
  key :name, String
end