module ActsAsMongoTaggable
  module ClassMethods
    
    
    # cond = klass ? {:taggable_class => klass.to_s} : nil
    # tags = collection.group(['word'], cond, {'count' => 0}, "function(doc, prev) {prev.count += 1}")
    # counts = tags.map{|t| [t['word'], t['count']]}
    # set = counts.sort{|a,b| a[1] <=> b[1]}.reverse
    # limit.nil? ? set : set[0,limit]
    
    def sorted_tag_counts(tags)
      counts = tags.map{|t| [t['word'], t['count'].to_i]}
      counts.sort{|a,b| a[1] <=> b[1]}.reverse
    end
    
    def all_tags_with_counts
      counts = Hash.new(0)
      tags = Tag.collection.group(['word'], 
              {:taggable_class => self.to_s}, 
              {'count' => 0}, 
              "function(doc, prev) {prev.count += 1}",
              true)
      sorted_tag_counts(tags)
    end
    
    # returns the _first_ widget with this tag, a la ActiveRecord find()
    # note: case-insensitive unless you specify otherwise with :case_sensitive=>true
    def find_with_tag(phrase, opts={})
      phrase = phrase.downcase unless opts[:case_sensitive] == true
      first(:tag_words => phrase)
    end
    
    
    def find_all_with_tag(phrase, opts={})
      phrase = phrase.downcase unless opts[:case_sensitive] == true
      all(:tag_words => phrase)
    end
    
    def most_tagged_with(phrase, opts={})
      phrase = phrase.downcase unless opts[:case_sensitive] == true
      tags = Tag.all({:select => 'taggable_id', :taggable_class => self.to_s, :word => phrase})
      widget_ids = tags.collect{|t| t.taggable_id}
      return [] if widget_ids.empty?
      counts = Hash.new(0)
      widget_ids.each{|id| counts[id] += 1}
      id = counts.sort{|a,b| a[1] <=> b[1]}.reverse.first[0]
      find(id)
    end
    
  end
  
  module InstanceMethods
    
    def delete_all_tags
      Tag.destroy_all(:id => taggings)
      update_attributes({ :taggings => [] })
    end
    
    def _tags
      Tag.find(:all, taggings)
    end
    
    # returns array of tags and counts: 
    #   [["matt", 3], ["bob", 2], ["bill", 1], ["joe", 1], ["frank", 1]]
    def tags_with_counts
      counts = Hash.new(0)
      Tag.all(:id => taggings, :select => 'word').collect(&:word).each{|val|counts[val]+=1}
      counts.sort{|a,b| a[1] <=> b[1]}.reverse
    end
    
    # returns an array of ids and user_ids
    def tags_with_user_ids
      _tags.collect{|t| [t.id, t.user_id] }
    end
    
    def tag_ids_by_user(user)
      tags_with_user_ids.select{|e| e[1] == user.id}.map{|m| m[0]}
    end
    
    def tag_words_by_user(user)
      Tag.all(:id => tag_ids_by_user(user)).map(&:word)
    end
    
    # returns only the tag words, sorted by frequency; optionally can be limited
    def tags(limit=nil)
      array = tags_with_counts
      limit ||= array.size
      array[0,limit].map{|t| t[0]}
    end
  end
  
  def delete_tags_by_user(user)
    return false unless user
    return 0 if tags.blank?
    user_taggings = tag_ids_by_user(user)
    Tag.destroy_all(:id => user_taggings)
    taggings.delete_if{|t| user_taggings.include?(t) }
    update_attributes({:taggings => taggings, :tag_words => Tag.find(:all, taggings).collect{|t| t.word}.uniq})
    reload
  end
  
  def arr_of_words(words)
    raise "Passed an invalid data type to tag()" unless words.is_a?(String) || words.is_a?(Array)
    if words.is_a?(String)
      words.squish.split(',').map{|w| w.squish}
    else
      words.map{|w| w.squish}
    end
  end
  
  
  def _tag_conditions(user, word)
    { :user_id => user.id, 
      :taggable_id => self.id,
      :taggable_class => self.class.to_s,
      :word => word 
    }
  end
  
  # returns my current tag word list; raises exception if user tries to multi-tag with same word
  def tag!(word_or_words, user)
    arr_of_words(word_or_words).each do |word|
      raise StandardError if Tag.exists?(_tag_conditions(user, word))
      t = Tag.create(_tag_conditions(user, word))
      taggings << t.id
      tag_words << word unless tag_words.include?(word)
    end
    save
    tags
  end
  
  # tags, but silently ignores if user tries to multi-tag with same word
  # NOTE: automatically downcases each word unless you manually specify :case_sensitive=>true
  def tag(word_or_words, user, opts={})
    arr_of_words(word_or_words).each do |word|
      word = word.downcase unless opts[:case_sensitive] == true
      unless Tag.exists?(_tag_conditions(user, word))
        t = Tag.create(_tag_conditions(user, word))
        taggings << t.id
        tag_words << word unless tag_words.include?(word)
      end
    end
    save
    tags
  end
  
  # returns the Rating object found if user has rated this project, else returns nil
  def tagged_by_user?(user)
    Tag.all({:id => taggings, :user_id => user.id}).count > 0
  end
  
  def self.included(receiver)
    receiver.class_eval do
      key :taggings, Array, :index => true # array of Tag ids
      key :tag_words, Array, :index => true
    end
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end

end

%w{ models observers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end

