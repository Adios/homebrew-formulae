require 'formula'

class Lftp < Formula
  homepage 'http://lftp.yar.ru/'
  url 'http://ftp.yars.free.net/pub/source/lftp/lftp-4.3.8.tar.bz2'
  sha1 '6e3b8165fa89781533f4af7350f62eb670ab26fe'

  depends_on 'pkg-config' => :build
  depends_on 'readline'

  def install
    # Bus error
    ENV.no_optimization if MacOS.leopard?

    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}", "--with-openssl"
    system "make install"
  end
end
