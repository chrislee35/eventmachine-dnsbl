require 'eventmachine'
require 'resolv'

module EventMachine
	module DNSBL
		class Server < EventMachine::Connection
			def initialize(zones = MemoryZone.new)
				@zones = zones
			end
			
			def receive_data(data)
				dns = Resolv::DNS::Message.decode(data)
				dns.qr = 1
				dns.aa = 1
				return if dns.opcode != Resolv::DNS::OpCode::Query
				unless dns.question.length == 1 and dns.question[0][1] == Resolv::DNS::Resource::IN::A
					dns.rcode = Resolv::DNS::RCode::FormErr
					res = dns.encode
					send_data res
					return
				end
				query, qtype = dns.question[0]
				rs = @zones.get_records(query.to_s, qtype)
				unless rs
					dns.rcode = Resolv::DNS::RCode::NXDomain
					res = dns.encode
					send_data res
					return
				end
				# add the records them to the set of answers
				rs.each do |rr|
					dns.add_answer(query,rr.ttl,rr.answer)
				end
				# Make sure that we are authoritative for the response! Otherwise, return REFUSED
				dns.rcode = Resolv::DNS::RCode::NoError # Or Refused
				res = dns.encode
				#port, ip = Socket.unpack_sockaddr_in(get_peername)
				#puts "DEBUG: #{ip}:#{port} #{res.length}"
				send_data res
			end
			
			def add_record(qname, answer, ttl=300)
				rr = ResourceRecord.new(qname, ttl, answer)
				@rr[qname] = [] unless @rr[qname]
				@rr[qname] << rr
			end

			def del_record(qname, answer)
				return nil unless @rr[qname]
				@rr[qname].delete_if {|rr| rr.answer == answer}
			end
			
			def del_all_records(qname)
				@rr.delete(qname)
			end

			def get_records(qname, qtype)
				return nil unless @rr[qname]
				@rr[qname].find_all {|rr| rr.answer.class == qtype}
			end
		end
	end
end
