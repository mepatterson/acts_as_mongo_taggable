require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_mongo_taggable_on plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_mongo_taggable_on plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsMongoTaggableOn'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  GEM = "acts_as_mongo_taggable"
  AUTHOR = "Matt E. Patterson"
  EMAIL = "mpatterson@ngenera.com"
  SUMMARY = "A ruby gem for acts_as_taggable to mongo"
  HOMEPAGE = "http://github.com/mepatterson/acts_as_mongo_taggable"
  
  gem 'jeweler', '>= 1.0.0'
  require 'jeweler'
  
  Jeweler::Tasks.new do |s|
    s.name = GEM
    s.summary = SUMMARY
    s.email = EMAIL
    s.homepage = HOMEPAGE
    s.description = SUMMARY
    s.author = AUTHOR
    
    s.require_path = 'lib'
    s.files = %w(MIT-LICENSE README.textile Rakefile) + Dir.glob("{rails,lib,generators,spec}/**/*")
    
    # Runtime dependencies: When installing Formtastic these will be checked if they are installed.
    # Will be offered to install these if they are not already installed.
    s.add_dependency 'mongo_mapper', '>= 0.7.0'
    
    # Development dependencies. Not installed by default.
    # Install with: sudo gem install formtastic --development
    #s.add_development_dependency 'rspec-rails', '>= 1.2.6'
  end
  
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "[acts_as_mongo_taggable:] Jeweler - or one of its dependencies - is not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end