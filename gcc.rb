require 'formula'

class Gcc < Formula
  homepage 'http://gcc.gnu.org'
  url 'http://ftpmirror.gnu.org/gcc/gcc-4.4.7/gcc-4.4.7.tar.bz2'
  md5 '295709feb4441b04e87dea3f1bab4281'

  depends_on 'gmp'
  depends_on 'mpfr'

  skip_clean :all

  def install
    gmp = Formula.factory 'gmp'
    mpfr = Formula.factory 'mpfr'

    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete 'LD'

    # Sandbox the GCC lib, libexec and include directories so they don't wander
    # around telling small children there is no Santa Claus. This results in a
    # partially keg-only brew following suggestions outlined in the "How to
    # install multiple versions of GCC" section of the GCC FAQ:
    #     http://gcc.gnu.org/faq.html#multiple
    gcc_prefix = prefix + 'gcc'

    args = [
      "--prefix=#{gcc_prefix}",
      "--datadir=#{share}",
      "--bindir=#{bin}",
      "--program-suffix=-#{version.slice(/\d\.\d/)}",
      "--with-gmp=#{gmp.prefix}",
      "--with-mpfr=#{mpfr.prefix}",
      "--with-system-zlib",
      "--enable-checking"
    ]

    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system '../configure', "--enable-languages=c,c++", *args
      system 'make bootstrap'
      system 'make install'
    end
  end
end
