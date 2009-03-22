module JavascriptNamedRoutes  
  class RoutesController < ActionController::Base
    prepend_view_path File.dirname(__FILE__) + '/../views'
    
    def index
      respond_to do |format|
        format.js do
          collect_routes
        end
      end
    end
    
    private
    
    def route_info(name, route)
      required = []
      optional = []
      segment_keys = []
      
      segments = required
      route.segments.each do |segment|
        segments = optional if segment != route.segments.first and segment.optional?
        if segment.is_a? ActionController::Routing::DynamicSegment
          segment_keys << segment.key.to_json
          segments << '_'
        else
          segments << segment.value.to_json
        end
      end
      
      optional.pop while !optional.empty? and optional.last != '_'
      
      name = "#{name}_path".to_json
      required = '[' + required.join(', ') + ']'
      optional = '[' + optional.join(', ') + ']'
      segment_keys = '[' + segment_keys.join(', ') + ']'
      [name, required, optional, segment_keys]
    end
    
    def collect_routes
      routes = ActionController::Routing::Routes.named_routes
      @route_data = routes.names.sort_by(&:to_s).collect do |name|
        route_info(name, routes[name])
      end
    end
  end
  
  module MapperExtensions
    def javascript_named_routes
      @set.add_route 'javascripts/routes.js', :controller => 'javascript_named_routes/routes'
    end
  end
  
  module ViewHelperExtensions
    def javascript_named_routes
      javascript_include_tag 'routes'
    end
  end
  
  ActionController::Routing::RouteSet::Mapper.send :include, MapperExtensions
  ActionView::Base.send :include, ViewHelperExtensions
end
