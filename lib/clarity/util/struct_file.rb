module Clarity
	
	# A file like this:
	# 
	# 	appname 'hq'
	# 	domain '4ppz.com'
	# 	
	# 	softlayer_node 'hq' do
	# 		private_ip '10.20.61.86'
	# 		public_ip '67.228.107.130'
	# 		root_password '%7C%03%CB%5B%2C%EE7%86%D4%04%BE%F7%5C%F6%C3Gq5%9D%95%3A%3C%8F%E3'
	# 		chef {
	# 			:mysql => {
	# 				:bind_address => 'localhost',
	# 				:server_root_password => Davcro::ProtectedFile['hq_mysql_root_password']
	# 			},
	# 			:rails_authorization => { 
	# 				:keyfile => Davcro::ProtectedFile['rails_id_rsa'],
	# 				:authorized_keys => Davcro::ProtectedFile['rails_authorized_keys']  
	# 			},
	# 			:rails => { :version => '2.3.4' },
	# 			:recipes => [ 'hq_web_app' ]
	# 		}
	# 	end
	
	# Will be objectified into this:
	# config = LazyHashFile.new(filepath) 
	# config.appname
	# => 'hq'
	# config.softlayer_node.hq.private_ip
	# => 10.20.61.86
	
	# convert each declaration into a hash like below
	# params hash will look like
	# { :appname => 'hq', :domain => '4ppz.com', :softlayer_node => { :hq => { :private_ip => '10.20.61.86' } } }
	# compress the hash into a struct
	
	class StructFile
		
		def self.parse_dir(dirname)
			filepaths = Dir.glob(File.join(dirname, '**', '*.rb'))
			self.parse filepaths
		end
		
		def self.parse(filepaths)
			if !filepaths.is_a?(Array)
				filepaths = [filepaths]
			end
			r = Reader.new
			filepaths.each do |filepath|
				r.instance_eval(File.new(filepath).read)
			end
			if r.params.keys.size<1
				return nil
			end
			HashStruct.new(r.params)
		end
		
		class Reader
			attr_reader :params
			def initialize
				@params = { }
			end
			
			def method_missing(name, *args, &block)
				if block_given?
					r = Reader.new
					r.instance_eval(&block)
					val = r.params
					if nested_name=args.first
						@params[name] ||= { }
						@params[name][nested_name.to_sym] = val
					else
						@params[name] = val
					end
				else
					# don't convert actual hashes into structs!
					if args.size==1
						arg = args.first
						if arg.is_a?(Hash)
							arg[:protected_hash]=true
						end
						@params[name]=arg
					else
						@params[name]=args
					end
				end
			end
		end
		
		class HashStruct
			def initialize(hash)
				@hash = hash
				@hash.each do |key, value|
					if value.is_a?(Hash)
						unless value.delete(:protected_hash)
							@hash[key] = HashStruct.new(value)
						end
					end
				end
			end
			
			def to_hash
				@hash
			end
			
			def each
				@hash.each do |k, v|
					yield(k,v)
				end
			end
			
			def [](name)
				@hash[name.to_sym]
			end
			
			def method_missing(name)
				@hash[name]
			end
		end
		
	end
	
	
end