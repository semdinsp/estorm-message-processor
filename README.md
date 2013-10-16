[![Build Status](https://travis-ci.org/semdinsp/estorm-message-processor.png)](https://travis-ci.org/semdinsp/estorm-message-processor)
[![Code Climate](https://codeclimate.com/repos/5258c4167e00a42fef002879/badges/da46d720691ea2bae63a/gpa.png)](https://codeclimate.com/repos/5258c4167e00a42fef002879/feed)
[![Gem Version](https://badge.fury.io/rb/estorm-message-processor.png)](http://badge.fury.io/rb/estorm-message-processor)

estorm-message-processor gem
============


Simple gem to use in rails apps for AMQP inclusion. Send a hash via AMQP and then have the message processor process the files.  See the test pages

Usage
=======

pull in the normal files for ruby.  Everytime a message is received with 'command' => "sendtemplates" delegate to that callback So add more delegate_routings and you will be able to handle multiple commands

## Setup delegate processor
This is the callback processor in the consumer

    class EstormMessageProcessor::Consumer
    def delegate_sendtemplates(cmdhash)
    p=Promotion.find(cmdhash['promotion'].to_i)
    data=YAML.load(p.data)
    data.each { |entry| 
    cc=CustomerContact.create_and_send_template(entry['email'],entry,p.configuration_setting,p) if entry!=nil and entry['email']!=nil           }
    end
    end

# Start the Message Processor
    begin
    config={:url => AMQPURL,:connecturlflag=> Rails.env.production? ,:queuename => CONTACT_MESSAGE, :blocking => true}
    #puts "Starting SMS Gateway. Please check the log at #{LOGFILE}"
    EstormMessageProcessor::Base.logger=Logger.new(STDOUT) 
    puts "Starting Bunny Contact Processor on #{config.inspect} "  
    mp = EstormMessageProcessor::Base.new
    mp.start(config)  # THIS MAY NEED TO BE IN a THREAD
    rescue Exception => ex
    puts "Exception in Message Processor: #{ex} at #{ex.backtrace.join("\n")}"
    end  

# send a message using the client
Use the client to send a message to the delegate processor (background task). Note the command set to the callback processor above

    def bunny_send
    cmdhash={'command'=>'sendtemplates', 'promotion'=>self.id.to_s}
    puts "----> to system [x] sending  #{cmdhash.inspect}"
    bunny=EstormMessageProcessor::Client.new
    bunny.bunny_send(AMQPURL,Rails.env.production?,CONTACT_MESSAGE,cmdhash)
    end

# config[:exit_when_empty] = true if you want to just process the messages in the queue
This is useful if you have a back ground task that you want to run occasionally and just process the messages and exit.  For example on heroku you can schedule a job to run every hour and it will process the messages and exit.  This will keep the costs down for the background task on heroku.  (Of course you need to ensure that the job time is shorter than the heroku scheduler time)

