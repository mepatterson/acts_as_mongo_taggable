class Tag
  include MongoMapper::Document
  key :word,            String,   :required => true, :index => true
  key :taggings_count,   Integer, :index => true
  
  many :taggings do
    def << (tagging)
      super << tagging
      tagging._parent_document.send(:increment_counts, tagging)
    end
    
    def delete(tagging)
      target.delete tagging
      tagging._parent_document.send(:decrement_counts, tagging)
    end
  end
  
  ensure_index 'taggings.user_id'
  ensure_index 'taggings.taggable_type'
  ensure_index 'taggings.taggable_id'
  
  before_save :set_tagging_counts
  
  def self.register_taggable_type(type)
    key taggings_count_key_for(type), Integer, :index => true
  end
    
  # == Various Class Methods
  
  # takes a string and produces an array of words from the db that are 'like' this one
  # great for those oh-so-fancy autocomplete/suggestion text fields
  def self.like(string, klass = nil)
    opts = {:word => /^#{string}/}
    opts['taggings.taggable_type'] = klass.to_s if klass
    all(opts)
  end
  
  def self.all_for_class(klass, opts = {})
    all(opts.merge('taggings.taggable_type' => klass.to_s))
  end
  
  def self.most_tagged(klass = nil, opts = {})
    order = klass ?  "#{taggings_count_key_for(klass)} desc" : 'taggings_count desc'
    lo = opts.merge(:order => order)
    lo['taggings.taggable_type'] = klass.to_s if klass
    all(lo)
  end
  
  def self.top_25(klass = nil)
    most_tagged(klass, :limit => 25)
  end
  
  def count_for(klass = nil)
    klass ? send(taggings_count_key_for(klass)) : taggings_count
  end
  
  #Called when removing taggings.  If no taggings left, destroy, otherwise save
  def save_or_destroy
    taggings.empty? ? destroy : save
  end
  
private
  def set_tagging_counts
    self.taggings_count = self.taggings.size
    
    count_hash = self.taggings.inject({}) do |hash, tagging|
      key = taggings_count_key_for(tagging.taggable_type)
      hash[key] ||= 0
      hash[key] += 1
      hash
    end
    count_hash.each{|key, count| self.send("#{key}=", count)}
  end

  def increment_counts(tagging)
    safe_increment_count(:taggings_count)
    safe_increment_count(taggings_count_key_for(tagging.taggable_type))
  end
  
  def decrement_counts(tagging)
    safe_decrement_count(:taggings_count)
    safe_decrement_count(taggings_count_key_for(tagging.taggable_type))
  end
  
  def taggings_count_key_for(type)
    Tag.taggings_count_key_for(type)
  end
  
  def safe_increment_count(key)
    val = self.send(key) || 0
    self.send("#{key}=", val + 1)
  end
  
  def safe_decrement_count(key)
    self.send("#{key}=", self.send("#{key}") - 1) if self.send("#{key}")
  end
  
  def self.taggings_count_key_for(type)
    type = type.name if type.is_a? Class
    :"#{type.underscore}_taggings_count"
  end
end
