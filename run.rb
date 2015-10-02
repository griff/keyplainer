require 'aws-sdk'
require 'set'
require 'yaml'

REGIONS={
  :'us-east-1'      => 'US East (N. Virginia)',
  :'us-west-2'      => 'US West (Oregon)',
  :'us-west-1'      => 'US West (N. California)',
  :'eu-west-1'      => 'EU (Ireland)',
  :'eu-central-1'   => 'EU (Frankfurt)',
  :'ap-southeast-1' => 'Asia Pacific (Singapore)',
  :'ap-southeast-2' => 'Asia Pacific (Sydney)',
  :'ap-northeast-1' => 'Asia Pacific (Tokyo)',
  :'sa-east-1'      => 'South America (Sao Paulo)'
}

class Machine
  def self.load(region, known_keys, ec2)
    instances = []
    resp = ec2.describe_instances
    machines = resp.reservations.map(&:instances).flatten.map do |i|
      Machine.new(region, known_keys, i)
    end
    instances.concat machines.to_a

    while resp.next_token
      resp = ec2.describe_instances({ next_token: resp.next_token })
      machines = resp.reservations.map(&:instances).flatten.map do |i|
        Machine.new(region, known_keys, i)
      end
      instances.concat machines.to_a
    end
    instances
  end

  attr_reader :region, :instance_id, :tags, :key

  def initialize(region, known_keys, instance)
    @region = region
    @instance_id = instance.instance_id
    @key = known_keys[instance.key_name] if instance.key_name
    @state = instance.state
    @tags = {}
    instance.tags.each do |tag|
      @tags[tag.key] = tag.value
    end
  end

  def name
    @tags['Name']
  end

  def region_name
    REGIONS[region]
  end

  STATES = {
    pending: 0,
    running: 16,
    shutting_down: 32,
    terminated: 48,
    stopping: 64,
    stopped: 80
  }

  STATES.each do |state, code|
    class_eval <<-_END_
      def #{state}?
        @state.code == #{code}
      end
    _END_
  end

  def included?(states)
    val = STATES.values_at(states)
    val.include?(@state.code)
  end

  def to_s
    "#{region_name} #{name} #{instance_id}"
  end

  def inspect
    "Machine[#{to_s}]"
  end
end

class KeyPair
  def self.load(region, ec2)
    known_keys = ec2.describe_key_pairs.key_pairs.map { |k| KeyPair.new(region, k) }
    ret = {}
    known_keys.each { |k| ret[k.name] = k }
    ret
  end

  attr_reader :region, :name, :fingerprint
  def initialize(region, key_pair)
    @region = region
    @name = key_pair.key_name
    @fingerprint = key_pair.key_fingerprint
  end

  def region_name
    REGIONS[region]
  end

  def to_s
    "#{region_name} #{name} #{fingerprint}"
  end

  def inspect
    "Key[#{to_s}]"
  end
end


allowed_keys = [].to_set
regions = REGIONS.keys
unless ARGV.empty?
  if ARGV[0] == '-'
    content = STDIN.read
  else
    unless File.exist?(ARGV[0])
      puts "Missing config file: #{ARGV[0]}"
      exit 27
    end
    content = File.read(ARGV[0])
  end
  config = YAML.load(content)
  allowed_keys = config['allowed_keys'].to_set if config.key?('allowed_keys')
  regions = config['regions'].map(&:to_sym) if config.key?('regions')
end

nil_keys = []
invalid_keys = []
unused_keys = []

#ENV['AWS_ACCESS_KEY_ID'] = 'aws key'
#ENV['AWS_SECRET_ACCESS_KEY'] = 'aws secret key'

regions.each do |region|
  ec2 = Aws::EC2::Client.new({ region: region })
  known_keys = KeyPair.load(region, ec2)

  machines = Machine.load(region, known_keys, ec2)

  keycount = Hash.new(0)
  machines.reject(&:terminated?).each do |m|
    if m.key
      keycount[m.key.name] += 1
      unless allowed_keys.empty? || allowed_keys.include?(m.key.fingerprint)
        invalid_keys << m
      end
    else
      nil_keys << m
    end
  end

  unused_keys.concat known_keys.values.select { |k| keycount[k.name] == 0 }
end

unless unused_keys.empty?
  puts "Unused key pairs:\n    " + unused_keys.map(&:to_s).join("\n    ") + "\n"
end
unless nil_keys.empty?
  puts "Machines with no key pair:\n    " + nil_keys.map(&:to_s).join("\n    ") + "\n"
end
unless invalid_keys.empty?
  rows = invalid_keys.map { |m| m.to_s + " " + m.key.name + " " + m.key.fingerprint }.join("\n    ")
  puts "Machines with an unallowed key pair:\n    " + rows + "\n"
end

exit [unused_keys, nil_keys, invalid_keys].all?(&:empty?) ? 0 : 1
