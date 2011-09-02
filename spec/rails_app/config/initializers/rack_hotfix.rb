# FIXME: Temporary monkey-patch to solve rack warnings
# See: http://blog.enricostahn.com/warning-regexp-match-n-against-to-utf-8-strin
# This is solved in rack 1.3, but rails stills requires rack 1.2
module Rack
  module Utils
    def escape(s)
      CGI.escape(s.to_s)
    end
    def unescape(s)
      CGI.unescape(s)
    end
  end
end
