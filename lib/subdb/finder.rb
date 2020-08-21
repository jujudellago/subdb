# Copyright (c) 2020 Julien Ramel
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'net/http'
require 'uri'
require 'cgi'
require 'digest/md5'
require 'net/http/post/multipart'

require 'subdb/version'
require 'subdb/client_utils'
require 'subdb/upload_cache'

module Subdb
  class Finder
    API     = "http://api.thesubdb.com/"
    SANDBOX = "http://sandbox.thesubdb.com/"

    class << self
      attr_accessor :test_mode

      def api_url
        test_mode ? SANDBOX : API
      end
    end

    self.test_mode = false

    attr_reader :hash, :path

    def initialize(hash)


      @hash = hash

    end

    def search
      res = request("search")
      Rails.logger.debug("search:"+res.inspect)
      check_get(res)
    end

    def download(languages = ["en"])
      res = request("download", :language => languages.join(","))
      check_get(res)
    end



    protected


    def user_agent
      "SubDB/1.0 (RubySubDB/#{VERSION}; http://github.com/wilkerlucio/subdb)"
    end

    def request(action, params = {}, body = nil)
      params = {:action => action, :hash => hash}.merge(params)
      
      url = URI.parse(self.class.api_url)
      fullurl=url.path + stringify_params(params)
      Rails.logger.debug("url:"+url.inspect+" params:"+params.inspect+" fullurl:"+fullurl)
      
      
      req = Net::HTTP::Get.new(fullurl)
      req["User-Agent"] = user_agent


      Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
    end

    def check_get(res)
      case res.code.to_s
      when "200" then res.body
      when "400" then fail "Malformed request"
      when "404" then nil
      else
        fail "Unexpected response code - #{res.code}"
      end
    end

    def stringify_params(params)
      params_string = []

      params.each do |key, value|
        next unless value

        key   = CGI.escape(key.to_s)
        value = CGI.escape(value.to_s)

        params_string << "#{key}=#{value}"
      end

      params_string.length.zero? ? "" : "?" + params_string.join("&")
    end
  end
end
