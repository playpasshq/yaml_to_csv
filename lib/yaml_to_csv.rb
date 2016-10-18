require "yaml_to_csv/version"
require "csv"
require "yaml"

class YamlToCsv
  DEFAULT_CSV_OPTS = { col_sep: ',' }
  DEFAULT_MERGE_KEYS = -> (parent, key) { [parent, key].compact.join('.') }
  DEFAULT_SPLIT_KEYS = -> (composite_key) { composite_key.split('.') }

  attr_reader :csv_opts, :merge_keys, :split_keys

  def initialize(csv_opts: {}, merge_keys: nil, split_keys: nil)
    @csv_opts = DEFAULT_CSV_OPTS.merge(csv_opts)
    @merge_keys = merge_keys || DEFAULT_MERGE_KEYS
    @split_keys = split_keys || DEFAULT_SPLIT_KEYS
  end

  # @return [String]
  def yaml_text_to_csv_text(yaml_text)
    yaml_hash = YAML.load(yaml_text)
    flat_hash = HashFlattener.new(merge_keys: merge_keys).flatten(yaml_hash)
    hash_to_csv_string(flat_hash, csv_opts: csv_opts)
  end

  # @return [Hash]
  def csv_text_to_yaml_hash(csv_text)
    csv_arrs = CSV.parse(csv_text, csv_opts)
    csv_arrs.reduce({}) do |hsh, (composite_key, value)|
      keys = split_keys.call(composite_key)
      nested = hsh
      keys.each_with_index do |key, idx|
        has_nested_keys = (idx + 1) != keys.length
        if has_nested_keys
          nested[key] ||= {}
          nested = nested[key]
        else
          nested[key] = value
        end
      end
      hsh
    end
  end

  protected

  def hash_to_csv_string(hsh, csv_opts: {})
    CSV.generate(DEFAULT_CSV_OPTS.merge(csv_opts)) do |csv|
      hsh.each do |key, value|
        csv << [key, value]
      end
    end
  end

  class HashFlattener
    attr_reader :merge_keys

    def initialize(merge_keys:)
      @merge_keys = merge_keys
    end

    def flatten(hsh, parent: nil)
      hsh.reduce({}) do |flat, (key, value)|
        new_key = merge_keys.call(parent, key)
        if value.is_a?(Hash)
          flat.merge!(flatten(value, parent: new_key))
        else
          flat[new_key] = value
        end
        flat
      end
    end
  end
end
