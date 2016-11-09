module JSONAPI
  class FilterStore
    attr_reader :filters

    def initialize(params)
      @params = params
      @filters = {}
      parse_filters(@params[:filter])
    end

    def filters_for(resource)
      name = resource.is_a? JSONAPI::Relationship ? relationship.name : relationship
      @filters[name]
    end

    def parse_filters(filters)
      return if filters.nil? || filters.empty?

      filters.each do |key, value|
        if key.include?("\.")
          parse_included_resource_filter(key, value)
        else
          parse_filter(key, value)
        end
      end
    end

    def parse_filter(key, value, resource_klass = nil)
      key = unformat_key(key)
      resource_klass ||= resource_for(@params[:controller])
      
      fail JSONAPI::Exceptions::FilterNotAllowed.new(value) unless validate_filter(key, resource_klass)

      @filters[key] = value
    end

    def parse_included_resource_filter(filter, value)
      *related, filter = filter.split(".")
      resource_klass = resource_for(related.split(".").last)
      parse_filter(filter, value, resource_klass)
    end

    def resource_for(name)
      return Resource.resource_for(name) if name
      fail JSONAPI::Exceptions::InvalidResource(name)
    end

    def validate_filter(filter, resource_klass)
       resource_klass && resource_klass._allowed_filter?(filter)
    end

    def add_default_filter(resource_klass = nil)
      resource_klass ||= resource_for(@params[:controller])

      resource_klass._allowed_filters.each do |filter, options|
        next if options[:default].nil? || !@filters[filter].nil?
        @filters[filter] = options[:defualt]
      end
    end

    def unformat_key(key)
      formatter = @options.fetch(:key_formatter, JSONAPI.configuration.key_formatter)
      unformatted_key = formatter.unformat(key)
      unformatted_key.nil? ? nil : unformatted_key.to_sym
    end
  end
end