class Tag
  include MongoMapper::Document
  key :user_id,         ObjectId, :required => true
  key :taggable_class,  String,   :required => true
  key :taggable_id,     ObjectId, :required => true
  key :word,            String,   :required => true
  
  ensure_index :user_id
  ensure_index :taggable_id
  ensure_index :word
  
  belongs_to :user
  
  # this will be helpful for a tag cloud of the most common tags
  @@top_25 = nil
  
  after_save :update_top_25
  after_destroy :update_top_25
  
  def update_top_25
    @@top_25 = Tag.all_with_counts(25)
  end
  
  # == Various Class Methods
  
  # takes a string and produces an array of words from the db that are 'like' this one
  # great for those oh-so-fancy autocomplete/suggestion text fields
  def self.like(string)
    collection.distinct(:word, {'word' => /^#{string}.+/})
  end
    
  # TO DO this can probably be rewritten to do limits and such in the query
  def self.all_with_counts(limit = nil)
    tags = @coll.group(['word'], nil, {'count' => 0}, "function(doc, prev) {prev.count += 1}")
    counts = tags.map{|t| [t['word'], t['count']]}
    set = counts.sort{|a,b| a[1] <=> b[1]}.reverse
    limit.nil? ? set : set[0,limit]
  end
  
  def self.top_25
    @@top_25 ||= all_with_counts(25)
  end
  
  
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

# not really sure why MM's ensure_index() calls above don't work for this plugin, but I was having trouble, so...
MongoMapper.database['tags'].create_index("word")
MongoMapper.database['tags'].create_index("user_id")
MongoMapper.database['tags'].create_index("taggable_id")