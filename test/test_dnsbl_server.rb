unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'helper'
#require 'eventmachine'
require 'pp'

#Monkeypatching for testing
module EventMachine
  module DNS
    class Socket < EventMachine::Connection    
      def send_packet(pkt)
        send_datagram(pkt, nameserver, 2053)
      end
    end
  end
end

class TestDNSBLServer < Minitest::Test
  
  def zone_add_test_resources(zone)
    zone.add_dnsblresource(
      EventMachine::DNSBL::Zone::DNSBLResourceRecord.new(
        "example.com", 
        /viagra/i, 
        300, 
        Resolv::DNS::Resource::IN::A.new("127.0.0.2"),
        Time.now.to_i + 3600
      )
    )
    zone.add_dnsblresource(
      EventMachine::DNSBL::Zone::DNSBLResourceRecord.new(
        "example.com", 
        /pillz/i, 
        300, 
        Resolv::DNS::Resource::IN::A.new("127.0.0.3"),
        Time.now.to_i + 3600
      )
    )
    zone.add_dnsblresource(
      EventMachine::DNSBL::Zone::DNSBLResourceRecord.new(
        "example.com", 
        /\d+\.0\.0\.127$/, 
        300, 
        Resolv::DNS::Resource::IN::A.new("127.0.0.4"),
        Time.now.to_i + 3600
      )
    )
    zone.add_dnsblresource(
      EventMachine::DNSBL::Zone::DNSBLResourceRecord.new(
        "example.com", 
        /\d+\.0\.168\.192$/, 
        300, 
        Resolv::DNS::Resource::IN::A.new("127.0.0.5"),
        Time.now.to_i - 10
      )
    )
  end
  
  def zone_test(zone)
    zone_add_test_resources(zone)
    recs = zone.get_records("viagrapillz.example.com")
    assert_equal(2, recs.length)
    assert_equal("127.0.0.2", recs[0].answer.address.to_s)
    assert_equal("127.0.0.3", recs[1].answer.address.to_s)
    recs = zone.get_records("cialispillz.example.com")
    assert_equal(1, recs.length)
    assert_equal("127.0.0.3", recs[0].answer.address.to_s)
    recs = zone.get_records("www.example.com")
    assert_equal(0, recs.length)
    recs = zone.get_records("1.0.0.127.example.com")
    assert_equal(1, recs.length)
    assert_equal("127.0.0.4", recs[0].answer.address.to_s)
    recs = zone.get_records("5.0.168.192.example.com")
    assert_equal(0, recs.length)
  end
    
  def test_memory_zone
    memzone = EventMachine::DNSBL::Zone::MemoryZone.new
    zone_test(memzone)
  end
  
  def test_sqlite3_zone
    if File.exist?("test/test.sqlite3")
      File.unlink("test/test.sqlite3")
    end
    sqlite3zone = EventMachine::DNSBL::Zone::Sqlite3Zone.new("test/test.sqlite3")
    zone_test(sqlite3zone)
    if File.exist?("test/test.sqlite3")
      File.unlink("test/test.sqlite3")
    end
  end
  
  def test_dnsbl_server
    memzone = EventMachine::DNSBL::Zone::MemoryZone.new
    zone_add_test_resources(memzone)
    completed = 0
    EM.run {
      EM::open_datagram_socket "0.0.0.0", 2053, EventMachine::DNSBL::Server, memzone
      EM::DNS::Resolver.nameservers = ["127.0.0.1"]
      r1 = EM::DNS::Resolver.resolve("viagrapillz.example.com")
      r1.callback do |r|
        assert_equal(2, r.length)
        completed += 1
        if completed == 2
          EM.stop
        end
      end
      r2 = EM::DNS::Resolver.resolve("cialispillz.example.com")
      r2.callback do |r|
        assert_equal(1, r.length)
        completed += 1
        if completed == 2
          EM.stop
        end
      end
    }
  end
end