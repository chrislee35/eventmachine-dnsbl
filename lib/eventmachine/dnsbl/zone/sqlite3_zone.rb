require "eventmachine/dnsbl/zone/abstract_zone"
require 'sqlite3'
require 'resolv'
require 'pp'

module EventMachine
  module DNSBL
    module Zone
      class Sqlite3Zone < AbstractZone
        def initialize(sqlite3, tablename = "zone")
          @class = DNSBLResourceRecord
          @fields = @class.members.map {|x| x.to_s}.join(", ")
          @tablename = tablename
          if sqlite3.class == SQLite3::Database
            @db = sqlite3
          else
            @db = SQLite3::Database.new(sqlite3)
          end
          if @db.table_info(tablename).length == 0
            @db.execute("CREATE TABLE #{@tablename} (#{@fields})")
          end            
          @zones = Array.new
          @backend = Hash.new
        end
        
        def add_dnsblresource(dnsblrr)
          dnsblrr.answer = dnsblrr.answer.address.to_s
          args = (@class.members).map{|f| dnsblrr.send(f)}
          qs = args.map{|x| "'#{quote(x.to_s)}'"}.join(",").gsub(/'NULL'/, "NULL")
          zone = dnsblrr[:zone]
          if not @zones.include?(zone)
            @zones << zone
            @zones = @zones.uniq.sort {|a,b| b.length <=> a.length}
          end
          sql = "INSERT INTO #{@tablename} (#{@fields}) VALUES (#{qs})"
          @db.execute(sql)
        end
        
        def get_records_by_field_and_value(field, value)
          records = Array.new
          rs = @db.execute("SELECT #{@fields} FROM #{@tablename} WHERE #{field}='#{value}'")
          rs.each do |row|
            row[1] = Regexp.new(row[1])
            row[3] = Resolv::DNS::Resource::IN::A.new(row[3])
            if row[4] =~ /\d/
              row[4] = row[4].to_i
            else
              row[4] = nil
            end
            records << DNSBLResourceRecord.new(*row)
          end
          records
        end
        
        def get_all_records_for_zone(zone)
          get_records_by_field_and_value("zone", zone)
        end
        
        def quote( string )
          string.gsub( /'/, "''" )
        end
        private :quote
      end
    end
  end
end