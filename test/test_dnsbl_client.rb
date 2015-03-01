unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'helper'
require 'eventmachine'
include EventMachine::DNSBL
require 'pp'


class TestDNSBLClient < Minitest::Test
  def run_test(item, expected_result)
    EM.run do
      EventMachine::DNSBL::Client.check(item) do |results|
        pp results
        assert_equal(expected_result, EventMachine::DNSBL::Client.blacklisted?(results))
        EM.stop
      end
    end
  end    
  
  def test_127_0_0_2
    run_test("127.0.0.2", true)
  end
  def test_127_0_0_254
    run_test("127.0.0.254", false)
  end
  def test_surbl
    run_test("surbl-org-permanent-test-point.com", true)
  end
  def test_example_com
    run_test("example.com", false)
  end
end
