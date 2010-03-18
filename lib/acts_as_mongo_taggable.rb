module ActsAsMongoTaggable
  module ClassMethods
    def all_tags_with_counts
      Tag.most_tagged(self).map{|tag| [tag.word, tag.count_for(self)]}
    end
    
    # returns the _first_ widget with this tag, a la ActiveRecord find()
    # note: case-insensitive unless you specify otherwise with :case_sensitive=>true
    def first_with_tag(phrase, opts={})
      lo = opts.clone
      case_sensitive = lo.delete :case_sensitive
      phrase = phrase.downcase unless case_sensitive
      first(lo.merge(:tag_words => phrase))
    end
    
    
    def all_with_tag(phrase, opts={})
      lo = opts.clone
      case_sensitive = lo.delete :case_sensitive
      phrase = phrase.downcase unless case_sensitive
      all(lo.merge(:tag_words => phrase))
    end
    
    def most_tagged_with(phrase, opts={})
      lo = opts.clone
      case_sensitive = lo.delete :case_sensitive
      phrase = phrase.downcase unless case_sensitive
      
      #Doesn't work :(
      #first(lo.merge('model_tags.word' => phrase, :order => 'model_tags.tagging_count desc'))
      
      all_with_tag(phrase, lo).sort do |a, b|
        b.model_tag(phrase, opts).tagging_count <=> a.model_tag(phrase, opts).tagging_count
      end.first
    end
    
    def top_25_tags
      Tag.top_25(self)
    end
  end
  
  module InstanceMethods
    
    def delete_all_tags
      Tag.find(tag_ids).each do |tag|
        model_taggings = tag.taggings.select{|tagging| tagging.taggable_type == self.class.name && tagging.taggable_id == self.id}
        model_taggings.each{|tagging| tag.taggings.delete tagging}
        tag.save_or_destroy
      end
      update_attributes({ :model_tags => [], :tag_words => [] })
    end
    
    def _tags
      Tag.find(:all, tag_ids)
    end
    
    # returns array of tags and counts: 
    #   [["matt", 3], ["bob", 2], ["bill", 1], ["joe", 1], ["frank", 1]]
    def tags_with_counts
      counts = model_tags.map{|tag| [tag.word, tag.tagging_count]}
      counts.sort{|a, b| b[1] <=> a[1]}
    end
    
    # returns an array of ids and user_ids
    def tags_with_user_ids
      model_tags.inject([]) do |arr, tag|
        tag.user_ids.each{|user_id| arr << [tag.id, user_id]}
        arr
      end
    end
    
    def tag_words_by_user(user)
      tags_by_user(user).map(&:word)
    end
    
    def tags_by_user(user)
      model_tags.select{|tag| tag.user_ids.include? user.id}
    end
    
    # returns only the tag words, sorted by frequency; optionally can be limited
    def tags(limit=nil)
      array = tags_with_counts
      limit ||= array.size
      array[0,limit].map{|t| t[0]}
    end
    
    def model_tag(phrase, opts = {})
      phrase = phrase.downcase unless opts[:case_sensitive]
      model_tags.detect{|tag| tag.word == phrase}
    end
    
    def tag_ids
      model_tags.map(&:tag_id)
    end
  end
  
  def delete_tags_by_user(user)
    return false unless user
    return 0 if model_tags.blank?
    user_tags = tags_by_user(user)
    
    Tag.find(user_tags.map(&:tag_id)).each do |tag|
      user_taggings = tag.taggings.select{|tagging| tagging.user_id == user.id && tagging.taggable_type == self.class.name && tagging.taggable_id == self.id}
      user_taggings.each{|tagging| tag.taggings.delete tagging}
      tag.save_or_destroy
    end
    
    user_tags.each do |tag| 
      tag.users.delete user
      destroy_if_empty(tag)
    end
    save
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
  
  # returns my current tag word list; raises exception if user tries to multi-tag with same word
  def tag!(word_or_words, user)
    arr_of_words(word_or_words).each do |word|
      raise StandardError if tag_words_by_user(user).include?(word)
      
      #First add Tag/Tagging
      t = Tag.first(:word => word) || Tag.create!(:word => word)
      t.taggings << Tagging.new(:user => user, :taggable => self)
      t.save!
      
      #Now add ModelTag/User/tag_word
      model_tag = model_tags.detect{|tag| tag.word == word}
      unless model_tag
        model_tag = ModelTag.new(:word => word, :tag => t)
        self.model_tags << model_tag
        self.tag_words << word
      end
      model_tag.users << user
    end
    save!
    tags
  end
  
  # tags, but silently ignores if user tries to multi-tag with same word
  # NOTE: automatically downcases each word unless you manually specify :case_sensitive=>true
  def tag(word_or_words, user, opts={})
    arr_of_words(word_or_words).each do |word|
      word = word.downcase unless opts[:case_sensitive] == true
      unless tag_words_by_user(user).include?(word)
        #First add Tag/Tagging
        t = Tag.first(:word => word) || Tag.create!(:word => word)
        t.taggings << Tagging.new(:user => user, :taggable => self)
        t.save
      
        #Now add ModelTag/User/tag_word
        model_tag = model_tags.detect{|tag| tag.word == word}
        unless model_tag
          model_tag = ModelTag.new(:word => word, :tag => t)
          self.model_tags << model_tag
          self.tag_words << word
        end
        model_tag.users << user
      end
    end
    save
    tags
  end
  
  # returns the Rating object found if user has rated this project, else returns nil
  def tagged_by_user?(user)
    !(model_tags.detect{|tag| tag.user_ids.include?(user.id)}.nil?)
  end
  
  def self.included(receiver)
    receiver.class_eval do
      key :tag_words, Array, :index => true
      many :model_tags
      
      ensure_index 'model_tags.word'
      ensure_index 'model_tags.tagging_count'
    end
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
    
    Tag.register_taggable_type receiver
  end
  
private
  def destroy_if_empty(tag)
    if tag.user_ids.empty?
      tag_words.delete(tag.word)
      model_tags.delete tag
    end
  end

end

%w{ models observers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end

