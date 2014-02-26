require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'



class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params
    @already_built_response = false

  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    @res.body = content
    @res.content_type = type
    raise "You can't double render" if @already_built_response
     # @session.store_session(@res)
    @already_built_response = true
     @session.store_session(@res) if @session
  end

  # helper method to alias @already_rendered
  def already_rendered?
    @already_built_response

  end

  # set the response status code and header
  def redirect_to(url)
    @res.status = 302
    @res["location"] =  url
    # @res.set_redirect(302, url)
    raise "You can't double render" if @already_built_response
    @already_built_response = true
      @session.store_session(@res) if @session
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    contents = File.read("views/#{self.class.to_s.underscore}/#{template_name}.html.erb")
    template = ERB.new(contents).result(binding)
    render_content(template, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    self.render(name) unless already_rendered?
  end
end
