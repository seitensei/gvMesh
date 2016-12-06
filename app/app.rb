require 'sinatra'
require 'socket'
require 'json'
require_relative 'core.rb'

set :port, '8080' #replace with '8080'
set :bind, '0.0.0.0' #replace with "0.0.0.0"

$outbox_path = 'outbox.mrl'
$inbox_path = 'inbox.mrl'

before do
    headers 'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
    'Access-Control-Allow-Headers' => 'Content-Type'
end

#set :protection, false

options '/*' do
    200
end

get '/' do
    # [HTTP]send HTML index/menu page
    # erb :inbox
    File.read(File.join('public', 'index.html'))
end

get '/new' do
    # [HTTP]send html new message page
    erb :message
end

get '/api/v1/inbox_list' do
    # [HTTP]send a json file with all items in inbox
    # source, message, id
    print("Attempt to load inbox")
    inbox = Core.load_box($inbox_path)
    output = Hash.new
    output['messages'] = inbox
    return JSON.generate(output)
    # TODO: inbox array to json
    
end

get '/api/v1/outbox_list' do
    # [HTTP]send a json file with all items in outbox
    # source, dest, message, id
    print("Attempt to load outbox")
    outbox = Core.load_box($outbox_path)
    output = Hash.new
    output['messages'] = outbox
    return JSON.generate(output)
    # TODO: Outbox array to JSON
    
end

get '/api/v1/active_clients' do
    # [HTTP]send a json file with entries of all clients and ping status
    # client ip, ping status [true/false]
    
    # TODO: Generate array of IPs from arpSetupFile table
    # TODO: call Core.ping(ip) for each, and if true, add to new array
    # TODO: array to json, return
    activeList = []
    fileInput = IO.readlines("arpSetupFile.txt")
    fileInput.each do |l|
      fileSplit = l.split(" ")
      ipAddress = fileSplit[0]
      macAddress = fileSplit[1]
      puts("Checking #{ipAddress}")
      if Core.ping(ipAddress)
          puts("#{ipAddress} is active.")
          activeList << ipAddress
      end
    end
    output_hash = Hash.new
    output_hash['clients'] = activeList
    return JSON.generate(output_hash)
end

get '/api/v1/clients' do
    activeList = []
    fileInput = IO.readlines("/var/gvMesh/arpSetupFile.txt") #should be /var/gvMesh/
    fileInput.each do |l|
      fileSplit = l.split(" ")
      ipAddress = fileSplit[0]
      macAddress = fileSplit[1]
      activeList << ipAddress
    end
    output_hash = Hash.new
    output_hash['clients'] = activeList
    return JSON.generate(output_hash)    
end

get '/api/v1/message/:message_id' do
    # [HTTP]send a json file with message specified, otherwise, json file with defaults of invalid
    # source, dest, message, id; if found
    # source: invalid, dest: invalid, message: invalid, id: 00000000-0000-0000-0000-000000000000 
    
    # TODO: load message to json and return
    inbox = Core.load_box($inbox_path)
    inbox.each do |m|
        if m.id = params[:message_id]
            # if id matches
            return message.to_json
        end
    end
end

post '/api/v1/outbox_refresh' do
    # just calls the outbox send method
    Core.outbox_send()
end

post '/api/v1/delete' do
    data = params['id']
    inbox_data = Core.load_box($inbox_path)
    inbox_data.delete_if{|message| message.id == data}
    Core.save_box(inbox_data, $inbox_path)
end

post '/api/v1/send' do
    #headers 'Access-Control-Allow-Origin' => '*'
    # accessible in data hash, i.e. data['message']
    # json file recieved should be in message format
    # create a message, save it to a file, and then send it
    
    # TODO: each pi has to set its own IP address in the app.rb file.
    
    data = Hash.new
    data['dest'] = params['dest']
    data['message'] = params['message']
    data['time_created'] = params['time_created']
    data['source'] = '999.999.999.3'
    message = Message.new(data['source'], data['dest'], data['message'], data['time_created'])
    Core.send(message)
    # Attempt outbox too
    Core.outbox_send() #no semi colons
end

post '/api/v1/inbox' do
    # this is used by remote host/client
    request.body.rewind
    initdata = JSON.parse(request.body.read)
    data = initdata[0]
    puts("#{data}")
    # accessible in data hash, i.e. data['message']
    # json file recieved should be in message format
    message = Message.new(data['source'], data['dest'], data['message'], data['time_created']) # need to overwrite
    message.from_hash(data)
    Core.recv_message(message)
    
end