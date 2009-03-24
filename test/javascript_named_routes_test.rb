require 'rubygems'
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
    
    def test_js_generation
      get :index
      assert_response :success
      body = @response.body.gsub(/ +/, '')
      
      [
        '"users_path":route(["/","users"],[])',
        '"formatted_users_path":route(["/","users",".",_],["format"])',
        '"user_path":route(["/","users","/",_],["id"])',
        '"edit_user_path":route(["/","users","/",_,"/","edit"],["id"])',
        '"user_accounts_path":route(["/","users","/",_,"/","accounts"],["user_id"])',
        '"user_account_path":route(["/","users","/",_,"/","accounts","/",_],["user_id","id"])',
        '"edit_user_account_path":route(["/","users","/",_,"/","accounts","/",_,"/","edit"],["user_id","id"])'
      ].each do |expected|
        assert body.include?(expected)
      end
    end
    
    def test_js_routes
      require 'appscript'
      get :index
      
      safari = Appscript.app('Safari')
      window = safari.documents.get.first
      window.do_JavaScript(@response.body)
      {
        "Routes.users_path()" => "/users",
        "Routes.formatted_users_path({format: 'xml'})" => "/users.xml",
        "Routes.user_path(123)" => "/users/123",
        "Routes.user_path(123, {foo: 42})" => "/users/123?foo=42",
        "Routes.user_path({id: 123})" => "/users/123",
        "Routes.edit_user_path(123)" => "/users/123/edit",
        "Routes.edit_user_path({id: 123})" => "/users/123/edit",
        "Routes.edit_user_path({id: 123, foo: 42, bar: 43})" => "/users/123/edit?foo=42&bar=43",
        "Routes.user_accounts_path(123)" => "/users/123/accounts",
        "Routes.user_account_path(123, 456)" => "/users/123/accounts/456",
        "Routes.user_account_path({id: 456, user_id: 123})" => "/users/123/accounts/456",
        "Routes.edit_user_account_path(123, 456)" => "/users/123/accounts/456/edit",
        "Routes.edit_user_account_path(123, 456, {foo: 42})" => "/users/123/accounts/456/edit?foo=42"
      }.each_pair do |expr, expected|
        assert_equal expected, window.do_JavaScript(expr) 
      end
    rescue LoadError => e
      warn "Skipping JavaScript tests, want applescript"
    end
  end
end
