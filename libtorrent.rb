require 'formula'

class Libtorrent < Formula
  homepage 'http://libtorrent.rakshasa.no/'
  url 'http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.2.tar.gz'
  md5 '96c0b81501357df402ab592f59ecaeab'

  depends_on 'Adios/formulae/gcc' => :build
  depends_on 'pkg-config' => :build
  depends_on 'libsigc++'

  def install
    ENV['CC'] = 'gcc-4.7'
    ENV['CXX'] = 'g++-4.7'
    ENV['OPENSSL_LIBS'] = '-lcrypto -lssl'
    ENV['OPENSSL_CFLAGS'] = '-I/usr/include'

    system "./configure", "--prefix=#{prefix}",
                          "--disable-debug",
                          "--disable-dependency-tracking",
                          "--with-kqueue",
                          "--enable-ipv6"
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
