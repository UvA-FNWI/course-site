class Kramdown::Converter::CustomHtml < Kramdown::Converter::Html
	
	##
	# give tables some bootstrap attributes
	#
	def convert_table(el, indent)
		el.attr['class'] = 'kramdown-table'
		super
	end
	
	##
	# prefixes all local image src with the right directory in /public/course
	#
	def convert_img(el, indent)
		if el.attr['alt'] == 'videoplayer'
			return "<video src='#{cdn_url(el.attr['src'])}' controls preload='none' class='video-js vjs-default-skin' data-setup='{}'>"
		elsif el.attr['src'] && el.attr['src'] !~ /(^[\w]*:|^\/)/
			el.attr['src'] = File.join(@options[:asset_prefix], el.attr['src'])
		end
		super
	end
	
	##
	# prefixes all local links with the right directory in /public/course
	#
	def convert_a(el, indent)
		if @options[:cdn_prefix]
			el.attr['href'] = cdn_url(el.attr['href'])
		end
		# any hrefs not starting with proto: or / or # are relative and 
		# will be prefixed
		if el.attr['href'] && el.attr['href'] !~ /(^[\w]*:|^\/|^\#)/
			el.attr['href'] = File.join(@options[:asset_prefix], el.attr['href'])
		end
		super
	end
	
	##
	# simply abuse the kramdown math markers, transform 
	# them to ASCIImath.js markers
	#
	def convert_math(el, indent)
		"`#{el.value}`"
	end
	
	##
	# convert 'bold' text to kbd tag, which will display it as keyboard 
	# entry text
	#
	def convert_strong(el, indent)
		format_as_span_html('kbd', el.attr, inner(el, indent))
	end
	
	def convert_blockquote(el, opts)
		el.attr['class'] = 'protip'
        format_as_indented_block_html(el.type, el.attr, '<span class="glyphicon glyphicon-pushpin dropcap"></span>' + inner(el, indent), indent)
	end
	
	private
	
	def cdn_url(source)
		source.sub(/^cdn:\//, @options[:cdn_prefix])
	end
	
end
