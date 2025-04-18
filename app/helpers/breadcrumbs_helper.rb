module BreadcrumbsHelper
  def breadcrumbs
    @breadcrumbs ||= []
  end

  def add_breadcrumb(text, path = nil)
    breadcrumbs << [ text, path ]
  end
end
