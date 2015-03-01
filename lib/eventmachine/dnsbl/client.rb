require 'eventmachine'
require 'eventmachine/dnsbl/defaults'
require 'resolv'
require 'json'

module EventMachine
  module DNSBL
  	# DNSBLResult holds the result of a DNSBL lookup
  	# dnsbl: name of the DNSBL that returned the answer
  	# item: the item queried, an IP or a domain
  	# result: the result code, e.g., 127.0.0.2
  	# meaning: the mapping of the result code to the meaning from the configuration file
  	# timing: the time between starting to send queries to the DNSBLs and when the result from this DNSBL returned
  	class DNSBLResult < Struct.new(:dnsbl,:item,:query,:result,:meaning,:timing); end
    
  	# Lookup actually handles the sending of queries to a recursive DNS server and places any replies into DNSBLResults
  	class Client
      @@config = EventMachine::DNSBL::Defaults.config
      @@tlds_2l = EventMachine::DNSBL::Defaults.tlds_2l
      @@tlds_3l = EventMachine::DNSBL::Defaults.tlds_3l
      
      @@requests = Array.new
      
      def self.config(config = nil)
        if config
          @@config = config
        end
        @@config
      end
      
      def self.two_level_tlds(two_level_tlds = nil)
        if two_level_tlds
          @@tlds_2l = two_level_tlds
        end
        @@tlds_2l
      end
      
      def self.three_level_tlds(three_level_tlds = nil)
        if three_level_tlds
          @@tlds_3l = three_level_tlds
        end
        @@tlds_3l
      end
            
  		# Converts a hostname to the domain: e.g., www.google.com => google.com, science.somewhere.co.uk => somewhere.co.uk
      def self.normalize(domain)
  			# strip off the protocol (\w{1,20}://), the URI (/), parameters (?), port number (:), and username (.*@)
  			# then split into parts via the .
  			parts = domain.gsub(/^\w{1,20}:\/\//,'').gsub(/[\/\?\:].*/,'').gsub(/.*?\@/,'').split(/\./)
  			# grab the last two parts of the domain
  			dom = parts[-2,2].join(".")
  			# if the dom is in the two_level_tld list, then use three parts
  			if @@tlds_2l.index(dom)
  				dom = parts[-3,3].join(".")
  			end
  			if @@tlds_3l.index(dom)
  				dom = parts[-4,4].join(".")
  			end
  			dom
      end

      def self.check(item, &cback)
        itemtype = (item =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) ? :ip : :domain
        label = (itemtype == :ip) ? item.split(/\./).reverse.join(".") : normalize(item)
        answers = Array.new
        count = 0
        @@config.each do |dnsblname, options|
          if options[:type] == itemtype and not options[:disabled]
            count += 1
            starttime = Time.now.to_f
            lookup = "#{label}.#{options[:domain]}"
            d = EM::DNS::Resolver.resolve lookup
            d.errback {
              answers << DNSBLResult.new(dnsblname, item, lookup, nil, nil, Time.now.to_f - starttime)
              if answers.length == count and cback
                cback.call(answers)
              end
            }
            d.callback { |r|
              res = nil
              meaning = nil
              if r.length > 0
                res = r.join(",")
                meaning = r.map {|answer|
                  options[answer] || answer
                }.join(",")
              end
              answers << DNSBLResult.new(dnsblname, item, lookup, res, meaning, Time.now.to_f - starttime)
              if answers.length == count and cback
                cback.call(answers)
              end
            }
          end
        end
      end
      
      def self.blacklisted?(answers)
        answers.find {|a| a.meaning } != nil
      end
          
    end
  end
end
