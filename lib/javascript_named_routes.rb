module JavascriptNamedRoutes  
  class RoutesController < ActionController::Base
    ROUTES_JS_PATH = "#{RAILS_ROOT}/public/javascripts/routes.js"
    
    def index
      respond_to do |format|
        format.js do
          generate_routes
          render :file => ROUTES_JS_PATH
        end
      end
    end
    
    private
    
    def path_info(route)
      segments = []
      keys = []
      route.segments.reject(&:optional?).each do |segment|
        if segment.class == ActionController::Routing::DynamicSegment
          segments << '_'
          keys << %Q~'#{segment.key}'~
        else
          segments << %Q~'#{segment.value}'~
        end
      end
      [segments, keys]
    end
    
    def generate_routes
      File.open(ROUTES_JS_PATH, 'w') do |output|
        output << %Q~var Routes = (function() {
  var _ = {};
  var _path = function(segments, keys, args) {
    var ki = 0;
    var next_arg;
    if (args.length == 1 && typeof args[0] == 'object') {
      args = args[0];
      next_arg = function() {
        return args[keys[ki++]];
      };
    } else {
      next_arg = function() {
        return args[ki++];
      };
    }
    for (var i = 0; i < segments.length; ++i) {
      if (segments[i] === _) {
        segments[i] = next_arg();
      }
    }
    return segments.join('');
  };
  return {
~
        routes = ActionController::Routing::Routes.named_routes
        separator = ''
        routes.names.sort_by(&:to_s).each do |name|
          segments, keys = path_info(routes[name])
          output << %Q~    #{separator}#{name}:
      function() {return _path([#{segments.join(',')}], [#{keys.join(',')}], arguments);}
~
          separator = ','
        end
        output << %Q~  };
}());
~
      end
    end
  end
  
  module Routing
    module MapperExtensions
      def javascript_named_routes
        @set.add_route 'javascripts/routes.js', :controller => 'javascript_named_routes/routes'
      end
    end
  end
  
  ActionController::Routing::RouteSet::Mapper.send :include, Routing::MapperExtensions
end
