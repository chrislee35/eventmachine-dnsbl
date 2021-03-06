module EventMachine
  module DNSBL
    module Zone
  		class DNSBLResourceRecord < Struct.new(:zone, :label_regex, :ttl, :answer, :valid_until); end
      
      class AbstractZone
        def get_records(query, qtype = Resolv::DNS::Resource::IN::A)
          records = Array.new
          # A queries are all that I support right now
          if qtype != Resolv::DNS::Resource::IN::A
            return records
          end

          zone = label = nil
          @zones.each do |z|
            if query.end_with?(z)
              label = query[0, query.length - z.length - 1]
              zone = z
            end
          end
          
          if zone
            get_all_records_for_zone(zone).each do |rec|
              if rec[:valid_until] and rec[:valid_until] < Time.now.to_i
                next
              elsif rec[:label_regex].match(label)
                records << rec
              end
            end
          end
          records
        end
      end
    end
  end
end