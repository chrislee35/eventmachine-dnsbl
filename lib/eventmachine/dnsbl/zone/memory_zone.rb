require "eventmachine/dnsbl/zone/abstract_zone"

module EventMachine
  module DNSBL
    module Zone
      class MemoryZone < AbstractZone
        def initialize
          @zones = Array.new
          @backend = Hash.new
        end
        
        def add_dnsblresource(dnsblrr)
          zone = dnsblrr[:zone]
          if not @backend[zone]
            if not @zones.include?(zone)
              @zones << zone
              @zones = @zones.uniq.sort {|a,b| b.length <=> a.length}
            end
            @backend[zone] = Array.new
          end
          @backend[zone] << dnsblrr
        end
        
        def get_all_records_for_zone(zone)
          @backend[zone]
        end
        
      end
    end
  end
end