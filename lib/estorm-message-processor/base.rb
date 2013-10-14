require 'rubygems'
require 'bunny'
require 'yaml'

module EstormMessageProcessor
  class Base

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

       def process_messages(delivery_info,properties,body)
         begin
           cmdhash=YAML.load(body)
           delegatestring="delegate_#{cmdhash['command']}"
           # create procedures named delegate_command accepting cmdhash
           msg = "-----> [gem estorm message processor] Received from App #{body} calling delegate #{delegatestring} "
           logger.info msg
           self.send(delegatestring,cmdhash)
           #load the promotion and process through data

         rescue  Exception => e    # add could not convert integer
           msg= "[gem estorm message processor] bunny exception #{e.message} found #{e.inspect} #{e.backtrace}..."  #THIS NEEDS WORK!
           logger.info msg

          end
       end

       def logger
         EstormMessageProcessor::Base.logger
       end

       def setup_bunny_communications(url,flag,queuename)
         begin
           # pass flag in as Rails.env.production?
           @client = Bunny.new(url) if flag 
           @client = Bunny.new if !flag
            @client.start
           # msg= "client inspect #{@client.inspect}"
           # logger.info msg
         rescue Bunny::PossibleAuthenticationFailureError => e
           puts "Could not authenticate "
           msg= "logger could not authenticate #{e.message}"
           logger.info msg
         end
         @channel   = @client.create_channel
         @queue   = @channel.queue(queuename)
         msg= "set up active MQ on #{queuename}"
         logger.info msg
       end

       def tear_down_bunny
          @client.close if @client!=nil
          msg= "closing bunny"
          logger.info msg
       end
       def queue_mgmt(config,msg_count)
          msg= "[*] Waiting for messages in #{@queue.name}.  blocking is #{config[:blocking]}"
          logger.info msg
          count=0
         @queue.subscribe(:block => config[:blocking]) do |delivery_info, properties, body|
            process_messages(delivery_info,properties,body)
            count=count+1
            msg= "#{count}: ------processed message"
            logger.info msg
           end
       end
       def start(config)
         setup_bunny_communications(config[:url],config[:connecturlflag],config[:queuename])
         # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
         msg= "Connecting to bunny #{config.inspect} environment #{config.inspect}"
         logger.info msg
         msg_count =@queue.message_count
         consumer_count =@queue.consumer_count
         msg = "queue status for queue #{config[:queuename]} message count: #{msg_count} consumers: #{consumer_count}"
         logger.info msg
         @loopflag=true
           while @loopflag do   
             queue_mgmt(config,msg_count)
           end
         msg= "Ending======about to tear_down_bunny...."
         logger.info msg
         tear_down_bunny
           
       end

     


     end
end    #Module