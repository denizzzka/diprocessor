int i;

typedef struct {
  int si_signo;
  int si_code;
} siginfo_t;

int fun1(int i){ return i; }

long var2 __attribute__((__aligned__(__alignof__(long))));

typedef struct {
long long var3 __attribute__((__aligned__(__alignof__(long long))));
} max_align_t;

int fun2(void){ return 123; }

int fun3(void){ fun2(); }

int fprintf (FILE *restrict, const char *restrict, ...)
              __attribute__ ((__format__ (__printf__, 2, 3)));

void *__attribute__((__nonnull__ (1))) fun4(void)
{
  fun2();
}
