class Tagging
  include MongoMapper::EmbeddedDocument
  
  belongs_to :user #, :required => true, :index => true
  belongs_to :taggable, :polymorphic => true
end