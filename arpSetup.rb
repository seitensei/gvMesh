# The script that adds the pi's and their ip/mac addresses to each other.
#need to get ip and mac addresses from a file.
#require "io"

    ourLines = IO.readlines("/var/gvMesh/arpSetupFile.txt")
    ourLines.each do |line|
      lineContents = line.split(" ")
      ipAddress = lineContents[0]
      macAddress = lineContents[1]
      print("#{ipAddress} on #{macAddress} read.\r\n")
      system( "sudo arp -s #{ipAddress} #{macAddress}" )
      print("ARP command ran. \r\n")
    
    end
