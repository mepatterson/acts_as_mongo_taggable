ActsAsMongoTaggable
===================

Inspired by mbleigh's "acts_as_taggable_on," this tagging plugin works with MongoDB+MongoMapper.

Intends to be super-performant by taking advantage of the benefits of document-driven db denormalization.

Requirements
------------

- MongoDB
- MongoMapper gem
- Expects you to have a User model that includes MongoMapper::Document

Installation
------------

Install the plugin:
        
    ./script/plugin install git://github.com/mepatterson/acts_as_mongo_taggable.git

Add this line to the Rails model class that you want to make taggable:

    include ActsAsMongoTaggable

Yeah, that's it.

Usage
-----

    class User
      include MongoMapper::Document
    end

    class Widget
      include MongoMapper::Document
      include ActsAsMongoTaggable
    end

To rate it:

    widget.tag(word_or_words, user)

- word_or_words can be a string, a string of comma-delimited words, or an array
- user is the User who is tagging this widget

Basic search:

    Widget.find_with_tag('vampires')

... will return the first Widget object that has been tagged with that phrase

    Widget.find_all_with_tag('vampires')

... will return an array of Widget objects, all of which have been tagged with that phrase

    Widget.most_tagged_with('vampires')
    
... will return the Widget object that has been tagged the most times with that phrase

Making tag clouds:

    Widget.all_tags_with_counts
    
... will return a nice array of arrays, a la [["rails", 8],["ruby", 12], ["php", 6], ["java", 2]]
Use this to make yourself a tag cloud for now. (maybe I'll implement a tag cloud view helper someday.)

Statistics on Tags:

    Tag.top_25

... returns the top 25 most used tags across all taggable object classes in the system

    Tag.top_25("Widget")

... returns the top 25 most used tags for Widget objects


Future
------
- Performance improvements as I come across the need


Thanks To...
------------
- John Nunemaker and the rest of the folks on the MongoMapper Google Group
- Kyle Banker and his excellent blog posts on grouping and aggregation
- The MongoDB peoples and the MongoDB Google Group
- mbleigh for the acts_as_taggable_on plugin for ActiveRecord

Copyright (c) 2009 [M. E. Patterson], released under the MIT license