require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsMongoTaggableTest < ActiveSupport::TestCase
  
  def create_user(name)
    u = User.create({:name => name})
    puts u.errors unless u.valid?
    u
  end
  
  def load_multiple_taggers
    @m_tagger_1 = create_user "m_tagger_1"
    @m_tagger_2 = create_user "m_tagger_2"
    @m_tagger_3 = create_user "m_tagger_3"
  end
  
  def multi_tag(obj)
    load_multiple_taggers
    obj.tag('frankenstein', @m_tagger_1)
    obj.tag('frankenstein', @m_tagger_2)
    obj.tag('vampires', @m_tagger_1)
    obj.tag('werewolves', @m_tagger_1)
    obj.tag('werewolves', @m_tagger_2)
    obj.tag('werewolves', @m_tagger_3)
  end  
    
  def setup
    @owner = create_user 'owner'
    @tagger = create_user 'tagger'
    @widget = @owner.widgets.create({:name => "Test Widget"})
  end
  
  test "ensure we can actually tag two different object types without collisions" do
    dongle_owner = create_user "dongle_owner"
    dongle = dongle_owner.dongles.create({:name => "Test Dongle"})
    # tag the widget
    multi_tag(@widget)
    assert_equal 3, @widget.tags.size
    assert_equal 0, dongle.tags.size
    # tag the dongle
    multi_tag(dongle)
    assert_equal 3, @widget.tags.size
    assert_equal 3, dongle.tags.size
    # delete from the widget
    @widget.delete_all_tags
    assert_equal 0, @widget.tags.size
    assert_equal 3, dongle.tags.size
    # delete from the dongle
    dongle.delete_all_tags
    assert_equal 0, @widget.tags.size
    assert_equal 0, dongle.tags.size
  end
    
  test "tag is created when project tagged" do
    assert_equal 0, @widget.tags.size
    @widget.tag("vampires", @tagger)
    assert_equal 1, @widget.tags.size
  end
  
  test "tagged_by_user? returns correct value" do
    assert ! @widget.tagged_by_user?(@tagger)
    @widget.tag("vampires", @tagger)
    assert @widget.tagged_by_user?(@tagger)
  end
  
  test "tag object can be retrieved after project tagged" do
    assert_equal 0, @widget.tags.size
    @widget.tag("werewolves", @tagger)
    assert_equal "werewolves", @widget.tags.first
  end

  test "widget returns correct array with multiple tags with 1 count each" do
    %w(vampires werewolves frankenstein).each {|word| @widget.tag(word, @tagger)}
    assert_equal 3, @widget.tags.size
    assert_equal ["vampires", "werewolves", "frankenstein"], @widget.tags
  end

  test "widget returns correct array with multiple tags with varying counts" do
    multi_tag(@widget)
    assert_equal 3, @widget.tags.size
    assert_equal ["werewolves", "frankenstein", "vampires"], @widget.tags
  end
  
  test "tags_with_counts returns the right tags and counts" do
    expected = [["werewolves", 3], ["frankenstein", 2], ["vampires", 1]]
    multi_tag(@widget)
    assert_equal expected, @widget.tags_with_counts
  end
  
  test "same user cannot multi-tag with same word using tag!()" do
    assert_raise StandardError do
      3.times { @widget.tag!('frankenstein', @tagger) }
    end
  end
  
  test "delete only tags by certain users" do
    multi_tag(@widget)
    assert_equal 3, @widget.tags.size
    @widget.delete_tags_by_user(@m_tagger_1)
    assert_equal 2, @widget.tags.size
    @widget.delete_tags_by_user(@m_tagger_2)
    assert_equal 1, @widget.tags.size    
  end
  
  test "silently ignore multi-tag by single user with same word using tag()" do
    3.times { @widget.tag('frankenstein', @tagger) }
    assert_equal 1, @widget.tags.size
  end
  
  test "widget with multiple tags can be cleared" do
    %w(vampires werewolves frankenstein).each {|word| @widget.tag(word, @tagger)}
    assert_equal 3, @widget.tags.size
    @widget.delete_all_tags
    assert_equal 0, @widget.tags.size
  end
  
  
  
end
