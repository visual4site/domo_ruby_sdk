require "domo_ruby_sdk/version"
require 'date'
require 'rest-client'
require 'json'

module DomoRubySdk

  class SdkException < StandardError
    def initialize(message)
      super(message)
    end

    # returns a ops user readable stacktrace.
    def stacktrace(ex)
      ex.backtrace.select do |t| 
        (t =~ /gem/) == nil && (t =~ /rvm/) == nil
      end.join('\n')
    end
  end

  class HttpException < SdkException
    attr_reader :status_code
    attr_reader :server_error

    def initialize(status_code, message)
      @status_code = status_code
      @server_error = message
      super(message)
    end

    def to_s
      return "API Request Failed. HTTP " + self.status_code.to_s + " -> " + self.server_error 
    end

  end
  
  class Api
    @@auth_endpoint = 'https://api.domo.com/oauth/token'
    @@datasets_endpoint = 'https://api.domo.com/v1/datasets'
    @@streams_endpoint = 'https://api.domo.com/v1/streams'

    def initialize(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
    end

    def access_token
      @access_token
    end

    def authenticated?
      @access_token != nil
    end

    # gets the access token for the API
    def authenticate
      if @client_id.length < 1 || @client_secret.length < 1
        raise SdkException.new('missing parameters: client_id, client_secret')
      end
      url_with_params = @@auth_endpoint + '?grant_type=client_credentials&scope=data'
      response = RestClient::Request.execute(
        url: url_with_params,
        user: @client_id,
        password: @client_secret,
        method: :post
      )
      body = JSON.parse(response.body)
      @access_token = body['access_token']
      self
    end

    # first method I'm using to test the authentication,
    # this will return the json object of the response from Domo.
    def get_datasets
      authenticate unless authenticated?
      response = RestClient::Request.execute(
        url: @@datasets_endpoint,
        method: :get,
        headers: headers('application/json')
      )
      return response
    end


    # used for fetching data from a dataset.
    # currently only fetching the whole dataset is implemented,
    def query_dataset(domo_dataset_id)
      authenticate unless authenticated?
      headers = {
        'Authorization': "Bearer #{@access_token}",
        'Accept': 'text/csv'
      }
      endpoint = "#{@@datasets_endpoint}/#{domo_dataset_id}/data?includeHeader=true&fileName=#{domo_dataset_id}.csv"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :get,
        headers: headers
      )
      if response.code != 200
        raise SdkException::HttpException(response.status, response.message)
      end
      return response.body
    end


    # returns the Domo metadata about the dataset.
    def get_dataset_metadata(domo_dataset_id)
      authenticate unless authenticated?
      endpoint = "#{@@datasets_endpoint}/#{domo_dataset_id}"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :get,
        headers: headers('application/json')
      )
      return JSON.parse(response.body)
    end


    # returns the domo dataset_id if successful.
    def create_dataset(name, description, columns)
      authenticate unless authenticated?
      payload = {
        name: name,
        description: description,
      }
      schema = {columns: []}
      columns.each { |col| schema[:columns].push(col) }
      payload[:schema] = schema
      response = RestClient::Request.execute(
        url: @@datasets_endpoint,
        method: :post,
        headers: headers('application/json'),
        payload: JSON.generate(payload)
      )
      return JSON.parse(response.body)
    end

    def update_dataset(dataset_id, columns)
      authenticate unless authenticated?
      payload = {}
      schema = {columns: []}
      columns.each { |col| schema[:columns].push(col) }
      payload[:schema] = schema
      response = RestClient::Request.execute(
        url: "#{@@datasets_endpoint}/#{dataset_id}",
        method: :put,
        headers: headers('application/json'),
        payload: JSON.generate(payload)
      )
      return JSON.parse(response.body)
    end

    # a non-stream append of data to a dataset. useful for only small
    # amounts of data.
    def append_dataset(dataset_id, csv_data)
      authenticate unless authenticated?
      headers = {
        'Content-Type': 'text/csv',
        'Authorization': "Bearer #{@access_token}",
        'Accept': 'application/json'
      }
      endpoint = "#{@@datasets_endpoint}/#{dataset_id}/data?updateMethod=APPEND"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :put,
        headers: headers,
        payload: csv_data
      )
      return response
    end

    # a non-stream replace of data to a dataset. useful for only small
    # amounts of data.
    def replace_dataset(dataset_id, csv_data)
      authenticate unless authenticated?
      headers = {
        'Content-Type': 'text/csv',
        'Authorization': "Bearer #{@access_token}",
        'Accept': 'application/json'
      }
      endpoint = "#{@@datasets_endpoint}/#{dataset_id}/data"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :put,
        headers: headers,
        payload: csv_data
      )
      return response
    end

    # creates a stream associated with the given dataset, for
    # streaming data via executions to the dataset.
    def create_dataset_stream(name, description, columns, method = 'APPEND')
      authenticate unless authenticated?
      payload = {
        "dataSet": {
          name: name,
          description: description,
          columns: columns.length,
          schema: { columns: columns }
        },
        updateMethod: method
      }
      response = RestClient::Request.execute(
        url: @@streams_endpoint,
        method: :post,
        headers: headers('application/json'),
        payload: JSON.generate(payload)
      )
      return JSON.parse(response.body)
    end

    # creates a stream execution with which data can be sent.
    def create_stream_execution(stream_id)
      authenticate unless authenticated?
      endpoint = "#{@@streams_endpoint}/#{stream_id}/executions"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :post,
        headers: headers('application/json')
      )
      return JSON.parse(response.body)
    end

    # upload csv data as one part of the stream execution.
    def upload_stream_data_part(stream_id, execution_id, part_no, csv_data)
      authenticate unless authenticated?
      headers = {
        'Content-Type': 'text/csv',
        'Authorization': "Bearer #{@access_token}",
        'Accept': 'application/json'
      }
      endpoint = "#{@@streams_endpoint}/#{stream_id}/executions/#{execution_id}/part/#{part_no}"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :put,
        headers: headers,
        payload: csv_data
      )
      return JSON.parse(response.body)
    end


    # call this when finished with stream upload. Otherwise Dataset will remain locked
    # in Domo.
    def finalize_stream_execution(stream_id, execution_id)
      authenticate unless authenticated?
      endpoint = "#{@@streams_endpoint}/#{stream_id}/executions/#{execution_id}/commit"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :put,
        headers: headers('application/json')
      )
      return JSON.parse(response.body)
    end

    # call this if there is an exception during stream uploading for 1 execution.
    def abort_stream_execution(stream_id, execution_id)
      authenticate unless authenticated?
      endpoint = "#{@@streams_endpoint}/#{stream_id}/executions/#{execution_id}/abort"
      response = RestClient::Request.execute(
        url: endpoint,
        method: :put,
        headers: headers('application/json')
      )
      return JSON.parse(response.body)
    end

    # this is an unrecoverable action. Really only used at this point for cleaning
    # up after tests.
    def delete_dataset(domo_dataset_id)
      authenticate unless authenticated?
      response = RestClient::Request.execute(
        url: "#{@@datasets_endpoint}/#{domo_dataset_id}",
        method: :delete,
        headers: headers('application/json')
      )
      return response
    end

    @access_token = nil

    private

    def headers(content_type)
      headers = {
        'Content-Type': content_type,
        'Authorization': "Bearer #{@access_token}",
        'Accept': 'application/json', 
        'accept-encoding': 'None'
      }
      headers
    end
  end
end
