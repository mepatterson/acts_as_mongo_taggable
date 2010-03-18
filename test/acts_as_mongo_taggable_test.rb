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
  
  test "widget tagged with the same word multiple times should not have dupes in tag_words" do
    multi_tag(@widget)
    assert_equal 3, @widget.tag_words.size
    @widget.delete_tags_by_user(@m_tagger_1)
    assert_equal 2, @widget.tag_words.size
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
  
  test "search and find all widgets containing a specified tag" do
    num_found = Widget.all_with_tag('vampires').size
    assert_equal 0, num_found
    @widget.tag("vampires", @tagger)
    num_found = Widget.all_with_tag('vampires').size
    assert_equal 1, num_found
    dongle_owner = create_user "dongle_owner"
    dongle = dongle_owner.dongles.create({:name => "Test Dongle"})
    multi_tag(dongle)
    num_found = Widget.all_with_tag('vampires').size
    # should only be 1 because we're only searching on Widgets!
    assert_equal 1, num_found
  end
  
  test "find first widget that matches specified tag" do
    @widget.tag("vampires", @tagger)
    dongle_owner = create_user "dongle_owner"
    dongle = dongle_owner.dongles.create({:name => "Test Dongle"})
    # should only be 1 because we're only searching on Widgets!
    assert_equal 1, Widget.all_with_tag('vampires').size
    assert_equal @widget, Widget.first_with_tag('vampires')
  end
  
  test "all_with_tag and first_with_tag are case-insensitive" do
    @widget.tag("VaMpiReS", @tagger)
    @widget.tag("VAMPIRES", @tagger)
    assert_equal @widget, Widget.first_with_tag("VampireS")
    assert_equal 1, Widget.all_with_tag("VampireS").size
  end
  
  test "case-sensitive mode" do
    @widget.tag("VaMpiReS", @tagger, {:case_sensitive => true})
    assert_equal 0, Widget.all_with_tag("vampires").size
    assert_equal 0, Widget.all_with_tag("VaMpiReS").size
    assert_equal 0, Widget.all_with_tag("vampires", {:case_sensitive => true}).size
    assert_equal 1, Widget.all_with_tag("VaMpiReS", {:case_sensitive => true}).size
  end
  
  test "we get an empty array if we ask for all tags with counts and there are none" do
    assert_equal 0, Tag.count
    assert_equal [], Widget.all_tags_with_counts
  end
  
  test "we can build an array of tags and counts across an entire tagged object space" do
    multi_tag(@widget)
    dongle_owner = create_user "dongle_owner"
    dongle = dongle_owner.dongles.create({:name => "Test Dongle"})
    dongle.tag("werewolves", @m_tagger_1)
    dongle.tag("werewolves", @m_tagger_2)
    assert_equal [["werewolves", 3], ["frankenstein", 2], ["vampires", 1]], Widget.all_tags_with_counts
    assert_equal [["werewolves", 2]], Dongle.all_tags_with_counts
  end
  
  test "most_tagged_with returns the proper widget" do
    widget_one = @owner.widgets.create({:name => "Test Widget One"})
    widget_two = @owner.widgets.create({:name => "Test Widget Two"})
    widget_three = @owner.widgets.create({:name => "Test Widget Three"})
    load_multiple_taggers
    #widget one -- worst
    widget_one.tag("werewolves", @m_tagger_1)
    #widget two -- best
    multi_tag(widget_two)
    #widget three -- middle child
    widget_three.tag("werewolves", @m_tagger_1)
    widget_three.tag("werewolves", @m_tagger_2)
    # now, did it work?
    assert_equal widget_two, Widget.most_tagged_with('werewolves')
  end
    
  test "tag is created when project tagged" do
    assert_equal 0, @widget.tags.size
    @widget.tag("vampires", @tagger)
    assert_equal 1, @widget.tags.size
  end
  
  test "tagged_by_user? returns true when this object tagged by user" do
    assert ! @widget.tagged_by_user?(@tagger)
    @widget.tag("vampires", @tagger)
    assert @widget.tagged_by_user?(@tagger)
  end
  
  test "tagged_by_user? returns false when this object not tagged but some other object is" do
    dongle_owner = create_user "dongle_owner"
    dongle = dongle_owner.dongles.create({:name => "Test Dongle"})
    dongle.tag("vampires", @tagger)
    assert ! @widget.tagged_by_user?(@tagger)    
  end
  
  test "tag object can be retrieved after project tagged" do
    assert_equal 0, @widget.tags.size
    @widget.tag("werewolves", @tagger)
    assert_equal "werewolves", @widget.tags.first
  end

  test "widget returns correct array with multiple tags with 1 count each" do
    %w(vampires werewolves frankenstein).each {|word| @widget.tag(word, @tagger)}
    assert_equal 3, @widget.tags.size
    ["vampires", "werewolves", "frankenstein"].each { |t| assert @widget.tags.include?(t) }
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
    assert_equal 6, @widget.model_tags.inject(0){|r, tag| r + tag.tagging_count}

    @widget.delete_tags_by_user(@m_tagger_1)
    assert_equal 2, @widget.tags.size
    assert_equal 3, @widget.model_tags.inject(0){|r, tag| r + tag.tagging_count}
    
    @widget.delete_tags_by_user(@m_tagger_2)
    assert_equal 1, @widget.tags.size   
    assert_equal 1, @widget.model_tags.inject(0){|r, tag| r + tag.tagging_count}
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
