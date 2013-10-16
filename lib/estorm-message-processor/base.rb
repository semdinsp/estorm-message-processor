require 'rubygems'
require 'bunny'
require 'yaml'

module EstormMessageProcessor
  class Base  
       attr_reader :queue, :channel, :consumer
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
          if @conn!=nil && @conn.open?
            @consumer.cancel if @consumer!=nil && !@consumer.cancelled?
            sleep 0.5
            @conn.close if @channel != nil && @channel.open?
          end
          msg= "closing bunny"
          logger.info msg
       end
       def queue_mgmt(config)
          msg= "[*] Waiting for messages in #{@queue.name}.  blocking is #{config[:blocking]}"
          logger.info msg
          count=0
       #  @queue.subscribe(:block => config[:blocking]) do |delivery_info, properties, body|
         @consumer.on_delivery() do |delivery_info, metadata, payload|
            @consumer.process_messages(delivery_info,metadata,payload)
            msg=   "ON DELIVERY: #{@consumer.count}: messages processed"
            logger.info msg
            msg_count,consumer_count = @consumer.queue_statistics
            @consumer.cancel if msg_count==0 && config[:exit_when_empty]
           end
       end
       
       
       def start(config)
         msg= "Connecting to bunny environment #{config.inspect}"
         logger.info msg
         config[:exit_when_empty]=false if config[:exit_when_empty]==nil
         setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
         @consumer=EstormMessageProcessor::Consumer.new(@channel, @queue, config[:consumer_name], true, false, config)
         @consumer.logger=logger
         raise "consumer creation problem" if @consumer==nil
         msg_count,consumer_count =@consumer.queue_statistics
         queue_mgmt(config)  
         @queue.subscribe_with(@consumer, :block => config[:blocking])
         
         loop do   
             #should loop forever if blocking... otherwise needs  a loop
            sleep 1
            break if @consumer.cancelled?
          end
         msg= "Ending======about to tear_down_bunny...."
         logger.info msg
         tear_down_bunny
           
       end
        
     


     end
end    #Module