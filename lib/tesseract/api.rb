#--
# Copyright 2011 meh. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY meh ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL meh OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of meh.
#++

require 'namedic'
require 'tesseract/c'

module Tesseract

class API
	Types = {
		int:    [:integer],
		bool:   [:boolean],
		double: [:float],
		string: [:str]
	}

	def initialize
		@internal = C::create

		ObjectSpace.define_finalizer self, self.class.finalizer(to_ffi)
	end

	def self.finalizer (pointer)
		proc {
			C::destroy(pointer)
		}
	end

	def version
		C::version(to_ffi)
	end

	def input_name= (name)
		C::set_input_name(to_ffi, name)
	end

	def output_name= (name)
		C::set_output_name(to_ffi, name)
	end

	def set_variable (name, value)
		C::set_variable(to_ffi, name, value)
	end

	def get_variable (name, type = nil)
		if type.nil?
			type = Types.keys.find { |type| C.__send__ "has_#{type}_variable", name }

			C.__send__ "get_#{type}_variable", name
		else
			unless Types.has_key?(type)
				name, aliases = Types.find { |name, aliases| aliases.member?(type) }

				raise ArgumentError, "unknown type #{type}" unless name

				type = name
			end

			if C.__send__ "has_#{type}_variable", name
				C.__send__ "get_#{type}_variable", name
			end
		end
	end

	def init (datapath, language, mode = :DEFAULT)
		C::init(to_ffi, datapath, language.to_s, mode)
	end

	def read_config_file (path, init_only = true)
		C::read_config_file(to_ffi, path, init_only)
	end

	def page_seg_mode
		C::get_page_seg_mode(to_ffi)
	end

	def page_seg_mode= (value)
		C::set_page_seg_mode(to_ffi, value)
	end

	def set_image (pix)
		C::set_image(to_ffi, pix)
	end

	namedic :left, :top, :width, :height,
		:alias => { :l => :left, :t => :top, :w => :width, :h => :height }
	def set_rectangle (left, top, width, height)
		C::set_rectangle(to_ffi, left, top, width, height)
	end

	def get_text
		pointer = C::get_utf8_text(to_ffi)
		result  = pointer.read_string
		result.force_encoding 'UTF-8'
		C::free_string(pointer)

		result
	end

	def to_ffi
		@internal
	end
end

end
