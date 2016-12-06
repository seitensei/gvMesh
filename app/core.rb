require 'securerandom'
require 'socket'
require 'json'
require 'uri'
require 'net/http'

$outbox_path = 'outbox.mrl'
$inbox_path = 'inbox.mrl'

class Core
    # these are all static methods, when prepended with self.
    
    def self.ping(clientaddr)
        # pings the client address, and returns true or false
        testPing = `ping -c 1 #{clientaddr}` 
        
        if (testPing.include? "100% packet loss") || (testPing.include? "Destination Host Unreachable")
          return false
        end
        
        #unwritten else for true and the client is reachable.
        return true
    end
    
    def self.save_message(message, file)
        # saves a message to a file
        # if file doesn't exist, create it
        # recommendation: serialization(http://ruby.about.com/od/advancedruby/ss/Serialization-In-Ruby-Marshal.htm)
        if File.exists?(file)
            #update the file here if it exists.
            theFile = File.open(file, "r+")
            fileContents = Marshal.load(theFile) #dont we want w+ to read the file to file contents?
            theFile.close()
            theFile = File.open(file, "w+")
            fileContents << message
            print("new contents:  #{fileContents} \r\n")
            #write back the new contents to the file here.
            Marshal.dump(fileContents, theFile)
            theFile.close()
            
        else
            #if the file doesnt exist, it is created and populated down here.
            theFile = File.open(file, "w+")
            Marshal.dump([message], theFile)
            theFile.close()
        end
    end
    
    def self.load_box(file)
        # loads messages from file to array
        # if file doesn't exist, or no messages in file
        # return an empty array
        if !File.exists?(file)
            #it does not exist
            return []
        else
            #it exists, but does it have messages?
            theFile = File.open(file, "r")
            fileContents = Marshal.load(theFile)
            theFile.close()
            if fileContents == nil || fileContents == ""
                return []
            else
                return fileContents
            end
        end
    end
    
    def self.save_box(array,file)
        # writes an array to the file
        # if file doesn't exist, create it
        
        theFile = File.open(file, "w+")
        Marshal.dump(array, theFile)
        theFile.close()
    end
    
    def self.send(message)
        # load message from message to send file
        # connect to/send to dest if ping is true
        # else, send to others
        #http://stackoverflow.com/questions/13152264/sending-http-post-request-in-ruby-by-nethttp
        destination = message.dest
        # see if host is reachable
        if Core.ping(destination)
            # reachable
            #call http post and it posts the message to the inbox/other users server.
            uri = URI("http://#{destination}:8080/api/v1/inbox")
            http = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
            request.body = "[#{message.to_json("hi")}]"
            response = http.request(request)
        else
            # unreachable, iterate through list and send to other peers
            peers = IO.readlines("/var/gvMesh/arpSetupFile.txt")
            peers.each do |peer|
                peerArray = peer.split(" ")
                peerIP = peerArray[0]
                if Core.ping(peerIP)
                    uri = URI("http://#{peerIP}:8080/api/v1/inbox")
                    http = Net::HTTP.new(uri.host, uri.port)
                    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
                    request.body = "[#{message.to_json("hi")}]"
                    response = http.request(request)
                else
                    next #go to next peer in file.
                end
            end
        end
    end
    
    def self.outbox_send()
        # check messages in outbox file for whether dest is available/pingable
        # if yes, send
        outbox = load_box($outbox_path)
        if outbox.any?
            outbox.each do |m|
                destination = m.dest
                if Core.ping(destination)
                    uri = ("http://#{destination}:8080/api/v1/inbox")
                    http = Net::HTTP.new(uri.host, uri.port)
                    request = Net::HTTP.new(uri.path, 'Content-Type' => 'application/json')
                    request.body = "[#{m.to_json("hi")}]"
                    http.request(request)
                    outbox.delete(m)
                end
            end
        end
    end
    
    def self.recv_message(message)
        # called from HTTP API
        # message is saved to appropriate file
        # if dest is host ip, save to inbox
        # if dest is not host ip, save to outbox
        destination = message.dest
        amHost = false
        puts("Recieved a message bound for #{destination}.")
        Socket.ip_address_list.each do |a|
            if a.ip_address == destination
                puts("Current Host Machine is destination.")
                puts("#{a} == #{destination}")
                amHost = true
                break
            else
                puts("IP does not match.")
                puts("#{a} != #{destination}")
                amHost = false
            end
        end
        if amHost
            Core.save_message(message, $inbox_path)
        else
            Core.save_message(message, $outbox_path)
        end
    end
    
    
end

# Model for Message
class Message
    # Message can be manipulated after creation, but not meta data
    # can't write to source, dest, or id
    attr_accessor :message
    attr_reader :time_created
    attr_reader :source
    attr_reader :dest
    attr_reader :id
    
    def initialize(src, dst, message, timec)
        # id is generated UUID using securerandom in string format
        # 00000000-0000-0000-0000-000000000000
        @id = SecureRandom.uuid
        @source = src
        @dest = dst
        @message = message
        @time_created = timec
        
    end
    
    def to_json(thing = nil)
        # json representation
        # http://ruby-doc.org/stdlib-2.1.5/libdoc/json/rdoc/JSON.html
        out_hash = {
            'id' => "#{@id}",
            'time_created' => "#{@time_created}",
            'source' => "#{@source}",
            'dest' => "#{@dest}", 
            'message' => "#{@message}"
        }
        return JSON.generate(out_hash)
        
    end
    
    def to_hash
        out_hash = {
            'id' => "#{@id}",
            'time_created' => "#{@time_created}",
            'source' => "#{@source}",
            'dest' => "#{@dest}", 
            'message' => "#{@message}"
        }
        return out_hash
    end
    
    def from_hash(msg_hash)
        # p "#{msg_hash} \r\n"
        @id = msg_hash['id']
        @time_created = msg_hash['time_created']
        @source = msg_hash['source']
        @dest = msg_hash['dest']
        @message = msg_hash['message']
        # p "id #{@id} \r\n"
        # p "time #{@time_created} \r\n"
        # p "source #{@source} \r\n"
        # p "dest #{@dest} \r\n"
        # p "message #{@message} \r\n"
    end
    
end