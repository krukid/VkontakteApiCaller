class VkontakteApiCaller

  DEFAULT_API_URL = "api.vkontakte.ru"    #alt: "api.vk.com"
  DEFAULT_API_PORT = 80
  DEFAULT_API_PATH = "/api.php"

  API_TYPES = [:server, :desktop] #:client

  attr_accessor :http_headers

  def initialize(api_id, api_type, args)
    @api_url  = args.delete(:api_url)  || DEFAULT_API_URL
    @api_port = args.delete(:api_port) || DEFAULT_API_PORT
    @api_path = args.delete(:api_path) || DEFAULT_API_PATH

    @api_id = api_id
    @api_type = api_type
    
    store_session!(args)
  end

  def store_session!(args)
    @mid, @sid, @secret = *[:mid, :sid, :secret].collect{|k| args[k]}
    validate!
  end

  def validate!
    case @api_type
    when :server
      message = ":secret is required" if @secret.blank?
    when :desktop
      message = ":mid, :sid and :secret are required" if @mid.blank? or @sid.blank? or @secret.blank?
    else
      raise ArgumentError.new("Unknown API type #{@api_type}")
    end
    raise ArgumentError.new(message + " for API type #{@api_type}") if message.present?
  end

#  def read_args(args, *keys)
#    return *keys.collect{|k| args[k]}
#  end
  
  def http_headers
    @http_headers || {}
  end

  def http
    @http ||= Net::HTTP.new(@api_url, @api_port)
  end

  def post(vk_method, vk_method_args, vk_api_args)
    #puts "[POST] #{@api_path} << #{api_query_str(vk_method, vk_method_args, vk_api_args)}"
    http.post(@api_path, api_query_str(vk_method, vk_method_args, vk_api_args), http_headers)
  end

  def get(vk_method, vk_method_args, vk_api_args)
    #puts "[GET] #{@api_path}?#{api_query_str(vk_method, vk_method_args, vk_api_args)}"
    http.get(@api_path+"?"+api_query_str(vk_method, vk_method_args, vk_api_args), http_headers)
  end

  # REQUEST QUERY STRINGS
  ########################

  def api_query_str(method, method_args, api_args)
    args = api_args(method, method_args, api_args)
    query_str = args.collect{|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
    puts "[qry_str] #=> #{query_str}"
    query_str
  end

  def api_args(method, method_args, api_args)
    case @api_type
    when :desktop
      api_desktop_args(method, method_args, api_args)
    when :server
      api_server_args(method, method_args, api_args)
    end
    
  end

  def api_desktop_args(method, method_args, api_args)
    args = {:api_id=>@api_id}.merge(method_args).merge(api_args)
    args.merge!({:method=>method})
    args.merge!(:sig=>api_desktop_sig(args))
    args.merge!(:sid=>@sid)
    args
  end

  def api_server_args(method, method_args, api_args)
    args = {:api_id=>@api_id}.merge(method_args).merge(api_args)
    args.merge!({:method=>method, :timestamp=>Time.now.to_i, :random=>(rand * 10000).to_i})
    args.merge!(:sig=>api_server_sig(args))
    args
  end

  # REQUEST SIGNATURES
  #####################

  def api_desktop_sig(args)
    api_sig(@mid + sorted_param_str(args) + @secret)
  end

  def api_server_sig(args)
    api_sig(sorted_param_str(args) + @secret)
  end

#  def api_client_sig(args)
#    api_sig(#@viewer_id + sorted_param_str(args) + @secret)
#  end

  def api_sig(sig_str)
    puts "[sig_str] #=> #{sig_str}"
    sig_md5 = Digest::MD5.hexdigest(sig_str)
    puts "[sig_md5] #=> #{sig_str}"
    sig_md5
  end

  # UTILS
  ########

  def sorted_param_str(params)
    # XXX lowercase + escaped values?
    params.sort_by{|k,v| k.to_s}.collect{|k,v| "#{k}=#{v}"}.join
  end


end
