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
   def delegate_testdelegate2(cmdhash)
     puts "test delegate2 received #{cmdhash.inspect}"
   end
   def delegate_testdelegate(cmdhash)
     puts "test delegate received #{cmdhash.inspect}"
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
    puts "test startup"
    config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
    Thread.new {
    @f.start(config) }
    sleep 6
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
    puts "test message"
    assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
    config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
    Thread.new {
    @f.start(config) }
    sleep 6
    puts "after start in test message"
    Thread.new {
      
      cmdhash={'command'=>'testdelegate', 'temp'=>'temp'}
       puts "----> to system [x] sending  #{cmdhash.inspect}"
      bunny=EstormMessageProcessor::Client.new
      bunny.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
       puts "after bunny send"
         }
    puts "after client in test message"
    sleep 3
    assert MessageFlag.flag==true, "should receive message and set temp #{MessageFlag.inspect}"
     @f.tear_down_bunny 
     
  end
  def test_client
       cmdhash={'command'=>'testdelegate2', 'promotion'=>2.to_s}
       puts "----> to system [x] sending  #{cmdhash.inspect}"
       config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
       bunny=EstormMessageProcessor::Client.new
       assert bunny!=nil, "bunny should not be nil"
       bunny.bunny_send_no_close(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
       assert bunny.connection!=nil, "should be ok"
       res=bunny.connection.close
       assert res=='closed'.to_sym, "should be closed: #{res.inspect}"
  end
 
  
 
 

end
