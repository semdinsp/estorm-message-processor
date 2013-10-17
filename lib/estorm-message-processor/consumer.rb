require 'rubygems'
require 'bunny'
require 'yaml'

module EstormMessageProcessor
  class Consumer  < Bunny::Consumer
    attr_accessor :logger
    def cancelled?
      @cancelled
    end
    def count
        @mycount=0  if @mycount==nil
        @mycount
    end
    @exit_flag=false
    def target(count,flag)
      puts "target is #{count} flag is #{flag}"
      @exit_flag=flag
      @exit_count=count-1
    end
    def increment
       @mycount=self.count+1
       @cancelled=true if @exit_flag && @exit_count < @mycount
       @mycount
    end

    def handle_cancellation(_)
      msg="consumer cancellation queue called"
      @logger.info msg
      @cancelled = true
    end
    # process message
    def process_messages(delivery_info,metadata,body)
       begin
         cmdhash=YAML.load(body)
         delegatestring="delegate_#{cmdhash['command']}"
         # create procedures named delegate_command accepting cmdhash
         msg = "-----> [gem estorm message processor:  consumer] Received from App #{body} calling delegate #{delegatestring} count: #{self.count} "
         @logger.info msg
         self.send(delegatestring,cmdhash)
         # self.send(delegatestring,cmdhash)
         #load the promotion and process through data
         self.increment
       rescue  Exception => e    # add could not convert integer
         msg= "[gem estorm message processor] bunny exception #{e.message} found #{e.inspect} #{e.backtrace}..."  #THIS NEEDS WORK!
         @logger.info msg

        end
     end
    # get the queue statistics and log it.
    def queue_statistics
      msg_count=0
      begin
      msg_count =@queue.message_count
      consumer_count =@queue.consumer_count
      msg = "queue status for queue [#{@queue.name}] message count: #{msg_count} consumers: #{consumer_count}"
      @logger.info msg if @logger!=nil
      rescue  Exception => e
        msg = "exception in queue statistics #{e.inspect}"
        @logger.info msg  if @logger!=nil
      end
      [msg_count, consumer_count]
     end
  end
end