require 'rubygems'
require 'bunny'
require 'yaml'

module EstormMessageProcessor
  class Base  
       attr_reader :queue, :channel, :consumer, :conn
       # MT id counter.
       @@mt_id = 0
       def Base.logger
         @@logger
       end

       def Base.logger=(logger)
         @@logger = logger
       end

       def logger
         @@logger
       end

       

       def logger
         EstormMessageProcessor::Base.logger
       end

       def setup_bunny_communications(url,flag,queuename)
         @client=EstormMessageProcessor::Client.new
         @conn,@channel=@client.setup_bunny(url,flag)
         raise "connection problem with #{@client.inspect}" if @conn==nil
         @channel   = @conn.create_channel
         @queue   = @channel.queue(queuename)
         msg= "set up active MQ on #{queuename}"
         logger.info msg
       end

       def tear_down_bunny
          if @conn!=nil && @conn.open? && @channel!=nil && @channel.open?
            sleep 1
            @consumer.cancel if @consumer!=nil && !@consumer.cancelled?
            sleep 1
          #  @queue.unsubscribe
          #  @conn.close if @channel != nil && @channel.open?
          #  sleep 0.5
          end
          msg= "closing bunny"
          logger.info msg
       end
       
       def queue_mgmt(config)
          msg= "[*] Waiting for messages in #{@queue.name}.  blocking is #{config[:blocking]}"
          logger.info msg
          count=0
        #  @channel.prefetch(1)   # set quality of service to only delivery one message at a time....
          msg_count,consumer_count = @consumer.queue_statistics  # just to get the stats before entering hte queue
       #  @queue.subscribe(:block => config[:blocking]) do |delivery_info, properties, body|
         @consumer.target(msg_count,config[:exit_when_done]) if config[:exit_when_done]
         @consumer.on_delivery() do |delivery_info, metadata, payload|
            @consumer.process_messages(delivery_info,metadata,payload)
       #     @consumer.channel.acknowledge(delivery_info.delivery_tag, false) if @consumer.channel!=nil && @consumer.channel.open?
            msg=   "ON DELIVERY: #{@consumer.count}: messages processed"
            logger.info msg
            @channel.close if @consumer.cancelled? 
               # ack the message to get the next message
            #msg_count,consumer_count = @consumer.queue_statistics  # POSSIBLE RACE CONDITION
           # @consumer.cancel if msg_count==0 && config[:exit_when_empty]
           end
       end
       def queue_creation(config)
          setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
          #@consumer=EstormMessageProcessor::Consumer.new(@channel, @queue, config[:consumer_name], true, false, config)
          @consumer=EstormMessageProcessor::Consumer.new(@channel, @queue)

          @consumer.logger=logger
          raise "consumer creation problem" if @consumer==nil
          msg_count,consumer_count =@consumer.queue_statistics
          queue_mgmt(config)
       end
       
       def start(config)
         msg= "Connecting to bunny environment #{config.inspect}"
         logger.info msg
         queue_creation(config)
         # the block flag shuts down the thread. the timeout values says whether to unsubscriber
         #need to set ack to true to manage the qos parameter
        # retval= @queue.subscribe_with(@consumer,:ack => true, :block => config[:blocking], :timeout => config[:timeout])
        #  retval= @queue.subscribe_with(@consumer,:ack => true, :block => config[:blocking])
        retval= @queue.subscribe_with(@consumer, :block => config[:blocking])
        # loop do   
             #should loop forever if blocking... otherwise needs  a loop
         #   sleep 1
        #  end
         msg= "Ending======about to tear_down_bunny [retval: #{retval}]...."
         logger.info msg
         tear_down_bunny
           
       end
       
    
     


     end
end    #Module