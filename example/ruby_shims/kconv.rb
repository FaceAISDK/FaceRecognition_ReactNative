# frozen_string_literal: true

# Ruby 3.4+/4.0 removed the old stdlib `kconv`, but some CocoaPods-related
# gems (notably CFPropertyList 3.x via xcodeproj) still require it.
# This shim provides the small compatibility surface they expect and delegates
# actual conversion work to the modern `nkf` gem.
require 'nkf'

module Kconv
  AUTO = :auto
  JIS = :jis
  EUC = :euc
  SJIS = :sjis
  UTF8 = :utf8
  BINARY = :binary
  NOCONV = :noconv

  OUTPUT_FLAGS = {
	JIS => '-j',
	EUC => '-e',
	SJIS => '-s',
	UTF8 => '-w',
	BINARY => '-w8',
	NOCONV => ''
  }.freeze

  module_function

  def kconv(str, to_enc, _from_enc = AUTO)
	NKF.nkf(OUTPUT_FLAGS.fetch(normalize_encoding(to_enc), '-w'), str.to_s)
  end

  def tojis(str)
	kconv(str, JIS)
  end

  def toeuc(str)
	kconv(str, EUC)
  end

  def tosjis(str)
	kconv(str, SJIS)
  end

  def toutf8(str)
	kconv(str, UTF8)
  end

  def tolocale(str)
	str.to_s
  end

  def normalize_encoding(encoding)
	case encoding
	when String
	  encoding.downcase.to_sym
	else
	  encoding
	end
  end
end

class String
  def kconv(to_enc, from_enc = Kconv::AUTO)
	Kconv.kconv(self, to_enc, from_enc)
  end

  def tojis
	Kconv.tojis(self)
  end

  def toeuc
	Kconv.toeuc(self)
  end

  def tosjis
	Kconv.tosjis(self)
  end

  def toutf8
	Kconv.toutf8(self)
  end

  def tolocale
	Kconv.tolocale(self)
  end
end

