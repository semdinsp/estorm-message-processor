puts File.dirname(__FILE__)
require 'yaml'
require File.dirname(__FILE__) + '/test_helper.rb' 
class MessageFlag
 
  def self.reset
    puts "reset called"
     @@flag=false
     @@test=0
  end
  def self.setflag
     puts "set flag called"
    @@flag=true
  end
  def self.flag
   
    @@flag
  end
  def self.testval
    @@test
  end
  def self.increment
    puts "increment called"
    @@test=MessageFlag.testval+1
  end
end
class EstormMessageProcessor::Consumer
   
   def delegate_testdelegate3(cmdhash)
     msg= "DELEGATE CALLED: test delegate 3 received #{cmdhash.inspect}"
     logger.info msg
     puts msg
     MessageFlag.increment
   end
end

class EstormMessageProcessTest <  Minitest::Test

  def setup
    EstormMessageProcessor::Base.logger=Logger.new(STDERR) 
    @f=EstormMessageProcessor::Base.new
    @@temp=false
    MessageFlag.reset
    puts "after setup"
  end
  
  def test_basic
    assert @f!=nil, "should be valid"
    assert !@@temp, "should be false"
    assert !MessageFlag.flag, "should be false"
    MessageFlag.setflag
     assert MessageFlag.flag, "should be true"
     assert MessageFlag.testval==0, "should be 0"
       MessageFlag.increment
        assert MessageFlag.flag, "should be false"
  end
  def test_processor_exits_after_queue_empty
     puts "test several  message"
     assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
     config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testqueueMessageExit', :blocking => false, :consumer_name => "test exit consumer", :exit_when_empty => true}
     # PRELOAD THE QUEUE WITH MESSAGES
     t2= Thread.new {

       cmdhash={'command'=>'testdelegate3', 'temp'=>'serveral messages'}
        puts "----> to system [x] sending  #{cmdhash.inspect}"
        1.upto(7) { |i| 
         bunnysender=EstormMessageProcessor::Client.new
         cmdhash['temp']="mesage #{i}"
         bunnysender.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
          puts "after bunny send test_message: #{cmdhash['temp']}"
            }
          }
     puts "after client in test message"
     t1=Thread.new {
      @f.start(config) 
      puts " should  get here this thread about to exit in tes_messag"}
      assert t1.alive? , "should be alive"
      sleep 10
       assert !t1.alive? , "should be dead after processing messages"
     sleep 1
       
       assert MessageFlag.testval==7, "should receive 7 message and set temp #{MessageFlag.testval}"

   end
end