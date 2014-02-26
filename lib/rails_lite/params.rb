require 'uri'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    # @query = req.query_string
    @permitted = {}
    @params = {}
    self.parse_www_encoded_form(req.query_string) if !req.query_string.nil?
    self.parse_www_encoded_form(req.body) if !req.body.nil?
    @params.merge!route_params

    # URI.decode_www_form(@query)
  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    keys.each {|k| @permitted[k] = true}
  end

  def require(key)
    raise AttributeNotFoundError unless @params[key]
  end

  def permitted?(key)
    @permitted[key]
  end

  def to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  # private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    query_arr = URI.decode_www_form(www_encoded_form)

    query_arr.each do |el|
      k = el[0]
      v = el[1]
      keys = parse_key(k)

      if keys.length == 1
        if @params[keys.first] == nil
          @params[keys.first] = v
        else
          @params[keys.first] += v
        end
      else
        @params.merge!create_params(keys, v)
      end
    end

  end

  def parse_body(body)
    k, v = parse_body_keys(body)
    @params.merge!create_params(k, v)
  end

  def parse_body_keys(body)
   keys, vals = body.split(",").first.scan(/'([a-zA-Z']*)'/).map(&:first)[0..-2]
   return keys, vals
  end


  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    keys = key.split("[")
    if keys.length > 1
      all_keys_except_first = keys[1..-1].map{|v| v[0...-1]}
      keys = [keys[0]] + (all_keys_except_first)
    end
    keys
  end


  def create_params(keys, value)
    params = {}


    if keys.length == 1
      if params[keys.first] ==nil
       params[keys.first] = value
       return params
      else
      params[keys.first] += value
      return params
      end
    end

    first_key = keys.shift
    if params[first_key] == nil
      params[first_key] = create_params(keys,value)
    else
      params[first_key] += create_params(keys,value)
    end
    p params
  end


end
