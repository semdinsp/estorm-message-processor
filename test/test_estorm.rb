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
   def delegate_testdelegate2(cmdhash)
     msg= "DELEGATE CALLED: test delegate2 received #{cmdhash.inspect}"
     logger.info msg
     puts msg
     MessageFlag.increment
   end
   def delegate_testdelegate(cmdhash)
     msg= "DELEGATE CALLED: test delegate received #{cmdhash.inspect}"
     logger.info msg
     puts msg
     MessageFlag.setflag
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
  
  def test_delegate
    puts "test delegate"
    config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testdelegatequeue', :blocking => true,:consumer_name => "test consumer delete startup consumer"}
      cmdhash={'command'=>'testdelegate', 'temp'=>'test_delegate'}
      t1 =Thread.new {
         @f.start(config) }
         sleep 1
    assert @f.consumer!=nil, "consumer should not be nil"
    @f.consumer.send("delegate_testdelegate",cmdhash)
   assert MessageFlag.flag==true, "should receive message and set temp #{MessageFlag.flag}"
   sleep 3
  end
  def test_basic_startup
    puts "test basic startup"
    config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testbasicqueue', :blocking => false,:consumer_name => "test basic non blocking consumer"}
    
    t1 =Thread.new {
      @f.start(config) }
    sleep 2
   # @f.tear_down_bunny     #NEED TO FIGURE OUT HOW TO STOP
    assert true,"should get here test_startup"
  end
  def test_startup
    puts "test startup"
    config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testqueue', :blocking => true,:consumer_name => "test startup consumer"}
    t1 =Thread.new {
       @f.start(config) }
    sleep 2
    @f.tear_down_bunny    
    sleep 1
    t1.exit
    assert true,"should get here test_startup"
    sleep 3
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
    puts "test  message"
    assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
    config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testsevalMessages', :blocking => true, :consumer_name => "test message consumer"}
    t1=Thread.new {
    @f.start(config) 
    puts " should not get here this thread about to exit in tes_messag"}
    sleep 1
    t2= Thread.new {
      
      cmdhash={'command'=>'testdelegate', 'temp'=>'temp'}
       puts "----> to system [x] sending  #{cmdhash.inspect}"
      bunny=EstormMessageProcessor::Client.new
      bunny.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
       puts "after bunny send test_message"
         }
    puts "after client in test message"
    sleep 5
    
      assert MessageFlag.flag==true, "should receive message and set temp #{MessageFlag.flag}"
   
     sleep 1
     t1.exit
     t2.exit
     sleep 1
  end
  def test_several_message
     puts "test several  message"
     assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
     config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testqueuesMessage', :blocking => true, :consumer_name => "test message consumer"}
     t1=Thread.new {
     @f.start(config) 
     puts " should not get here this thread about to exit in tes_messag"}
     sleep 1
     t2= Thread.new {

       cmdhash={'command'=>'testdelegate2', 'temp'=>'serveral messages'}
        puts "----> to system [x] sending  #{cmdhash.inspect}"
        1.upto(7) { |i| 
         bunnysender=EstormMessageProcessor::Client.new
         cmdhash['temp']="mesage #{i}"
         bunnysender.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
          puts "after bunny send test_message"
            }
          }
     puts "after client in test message"
     sleep 15
  #    @f.tear_down_bunny 
      sleep 1
       assert MessageFlag.testval==7, "should receive 7 message and set temp #{MessageFlag.testval}"
     

      t1.exit
      t2.exit
      sleep 3
   end
   def test_several_message_again
       puts "test several  message"
       assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
       config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testqueuesMessage again', :blocking => true, :consumer_name => "test message consumer"}
       t1=Thread.new {
       @f.start(config) 
       puts " should not get here this thread about to exit in tes_messag"}
       sleep 1
       t2= Thread.new {

         cmdhash={'command'=>'testdelegate2', 'temp'=>'serveral messages'}
          puts "----> to system [x] sending  #{cmdhash.inspect}"
          1.upto(7) { |i| 
           bunnysender=EstormMessageProcessor::Client.new
           cmdhash['temp']="mesage #{i}"
           bunnysender.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
            puts "after bunny send test_message"
              }
            }
       puts "after client in test message"
       sleep 15
    #    @f.tear_down_bunny 
        sleep 1
         assert MessageFlag.testval==7, "should receive 7 message and set temp #{MessageFlag.testval}"
         count=4
          t2= Thread.new {

            cmdhash={'command'=>'testdelegate2', 'temp'=>'serveral messages'}
             puts "----> to system [x] sending  #{cmdhash.inspect}"
             1.upto(count) { |i| 
              bunnysender=EstormMessageProcessor::Client.new
              cmdhash['temp']="mesage #{i}"
              bunnysender.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
               puts "after bunny send test_message"
                 }
               }
        sleep 10
          assert MessageFlag.testval==7+count, "should receive #{7+count} message and set temp #{MessageFlag.testval}"
        t1.exit
        t2.exit
        sleep 3
     end
  def test_client
       puts "test client  -- basic"
       cmdhash={'command'=>'testdelegate2', 'promotion'=>2.to_s}
       puts "----> to system [x] sending  #{cmdhash.inspect}"
       config={:url => 'fakeurl',:connecturlflag=> false,:timeout => 0,:queuename => 'testqueue7', :blocking => true, :consumer_name => "test consumer"}
       bunny=EstormMessageProcessor::Client.new
       assert bunny!=nil, "bunny should not be nil"
       bunny.setup_bunny(config[:url],config[:connnecturlflag])
       bunny.bunny_send_no_close(config[:queuename],cmdhash)
       assert bunny.connection!=nil, "should be ok"
       res=bunny.connection.close
       assert res=='closed'.to_sym, "should be closed: #{res.inspect}"
       sleep 3
  end
 
  
  #def test_one_shotclient
  #  assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
  #  config={:url => 'fakeurl',:exit_when_empty => true,:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
  #   Thread.new {
      
   #   cmdhash={'command'=>'testdelegate2', 'temp'=>'temp'}
  #     puts "----> to system [x] sending 5 messages  #{cmdhash.inspect}"
  #     1.upto(5)  {|i|   # send five messages
  #    bunny=EstormMessageProcessor::Client.new
  #    bunny.bunny_send(config[:url],config[:connnecturlflag],config[:queuename],cmdhash)
  #     puts "after bunny send" }
  #       }
  #  sleep 2
    
  #  @f.start(config) 
  #  sleep 10
    
  #  assert MessageFlag.testval==5, "should receive 5 message and set  #{MessageFlag.inspect}"
  #   @f.tear_down_bunny 
     
  #end
 
  
 
 

end
