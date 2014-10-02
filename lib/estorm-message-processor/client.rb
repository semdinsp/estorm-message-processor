require 'rubygems'
require 'bunny'
require 'yaml'

module EstormMessageProcessor
  class Client
  def setup_bunny(url,flag)
  #maybe save this as global to speed it up.
  begin
    @conn = Bunny.new(url) if flag
    @conn = Bunny.new if !flag
    @conn.start
  rescue Bunny::PossibleAuthenticationFailureError => e
    puts "Could not authenticate as #{@conn.username}"
  rescue Bunny::TCPConnectionFailed => e
    puts "BUNNY TCP CONNECTION FAILURE -----RETRY #{e.message}"
    sleep 3
    @conn.start if @conn!=nil
  end
  @channel   = @conn.create_channel
  #puts "connected: #{conn.inspect}"
  [@conn,@channel]
  end
  def bunny_send(url,flag,queuename,cmdhash)
   @conn,@channel=setup_bunny(url,flag)
   @queue    = @channel.queue(queuename)
   #cmdhash={'command'=>'sendtemplates', 'promotion'=>self.id.to_s}
   @channel.default_exchange.publish(cmdhash.to_yaml, :routing_key => @queue.name)
   @conn.close  
  end 
  def connection
    @conn
  end
  #def bunny_send_no_close(url,flag,queuename,cmdhash)
  def bunny_send_no_close(queuename,cmdhash)
    # @conn,@channel=setup_bunny(url,flag)
    @queue    = @channel.queue(queuename)
    #cmdhash={'command'=>'sendtemplates', 'promotion'=>self.id.to_s}
    @channel.default_exchange.publish(cmdhash.to_yaml, :routing_key => @queue.name)
   end
end
end