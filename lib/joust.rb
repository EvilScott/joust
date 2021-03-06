require 'json'
require 'rest-client'
require File.join('joust','expected_response.rb')
require File.join('joust','expected_response','version_12.rb')
require File.join('joust','expected_response','version_20.rb')

class Joust

  # run each version spec and return results
  def self.run(url, options, test_cases)
    specs = self.new(url, test_cases[options[:version]], options[:version])
    puts specs.check
  end

  # initialize an instance to test a specific version
  def initialize(url, test_cases, version)
    @url, @test_cases, @version = url, test_cases, version
  end

  # run specification checks and return results
  def check
    num_tests = passed_tests = 0
    results = @test_cases.map(&:flatten).inject([]) do |results, test|
      test_name, sent, expected = test.first, test.last.first, test.last.last
      resp = RestClient.post(@url, sent, :content_type => 'application/json')
      num_tests += 1
      json_hash = JSON.parse(resp.body) rescue {}
      if expected.is_a?(Array)
        pass = expected.inject(true) { |pass, exp| pass = false unless exp.match?(json_hash.shift); pass }
      else
        pass = expected.match?(json_hash)
      end
      if !!pass
        passed_tests += 1
        result_output = 'PASS'
      else
        result_output = 'FAIL: ' + resp.body
      end
      results << "#{@version} #{test_name} -- #{result_output}"
      results
    end
    results << "JSON-RPC #{@version}: #{passed_tests}/#{num_tests} tests passed"
  end

end