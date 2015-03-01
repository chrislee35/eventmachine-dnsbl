# EventMachine::DNSBL

EventMachine::DNSBL::Client queries DNS Blacklists for listings.
EventMachine::DNSBL::Server provides a simple way of creating a DNSBL server

## Installation

Add this line to your application's Gemfile:

    gem 'eventmachine-dnsbl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eventmachine-dnsbl

## Usage

### Client

	item = "78.12.11.91"
    EM.run do
      EventMachine::DNSBL::Client.check(item) do |results|
        pp results
        EM.stop
      end
    end
	

### Server 

To run a server, first create a "zone holder"

    memzone = EventMachine::DNSBL::Zone::MemoryZone.new

or

	sqlite3zone = EventMachine::DNSBL::Zone::Sqlite3Zone.new("test/test.sqlite3")

Then add answers, e.g.,

    memzone.add_dnsblresource(
      EventMachine::DNSBL::Zone::DNSBLResourceRecord.new(
        "example.com", 
        /viagra/i, 
        300, 
        Resolv::DNS::Resource::IN::A.new("127.0.0.2"),
        Time.now.to_i + 3600
      )
    )
    memzone.add_dnsblresource(
      EventMachine::DNSBL::Zone::DNSBLResourceRecord.new(
        "example.com", # domain name for zone
        /pillz/i,      # regex for the label
        300,           # TTL
        Resolv::DNS::Resource::IN::A.new("127.0.0.3"), # Answer to return
        Time.now.to_i + 3600 # valid until expiry
      )
    )

Then start the server

	
    EM.run {
      EM::open_datagram_socket "0.0.0.0", 53, EventMachine::DNSBL::Server, memzone
	}
	

## Contributing

1. Fork it ( https://github.com/[my-github-username]/eventmachine-dnsbl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
