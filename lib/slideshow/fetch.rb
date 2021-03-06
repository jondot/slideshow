module Slideshow
  module Fetch
  
  def fetch_file( dest, src )
    logger.debug "fetch( dest: #{dest}, src: #{src})"

    uri = URI.parse( src )
  
    # new code: honor proxy env variable HTTP_PROXY
    proxy = ENV['HTTP_PROXY']
    proxy = ENV['http_proxy'] if proxy.nil?   # try possible lower/case env variable (for *nix systems) is this necessary??
    
    if proxy
      proxy = URI.parse( proxy )
      logger.debug "using net http proxy: proxy.host=#{proxy.host}, proxy.port=#{proxy.port}"
      if proxy.user && proxy.password
        logger.debug "  using credentials: proxy.user=#{proxy.user}, proxy.password=****"
      else
        logger.debug "  using no credentials"
      end
    else
      logger.debug "using direct net http access; no proxy configured"
      proxy = OpenStruct.new   # all fields return nil (e.g. proxy.host, etc.)
    end
  
    # same as short-cut: http_proxy.get_respone( uri )
    # use full code for easier changes
    
    http_proxy = Net::HTTP::Proxy( proxy.host, proxy.port, proxy.user, proxy.password )
    http       = http_proxy.new( uri.host, uri.port )
    request    = Net::HTTP::Get.new( uri.request_uri )
    response   = http.request( request )  
  
    unless response.code == '200'   # note: responsoe.code is a string
      msg = "#{response.code} #{response.message}" 
      puts "*** error: #{msg}"
      return   # todo: throw StandardException?
    end

    logger.debug "  content_type: #{response.content_type}, content_length: #{response.content_length}"
  
    # check for content type; use 'wb' for images
    if response.content_type =~ /image/
      logger.debug '  switching to binary'
      flags = 'wb'
    else
      flags = 'w'
    end
  
    File.open( dest, flags ) do |f|
      f.write( response.body )	
    end
  end
  
  
  def fetch_slideshow_templates
    logger.debug "fetch_uri=#{opts.fetch_uri}"
    
    src = opts.fetch_uri
    
    ## check for builtin shortcut (assume no / or \) 
    if src.index( '/' ).nil? && src.index( '\\' ).nil?
      shortcut = src.clone
      src = config.map_fetch_shortcut( src )
      
      if src.nil?
        puts "** Error: No mapping found for fetch shortcut '#{shortcut}'."
        return
      end
      puts "  Mapping fetch shortcut '#{shortcut}' to: #{src}"
    end
    
    
    # src = 'http://github.com/geraldb/slideshow/raw/d98e5b02b87ee66485431b1bee8fb6378297bfe4/code/templates/fullerscreen.txt'
    # src = 'http://github.com/geraldb/sandbox/raw/13d4fec0908fbfcc456b74dfe2f88621614b5244/s5blank/s5blank.txt'
    uri = URI.parse( src )
  
    logger.debug "host: #{uri.host}, port: #{uri.port}, path: #{uri.path}"
  
    dirname  = File.dirname( uri.path )    
    basename = File.basename( uri.path, '.*' ) # e.g. fullerscreen     (without extension)
    filename = File.basename( uri.path )       # e.g. fullerscreen.txt (with extension)

    logger.debug "dirname: #{dirname}"
    logger.debug "basename: #{basename}, filename: #{filename}"

    dlbase = "http://#{uri.host}:#{uri.port}#{dirname}"
    pkgpath = File.expand_path( "#{config_dir}/templates/#{basename}" )
  
    logger.debug "dlpath: #{dlbase}"
    logger.debug "pkgpath: #{pkgpath}"
  
    FileUtils.makedirs( pkgpath ) unless File.directory? pkgpath 
   
    puts "Fetching template package '#{basename}'"
    puts "  : from '#{dlbase}'"
    puts "  : saving to '#{pkgpath}'"
  
    # download manifest
    dest = "#{pkgpath}/#{filename}"

    puts "  Downloading manifest '#{filename}'..."

    fetch_file( dest, src )

    manifest = load_manifest_core( dest )
      
    # download templates listed in manifest
    manifest.each do |values|
      values[1..-1].each do |file|
      
        dest = "#{pkgpath}/#{file}"

        # make sure path exists
        destpath = File.dirname( dest )
        FileUtils.makedirs( destpath ) unless File.directory? destpath
    
        src = "#{dlbase}/#{file}"
    
        puts "  Downloading template '#{file}'..."
        fetch_file( dest, src )
      end
    end   
    puts "Done."  
  end  
    
  end # module  Fetch
end # module Slideshow

class Slideshow::Gen
  include Slideshow::Fetch
end    
