puts File.dirname(__FILE__)
require 'yaml'
require File.dirname(__FILE__) + '/test_helper.rb' 
class MessageFlag
  @@flag=false
  def self.setflag
    @@flag=true
  end
  def self.flag
    @@flag
  end
end
class EstormMessageProcessor::Base
   def delegate_testdelegate(cmdhash)
     puts "teste delegate received #{cmdhash.inspect}"
     MessageFlag.setflag
       
   end
end

class EstormMessageProcessTest <  Minitest::Test

  def setup
    EstormMessageProcessor::Base.logger=Logger.new(STDERR) 
    @f=EstormMessageProcessor::Base.new
    @@temp=false
    puts "after setup"
  end
  
  def test_basic
    assert @f!=nil, "should be valid"
    assert !@@temp, "should be false"
  end
  
  def test_startup
    config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
    Thread.new {
    @f.start(config) }
    sleep(15)
    @f.tear_down_bunny 
    assert true,"should get here"
  end
  def test_1yaml
    puts "in yaml test"
    fred={'test' => 'fredtest'}
    yaml=fred.to_yaml
    assert yaml.include?('test'), "should have test in it"
    loaded=YAML.load(yaml)
    assert loaded['test']==fred['test'],"values should be smae"
  end
  def test_message
    assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
    config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
    Thread.new {
    @f.start(config) }
    sleep(20)
    puts "after start in test message"
    Thread.new {
      
      cmdhash={'command'=>'testdelegate', 'temp'=>'temp'}
       puts "----> to system [x] sending  #{cmdhash.inspect}"
      bunny=EstormMessageProcessor::Client.new
      bunny.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
       puts "after bunny send"
         }
    puts "after client in test message"
    sleep 5
    assert MessageFlag.flag==true, "should receive message and set temp #{MessageFlag.inspect}"
     @f.tear_down_bunny 
     
  end
 
  
 
 

end
