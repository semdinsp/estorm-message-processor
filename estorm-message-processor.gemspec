Gem::Specification.new do |s|
  s.name        = "estorm-message-processor"
  s.version     = "0.1.2"
  s.author      = "Scott Sproule"
  s.email       = "scott.sproule@ficonab.com"
  s.homepage    = "http://github.com/semdinsp/estorm-message-processor"
  s.summary     = "Using a AMQP to process a queue. Primarily support for scripting"
  s.description = "a gem to help rails app process AMQP queues for background jobs"
  s.executables = ['']    #should be "name.rb"
  s.files        = Dir["{lib,test}/**/*"] +Dir["bin/*.rb"] + Dir["[A-Z]*"] # + ["init.rb"]
  s.require_path = "lib"
  s.license = 'MIT'
  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
end
