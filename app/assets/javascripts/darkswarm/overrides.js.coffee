Foundation.libs.section.toggle_active = (e)->
  $this = $(this)
  self = Foundation.libs.section
  region = $this.parent()
  content = $this.siblings(self.settings.content_selector)
  section = region.parent()
  settings = $.extend({}, self.settings, self.data_options(section))
  prev_active_region = section.children(self.settings.region_selector).filter("." + self.settings.active_class)
  
  #for anchors inside [data-section-title]
  e.preventDefault()  if not settings.deep_linking and content.length > 0
  e.stopPropagation() #do not catch same click again on parent
  unless region.hasClass(self.settings.active_class)
    prev_active_region.removeClass self.settings.active_class
    region.addClass self.settings.active_class
    #force resize for better performance (do not wait timer)
    self.resize region.find(self.settings.section_selector).not("[" + self.settings.resized_data_attr + "]"), true
  else if not settings.one_up# and (self.small(section) or self.is_vertical_nav(section) or self.is_horizontal_nav(section) or self.is_accordion(section))
    region.removeClass self.settings.active_class  
  settings.callback section
