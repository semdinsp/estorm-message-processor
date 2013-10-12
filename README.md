[![Build Status](https://travis-ci.org/semdinsp/estorm-message-processor.png)](https://travis-ci.org/semdinsp/estorm-message-processor)
[![Code Climate](https://codeclimate.com/repos/5258c4167e00a42fef002879/badges/da46d720691ea2bae63a/gpa.png)](https://codeclimate.com/repos/5258c4167e00a42fef002879/feed)
[![Gem Version](https://badge.fury.io/rb/estorm-message-processor.png)](http://badge.fury.io/rb/estorm-message-processor)

estorm-message-processor gem
============


Simple gem to use in rails apps for AMQP inclusiong. Send a hash via AMQP and then have the message processor process the files.  See the test pages

Usage
=======

pull in the normal files for ruby.  Everytime a message is received with 'command' => "sendtemplates" delegate to that callback So add more delete_routings and you will be able to handle multiple commands

## Setup delegate processor
This is the callback processor

    class EstormMessageProcessor::Base
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
    mp.start(config)
    rescue Exception => ex
    puts "Exception in Message Processor: #{ex} at #{ex.backtrace.join("\n")}"
    end  

