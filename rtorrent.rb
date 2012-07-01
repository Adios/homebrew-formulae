require 'formula'

class Rtorrent < Formula
  url 'http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.2.tar.gz'
  homepage 'http://libtorrent.rakshasa.no/'
  md5 '72c3e9ab859bda7cc8aa96c0b508b09f'

  depends_on 'Adios/formulae/gcc'
  depends_on 'pkg-config' => :build
  depends_on 'libsigc++'
  depends_on 'Adios/formulae/libtorrent'
  depends_on 'xmlrpc-c' => :optional

  def install
    ENV['CC'] = 'gcc-4.4'
    ENV['CXX'] = 'g++-4.4'

    args = ["--disable-debug", "--disable-dependency-tracking", "--prefix=#{prefix}"]
    args << "--with-xmlrpc-c" if Formula.factory("xmlrpc-c").installed?
    inreplace 'configure' do |s|
      s.gsub! '  pkg_cv_libcurl_LIBS=`$PKG_CONFIG --libs "libcurl >= 7.15.4" 2>/dev/null`',
              '  pkg_cv_libcurl_LIBS=`$PKG_CONFIG --libs "libcurl >= 7.15.4" | sed -e "s/-arch [^-]*//" 2>/dev/null`'
    end
    system "./configure", *args
    system "make"
    system "make install"
  end

  def patches
    # Patch for no posix_memalign() error under OSX 10.5 PowerPC.
    # piyokos @ http://libtorrent.rakshasa.no/ticket/2086
    DATA
  end
end

__END__
diff --git a/rak/allocators.h b/rak/allocators.h
index 0a1b711..b470167 100644
--- a/rak/allocators.h
+++ b/rak/allocators.h
@@ -74,17 +74,13 @@ public:
   size_type max_size () const throw() { return std::numeric_limits<size_t>::max() / sizeof(T); }

   pointer allocate(size_type num, const_void_pointer hint = 0) { return alloc_size(num*sizeof(T)); }
+  void deallocate (pointer p, size_type num) { dealloc_size(p, num*sizeof(T)); }

-  static pointer alloc_size(size_type size) {
-    pointer ptr = NULL;
-    int __UNUSED result = posix_memalign((void**)&ptr, LT_SMP_CACHE_BYTES, size);
-
-    return ptr;
-  }
+  static pointer alloc_size(size_type size);
+  static void dealloc_size(pointer p, size_type size);

   void construct (pointer p, const T& value) { new((void*)p)T(value); }
   void destroy (pointer p) { p->~T(); }
-  void deallocate (pointer p, size_type num) { free((void*)p); }
 };


@@ -98,6 +94,36 @@ bool operator!= (const cacheline_allocator<T1>&, const cacheline_allocator<T2>&)
   return false;
 }

+template <class T>
+inline typename cacheline_allocator<T>::pointer cacheline_allocator<T>::alloc_size(size_type size) {
+  pointer ptr;
+
+#if HAVE_POSIX_MEMALIGN
+  if (posix_memalign((void**)&ptr, LT_SMP_CACHE_BYTES, size))
+    return NULL;
+#else
+  char* org = (char*)malloc(size + sizeof(void*) + LT_SMP_CACHE_BYTES - 1);
+  if (org == NULL)
+    return NULL;
+
+  ptr = (pointer)((uintptr_t)(org + LT_SMP_CACHE_BYTES - 1) & ~(LT_SMP_CACHE_BYTES - 1));
+
+  // store originally allocated pointer for later free() at the end of the allocated data
+  *(void**)((char*)ptr + size) = org;
+#endif
+
+  return ptr;
+}
+
+template <class T>
+inline void cacheline_allocator<T>::dealloc_size(pointer p, size_type size) {
+#if HAVE_POSIX_MEMALIGN
+  free(p);
+#else
+  free(*(void**)((char*)p + size));
+#endif
+}
+
 }

 //
