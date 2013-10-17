puts File.dirname(__FILE__)
require 'yaml'
require File.dirname(__FILE__) + '/test_helper.rb' 
class EstormMessageProcessor::Consumer
   attr_reader :conflag
   def delegate_testdelegate(cmdhash)
     msg= "DELEGATE CALLED: test delegate received #{cmdhash.inspect}"
     logger.info msg
     puts msg
    @conflag=true
   end
end

class EstormConsumerProcessTest <  Minitest::Test

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
  def test_cancel
    puts "testing consumer"
    config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testconsumerqueue', :blocking => true, :timeout => 0, :consumer_name => "test consumer"}
    @f.setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
    assert @f.channel.open? , "channel should be open"
    @consumer = EstormMessageProcessor::Consumer.new(@f.channel, @f.queue)
     @consumer.logger=@f.logger
    assert !@consumer.cancelled?, "should not be cancelled"
    tag=@consumer.consumer_tag
    ack=@consumer.cancel
    puts "ack string is #{ack}"
    assert ack.consumer_tag==tag, "should  be cancelled #{ack}  #{ack.consumer_tag} #{tag}"
  end 
  def test_consumer_increment
     puts "testing consumer"
     config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testconsumerqueue',:timeout => 0, :blocking => true, :consumer_name => "test consumer"}
     @f.setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
     @consumer = EstormMessageProcessor::Consumer.new(@f.channel, @f.queue)
     @consumer.logger=@f.logger
     assert @consumer.count!=nil, "should not be nil"
      assert @consumer.count==0, "should  be 0"
       assert @consumer.increment==1, "should  be 1 but is #{@consumer.count}"
        assert @consumer.increment
        assert @consumer.count==2, "should  be 2 but is #{@consumer.count}"
   end
    def test_qos
      puts "test startup"
      config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testdelegatequeue', :timeout => 0,:blocking => true,:consumer_name => "test consumer delete startup consumer"}
        cmdhash={'command'=>'testdelegate', 'temp'=>'test_delegate'}
         @f.setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
         res=@f.channel.prefetch(1)
     assert res.is_a?(AMQ::Protocol::Basic::QosOk), "should set prefetch #{res} methods "
    end
   def test_delegate
     puts "test startup"
     config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testdelegatequeue', :timeout => 0,:blocking => true,:consumer_name => "test consumer delete startup consumer"}
       cmdhash={'command'=>'testdelegate', 'temp'=>'test_delegate'}
        @f.setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
         @consumer = EstormMessageProcessor::Consumer.new(@f.channel, @f.queue)
         @consumer.logger=@f.logger
         assert !@consumer.cancelled?, "should not be cancelled"
     @consumer.send("delegate_testdelegate",cmdhash)
     sleep 1
    assert @consumer.conflag==true, "should receive message and set temp #{@consumer.inspect}"
   end
  def test_consumer
    puts "testing consumer"
    config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testconsumerqueue2', :timeout => 0, :blocking => true, :consumer_name => "test consumer"}
    @f.setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
    @consumer = EstormMessageProcessor::Consumer.new(@f.channel, @f.queue)
    @consumer.logger=@f.logger
    assert !@consumer.cancelled?, "should not be cancelled"
    res=""
    t=Thread.new {
    @f.queue.subscribe_with(@consumer)
    sleep 1
    x = @f.channel.default_exchange
    # Publish messages
    x.publish('Hello', :routing_key =>config[:queuename])
    res=@f.queue.delete  
    puts "res is #{res}"
    }
    sleep 3
    assert @consumer.cancelled?, "should  be cancelled #{res} "
    t.exit
  end
  def test_queueu_stats
     puts "testing consumer"
      config={:url => 'fakeurl',:connecturlflag=> false,:queuename => 'testconsumerqueue', :timeout => 0,:blocking => true, :consumer_name => "test consumer2"}
      @f.setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
      @consumer = EstormMessageProcessor::Consumer.new(@f.channel, @f.queue)
      @consumer.logger=@f.logger
      assert @consumer.consumer_tag=config[:consumer_name]
      mc,cc=@consumer.queue_statistics
      assert mc!=nil, "mc should have vlue"
      assert cc!=nil, "concsumer count should have value"
      assert true, "should get here without a problem"
  end
  
  #def test_one_shotclient
  #  assert MessageFlag.flag==false, "should be flase #{MessageFlag.inspect}"
  #  config={:url => 'fakeurl',:exit_when_empty => true,:connecturlflag=> false,:queuename => 'testqueue', :blocking => true}
  #  Thread.new {
      
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