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


Future
------
- (very soon!) Add search functions so you can quickly dig up all Widgets with tag "foo"
- (very soon!) Add some stats methods to the Tag class, so we can make tag clouds and such
- Performance improvements as I come across the need


Thanks To...
------------
- John Nunemaker and the rest of the folks on the MongoMapper Google Group
- The MongoDB peoples and the MongoDB Google Group
- mbleigh for the acts_as_taggable_on plugin for ActiveRecord

Copyright (c) 2009 [M. E. Patterson], released under the MIT license