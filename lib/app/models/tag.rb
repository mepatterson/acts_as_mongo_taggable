class Tag
  include MongoMapper::Document
  key :user_id,         ObjectId, :required => true
  key :taggable_class,  String,   :required => true
  key :taggable_id,     ObjectId, :required => true
  key :word,            String,   :required => true
  
  ensure_index :user_id
  ensure_index :taggable_id
  ensure_index :taggable_class
  ensure_index :word
  
  belongs_to :user
    
  # == Various Class Methods
  
  # takes a string and produces an array of words from the db that are 'like' this one
  # great for those oh-so-fancy autocomplete/suggestion text fields
  def self.like(string, klass)
    collection.distinct(:word, {'word' => /^#{string}.+/, 'taggable_class' => klass.to_s})
  end
    
  # TO DO this can probably be rewritten to do limits and such in the query
  def self.all_with_counts(limit = nil, klass = nil)
    cond = klass ? {:taggable_class => klass.to_s} : nil
    tags = collection.group(['word'], cond, {'count' => 0}, "function(doc, prev) {prev.count += 1}")
    counts = tags.map{|t| [t['word'], t['count']]}
    set = counts.sort{|a,b| a[1] <=> b[1]}.reverse
    limit.nil? ? set : set[0,limit]
  end
  
  def self.top_25(klass = nil)
    all_with_counts(25, klass)
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

# 0.18.1 docs claim this method looks like this, but my gem didn't have the 'query' option
# so I'm adding it directly... should take this out later if the mongo ruby library is updated properly
module Mongo
  class Collection
  
    # dunno why this isn't the same in my 0.18.1 version of the gem as what the docs say
    def distinct(key, query=nil)
      raise MongoArgumentError unless [String, Symbol].include?(key.class)
      command = OrderedHash.new
      command[:distinct] = @name
      command[:key]      = key.to_s
      command[:query]    = query

      @db.command(command)["values"]
    end
      
  end
end
