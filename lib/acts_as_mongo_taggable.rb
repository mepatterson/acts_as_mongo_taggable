module ActsAsMongoTaggable
  module ClassMethods
    
  end
  
  module InstanceMethods
    
    def delete_all_tags
      Tag.destroy_all(:id => taggings)
      taggings = []
      save!
    end
    
    def _tags
      Tag.all(:id => taggings)
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
    
    def tag_ids_except_user(user)
      tags_with_user_ids.reject{|e| e[1] == user.id}.map{|m| m[0]}      
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
    Tag.destroy_all(:id => tag_ids_by_user(user))
    taggings = tag_ids_except_user(user)
    save!
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
  def tag!(word_or_words, user = nil)
    arr_of_words(word_or_words).each do |word|
      raise StandardError if Tag.exists?(_tag_conditions(user, word))
      t = Tag.create(_tag_conditions(user, word))
      taggings << t.id
    end
    save!
    tags
  end
  
  # tags, but silently ignores if user tries to multi-tag with same word
  def tag(word_or_words, user = nil)
    arr_of_words(word_or_words).each do |word|
      unless Tag.exists?(_tag_conditions(user, word))
        t = Tag.create(_tag_conditions(user, word))
        taggings << t.id 
      end
    end
    save!
    tags
  end
  
  # returns the Rating object found if user has rated this project, else returns nil
  def tagged_by_user?(user)
    ! tags.blank?
  end
  
  def self.included(receiver)
    receiver.class_eval do
      # anything here will be eval'ed on the taggable object class (i.e. Project)
      key :taggings, Array, :index => true # array of Tag ids
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