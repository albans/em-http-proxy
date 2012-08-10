require "rubygems"
require "eventmachine"

module ProxyConnection
  def initialize(client, request)
    @client, @request = client, request
  end

  def post_init
    puts "#{@request}"
    EM::enable_proxy(self, @client)
  end

  def connection_completed
    send_data @request
  end

  def proxy_target_unbound
    close_connection
    puts "Connection closed."
  end

  def unbind
    @client.close_connection_after_writing
  end
end

module ProxyServer
  def receive_data(data)
    (@buf ||= "") << data
    if @buf =~ /\r\n\r\n/ # all http headers received
      
      if @buf =~ /Host: ((([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])\.)+([a-zA-Z0-9]{2,5}))(:(\d*))?/
        host=$1
        port=$5||80
        puts "connecting to #{host} on #{port}..."
        EM.connect(host, port, ProxyConnection, self, data)
      end
    end
  end
end

EM.run {
  EM.start_server("127.0.0.1", 8080, ProxyServer)
}
