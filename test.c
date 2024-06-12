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

char basename(const char *) __asm("" "__gnu_basename");

siginfo_t sgt;
typeof(sgt->si_signo) int_var;

static inline __attribute__((always_inline)) void __attribute__((always_inline)) rv_utils_wait_for_intr(void)
{
  __asm ("wfi\n");
}

static inline __attribute__((always_inline)) void *rv_utils_get_sp(void)
{
  void *sp;
  __asm ("mv %0, sp;" : "=r" (sp));
  return sp;
}

uint32_t iomux_reg_val = ({ 123; });

void func7(void)
{
  int r;
  r = 0b11111110;

  return ({ unsigned long __tmp; __tmp = 123; __tmp; });
}

void rv_utils_set_cycle_count(uint32_t ccount)
{
  ({ __asm ("csrw " "0x7e2" ", %0" :: "rK"(ccount) : "abc"(0x00000008)); });
}

_Static_assert (sizeof(efuse_dev_t) == 0x200, "Invalid size of efuse_dev_t structure");

typedef enum {
  E123 __attribute__((deprecated("please use 456"))) = 123,
} depr_t;

siginfo_t *s_slots[123] = {};
