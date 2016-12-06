#the file/script that listens for new IP addresses and mac addresses before
#sending them out.
require 'socket'

class Broadcaster
#pull everything in from the file, get it into memory, then close the file.
def broadcast()
    ourLines = IO.readlines("arpSetupFile.txt")

    ourLines.each do |line|
      ipAddress = (line.split(" "))[0]

      begin #try start
      p "[B]Connection: #{ipAddress}"
      
      amHost = false
      Socket.ip_address_list.each do |i|
        if ipAddress == i.ip_address
          amHost = true
          break
        end
      end
      if amHost
        p "IP belongs to host, skipping"
        next
      end
      
      testPing = `ping -c 1 #{ipAddress}` 
      if (testPing.include? "100% packet loss") ||
        (testPing.include? "Destination Host Unreachable" )
        next # skip execution of current iteration
      end
      
      u1 = TCPSocket.new ipAddress, 55000 
      p "[B] #{u1} connected @ #{Time.now}."
      p "[B] Attempt to Receive @ #{Time.now}."
      ourPort = u1.gets()
      print(ourPort)
      #ourPort = u1.recv(1024)
      p "[B]Received #{ourPort} @ #{Time.now}."
      p "[B]our port from the other user: #{ourPort}"
      p "[B]Attemping Connection to #{ipAddress}:#{ourPort}."

      u2 = TCPSocket.new ipAddress, Integer(ourPort) 
      
      p "[B]New Connection @ #{Time.now}"
      # result = u1.recvfrom(30)
      # innerArray = result[1]
      # innerAddress = innerArray[2]
        localLines = IO.readlines("arpSetupFile.txt")
        localLines.each do |fileline|
          p fileline
          u2.print fileline
          #u2.send fileline, 0
        end
        u2.send "EOF\r\n", 0
        p "EOF sent."

        u1.close
        u2.close

        p "[B] data sent and connections closed."

      rescue Exception => e #catch start
        puts "[B]debug connection print out."
        puts e.message
        puts e.backtrace.inspect
        puts caller
        puts u1
        puts u2
      end #end of begin-rescue/ try-catch.
    end #for the loop
end #end of broadcast.

#and a separate thread is used to listen for new stuff to be saved.
  def listen()
      listenSocket = TCPServer.new 55000
      while true
        connection = listenSocket.accept()
        Thread.start{
          # generate an available port, send it back, listen for a connection
          # on that new port # etc.
          p "[L]Connection accepted @ #{Time.now}"
          availPort = port_generator()
          p "[L]Avaliable port to be sent #{availPort} @ #{Time.now}"
          
          p "[L]waiting for new connection"
          newSocket = TCPServer.new availPort
          
          connection.print(availPort)
          #listenSocket.send availPort, 0
          p "[L] connection closed."
          connection.close
          
          
          p "[L] new Socket made with #{availPort}. \r\n"
          conn2 = newSocket.accept()
          p "[L]new connection accepted."
          
          #listenSocket.close
          #new connection means new data being sent to us.
          newData = []
          
          while true
            #data = conn2.recv(512)
            data = conn2.gets()
            p "[L] the Data: #{data}"
            if data == "EOF\r\n"
              break
            else
              p "attempting to append data"
              newData << data
              p "data appended"
            end
          end #while end

        #compare our existing data to newData and fuse the two before writing
        #out to our file.
        lines = IO.readlines("arpSetupFile.txt")

          ourResults = lines + newData #at this point the data is just a string,
          #not an array of strings. needs conversion and the removing of new line chars
          savedResults = ourResults.uniq

          theFile = File.open("arpSetupFile.txt", "r+")
          savedResults.each do |line|
            if line != "EOF\r\n"
              p "writing file."
              theFile.write(line)
            end
          end
          theFile.close()
          p "[L] Smooth sailing until the end of the thread.\r\n"
          conn2.close
        }
      end #end for the while
      
  end #end for the function.

      def port_generator
        while true
          port = 32768 + rand(28232)
          p "Generated Port is #{port}"
            begin
              ourServer = TCPServer.new port
              ourServer.close
              p "[P] #{ourServer}"
              p "Open port on #{port}"
              return port
            rescue
              p "Unable to open port on #{port}"
              next
            end
        end
        return -1
      end
end

p "starting up"

ourBroadcast = Broadcaster.new

Thread.new{ ourBroadcast.listen() }
p "listener listening."

ourFlag = true

while true
  ourTime = Time.new
  #p ourTime.sec
  #add a boolean flag that allows for only a single transmission
  if(((ourTime.sec) % 30) == 0 && ourFlag)
      ourBroadcast.broadcast()
      p "broadcasted"
      ourFlag = false
      #currently not explicitly sending out our IP address because it can be
      #extracted by our listener on the other side/other class of our project
      #as shown how with the code below.
      #result = u1.recvfrom(30)
      #innerArray = result[1]
      #innerAddress = innerArray[2]
  end

  if(((ourTime.sec) == 31) || ((ourTime.sec) == 1))
    ourFlag = true
  end

end
