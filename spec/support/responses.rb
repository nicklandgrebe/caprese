module Responses
  # Returns the JSON response body as a Ruby object
  def json
    @json ||= JSON.parse(response.body)
  end
end
