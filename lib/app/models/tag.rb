class Tag
  include MongoMapper::Document
  key :user_id,         ObjectId, :required => true
  key :taggable_class,  String,   :required => true
  key :taggable_id,     ObjectId, :required => true
  key :word,            String,   :required => true
  
  ensure_index :user_id
  ensure_index :taggable_id
  
  belongs_to :user
  
  # == Various Instance Methods   
  def find_tagged_document
    klass = taggable_class.constantize
    klass.find(taggable_id.to_s)
  end
  
  def find_tagged_document!
    doc = find_tagged_document
    raise "Associated document not found" if doc.nil?
    doc
  end
end