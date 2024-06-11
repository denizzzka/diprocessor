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
