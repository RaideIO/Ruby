require 'json'
require 'httparty'

#
# Raide API
#
# @funcs  initialize( account_id, api_key, api_password )
#         parse_results( results )
#         comment( id, comment, is_external_id )
#         delete( id, is_external_id )
#         get( id, datatype, is_external_id )
#         search( parameters )
#         submit( base64_summary, requester, comment, external_id )
#         update( id, status, is_external_id )

class RaideAPI
  include HTTParty
  format :json
  base_uri 'http://api.raide.io/1.0/'
  headers "User-Agent" => 'Raide/1.0 (Ruby)'

  #
  # When an instance of this class is initialized.
  #
  # @param int      account_id    Raide Account ID.
  # @param string   api_key       Raide API Key.
  # @param string   api_password  Raide API Password.
  #   

  def initialize(account_id = 0, api_key = "", api_password = "")
    @accountId = account_id
    @apiKey = api_key
    @apiPassword = api_password
    # // Append an Authentication header with the Account's ID, API Key and API Password.
    @header = "id=#{@accountId};key=#{@apiKey};password=#{@apiPassword}"
  end

  def comment(id = 0, comment = "", is_external_id = false)
    begin

      response = self.class.post("/comment/#{id}", :body => {"comment" => "hello"}, :headers => {"Authentication" => @header} )
      return parse_results([response.code, response.body])

    rescue => e
      raise e
    end
  end

  #
  # Delete a Ticket.
  # 
  # @param  mixed id              Either the Ticket ID, or an External ID.
  # @param  bool  is_external_id  If this is an External ID, set as true.
  # @return bool
  #   

  def delete(id = 0, is_external_id = false)
    begin
      if is_external_id
        url = "/delete/external/#{id}"
      else
        url = "/delete/#{id}"
      end

      response = self.class.delete(url, :headers => {"Authentication" => @header})
      return parse_results([response.code, response.body])

    rescue => e
      raise e
    end
  end

  # 
  # Retrieve a Ticket.
  # 
  # @param  mixed   id              Either the Ticket ID, or an External ID.
  # @param  string  datatype        [json|text]
  # @param  bool    is_external_id  If this is an External ID, set as true.
  # @return array
  #   

  def get(id = nil, datatype = "json", is_external_id = false)
    begin
      if is_external_id
        url = "/get/external/#{id}/#{datatype}"
      else
        url = "/get/#{id}/#{datatype}"
      end

      response = self.class.get(url, :headers => {"Authentication" => @header})
      return parse_results([response.code, response.body])

    rescue => e
      raise e
    end
  end
  
  # 
  # Search through existing Tickets.
  # 
  # @param  array parameters
  # @return array
  #   

  def search(parameters = {})
    begin
      possible = ['endTime', 'limit', 'page', 'search', 'sort_by', 'sort_order', 'startTime', 'status']

      response = self.class.get("/search", :body => parameters.delete_if {|key, value| !possible.include?(key)}, :headers => {"Authentication" => @header})
      return parse_results([response.code, response.body])

    rescue => e
      raise e
    end
  end

  #
  # Submit a Ticket.
  # 
  # @param  string  base64_summary
  # @param  string  subject     
  # @param  string  description
  # @param  mixed   requester       Either an e-mail address, or an array {id, email, name}.  
  # @param  string  external_id
  # @return array
  #

  #server varible is accesible because of http://clearcove.ca/2008/08/recipe-make-request-environment-available-to-models-in-rails/
  def submit(base64_summary, subject, description, requester, external_id = '' )
    begin
      parameters = {"summary" => base64_summary, "subject" => subject, "description" => description, "external_id" => external_id, "requester" => requester, "server" => Thread.current[:env]}

      response = self.class.post("/submit", :body => parameters, :headers => {"Authentication" => @header})

      return parse_results([response.code, response.body])
    rescue => e
      raise e
    end
  end

  #
  # Update the status of a Ticket.
  # 
  # @param  mixed id              Either the Ticket ID, or an External ID.
  # @param  int   status          [1=Pending, 2=Open, 3=Solved]
  # @param  bool  is_external_id  If this is an External ID, set as true.
  # 
  
  def update(id = nil, status = 1, is_external_id = false)
    begin
      parameters = {
        "status" => status
      }

      response = self.class.put("/update/#{id}", :body => parameters, :headers => {"Authentication" => @header})
      return parse_results([response.code, response.body])
    rescue => e
      raise e
    end
  end

  private

  #
  # Check whether or not the cURL request was successful.
  # 
  # @param  array [httpCode, rawResponse]
  # @return array
  #   

  def parse_results(results)
    httpCode = results[0]
    rawResponse = results[1]

    codes = {"401" => "You are Unauthorized.", "403" => "You are Forbidden."}

    if httpCode == 200
      returned = JSON.parse(rawResponse)

      #needs testing if it is 0 or "0"
      if returned["error"] == 0
        return returned["result"]
      else
        error = returned["errorDescription"]
      end

    elsif codes.has_key?(httpCode.to_s)
      error = codes[httpCode.to_s]
    else
      error = "An error has occurred."
    end

    raise error
  end

end
