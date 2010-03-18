class ModelTag
  include MongoMapper::EmbeddedDocument
  
  key :word,            String, :required => true
  key :tagging_count,   Integer
  key :user_ids,        Array
  
  def users
    UserProxy.new(self)
  end
  
  belongs_to :tag
  
  before_save :set_tagging_count
  
  def save_or_destroy
    user_ids.empty? ? destroy : save
  end
  
private
  def set_tagging_count
    self.tagging_count = user_ids.count
  end
  
  class UserProxy
    attr_accessor :model_tag
    
    def initialize(model_tag)
      @model_tag = model_tag
    end
    
    def to_a
      fetch_all.to_a
    end
    
    def count
      model_tag.user_ids.size
    end
    
    def all(opts = {})
      fetch_all
    end
    
    def each(&block)
      fetch_all.each {|user| yield user}
    end
    
    def find(id)
      return nil unless model_tag.user_ids.include?(id)
      User.find(id)
    end
    
    def first(opts = {})
      return @first ||= User.find(model_tag.user_ids.first) if opts.empty?
      User.first(opts.merge(:_id.in => model_tag.user_ids))
    end
    
    def last(opts = {})
      return @last ||= User.find(model_tag.user_ids.last) if opts.empty?
      User.last(opts.merge(:_id.in => model_tag.user_ids))
    end
    
    alias :size :count
    
    def << (user)
      model_tag.user_ids << user.id
      model_tag.send(:set_tagging_count)
    end
    
    def delete(user)
      model_tag.user_ids.delete user.id
      model_tag.send(:set_tagging_count)
    end
    
    def inspect
      all.inspect
    end
    
  private
    def fetch_all
      @fetch ||= User.find(model_tag.user_ids)
    end
  end
end