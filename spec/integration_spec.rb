require_relative '../lib/yaml_to_csv'

RSpec.describe 'Integration' do
  let(:yaml_path) { File.join(__dir__, 'example.yml') }
  let(:yaml) { File.read(yaml_path) }

  it "can convert YAML text to CSV text" do
    converter = YamlToCsv.new
    csv = converter.yaml_text_to_csv_text(yaml)
    expect(csv.strip).to eq <<-CSV.gsub(/^\s+/, '').strip
      en.foo,bar
      en.bar,foo
      en.attributes.name,Name
      en.attributes.address,Address
      en.attributes.empty,
    CSV
    expect(converter.csv_text_to_yaml_hash(csv)).to eq(YAML.load(yaml))
  end

  it "can override how keys are merged" do
    merge_keys = -> (parent, key) { [parent, key].compact.join("+") }
    split_keys = -> (composite) { composite.split("+") }
    converter = YamlToCsv.new(merge_keys: merge_keys, split_keys: split_keys)
    csv = converter.yaml_text_to_csv_text(yaml)
    expect(csv.strip).to eq <<-CSV.gsub(/^\s+/, '').strip
      en+foo,bar
      en+bar,foo
      en+attributes+name,Name
      en+attributes+address,Address
      en+attributes+empty,
    CSV
    expect(converter.csv_text_to_yaml_hash(csv)).to eq(YAML.load(yaml))
  end

  it "can override the CSV options" do
    converter = YamlToCsv.new(csv_opts: { col_sep: ';' })
    csv = converter.yaml_text_to_csv_text(yaml)
    expect(csv.strip).to eq <<-CSV.gsub(/^\s+/, '').strip
      en.foo;bar
      en.bar;foo
      en.attributes.name;Name
      en.attributes.address;Address
      en.attributes.empty;
    CSV
    expect(converter.csv_text_to_yaml_hash(csv)).to eq(YAML.load(yaml))
  end
end
