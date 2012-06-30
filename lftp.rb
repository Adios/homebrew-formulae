require 'formula'

class Lftp < Formula
  homepage 'http://lftp.yar.ru/'
  url 'http://ftp.yars.free.net/pub/source/lftp/lftp-4.3.7.tar.bz2'
  sha1 'fe90aaa453537fdfbb199389a983dbf03901a87c'

  depends_on 'pkg-config' => :build
  depends_on 'readline'

  def install
    # Bus error
    ENV.no_optimization if MacOS.leopard?

    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}", "--with-openssl"
    system "make install"
  end
end
