require 'rubygems'
require 'open3'
require 'test/unit'
require 'action_controller'
require 'action_controller/test_process'

# initialization attempts to delete cached js under RAILS_ROOT
RAILS_ROOT = '/tmp'

# initialize the plugin
require File.dirname(__FILE__) + '/../init'

module JavascriptNamedRoutes
  class RoutesControllerTest < ActionController::TestCase
    def setup
      ActionController::Routing::Routes.draw do |map|
        map.resources :users do |users|
          users.resources :accounts
        end
        map.javascript_named_routes
      end
    end
    
    def test_action_success
      get :index
      assert_response :success
    end
    
    [
      '"usersPath":route(["/","users"],[])',
      '"userPath":route(["/","users","/",_],["id"])',
      '"editUserPath":route(["/","users","/",_,"/","edit"],["id"])',
      '"userAccountsPath":route(["/","users","/",_,"/","accounts"],["user_id"])',
      '"userAccountPath":route(["/","users","/",_,"/","accounts","/",_],["user_id","id"])',
      '"editUserAccountPath":route(["/","users","/",_,"/","accounts","/",_,"/","edit"],["user_id","id"])'
    ].each do |expected|
      route_name = expected.match(/^"(\w+)"/).captures.first
      define_method("test_js_generation_for_#{route_name}") do
        help_test_js_generation(expected)
      end
    end
    
    def help_test_js_generation(expected)
      get :index
      body = @response.body.gsub(/ +/, '')
      assert body.include?(expected), "@response.body should contain <#{expected}>"
    end
    
    # should be true if you have a Mac and JavaScript OSA installed
    if system('osascript -l JavaScript -e 0 2> /dev/null')
      {
        "Routes.usersPath()" => "/users",
        "Routes.usersPath({format: 'xml'})" => "/users.xml",
        "Routes.userPath(123)" => "/users/123",
        "Routes.userPath(123, {foo: 42})" => "/users/123?foo=42",
        "Routes.userPath({id: 123})" => "/users/123",
        "Routes.editUserPath(123)" => "/users/123/edit",
        "Routes.editUserPath({id: 123})" => "/users/123/edit",
        "Routes.editUserPath({id: 123, foo: 42, bar: 43})" => "/users/123/edit?foo=42&bar=43",
        "Routes.userAccountsPath(123)" => "/users/123/accounts",
        "Routes.userAccountPath(123, 456)" => "/users/123/accounts/456",
        "Routes.userAccountPath({id: 456, user_id: 123})" => "/users/123/accounts/456",
        "Routes.editUserAccountPath(123, 456)" => "/users/123/accounts/456/edit",
        "Routes.editUserAccountPath(123, 456, {foo: 42})" => "/users/123/accounts/456/edit?foo=42"
      }.each_pair do |expr, expected|
        route_name = expr.match(/^Routes\.(\w+)/).captures.first
        define_method("test_js_route_for_#{route_name}") do
          help_test_js_route(expr, expected)
        end
      end
    else
      warn "Skipping JavaScript tests, want Javascript OSA"
    end
    
    def help_test_js_route(expr, expected)
      get :index
      Open3.popen3('osascript', '-l', 'JavaScript') do |input, output|
        input << @response.body << expr
        input.close
        assert_equal expected, output.readline.chomp
      end
    end
  end
end
