int i;

typedef struct {
  int si_signo;
  int si_code;
} siginfo_t;

int fun1(int i){ return i; }

uint64_t systimer_us_to_ticks(uint64_t us) __attribute__((const));

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
  __asm volatile(".cfi_undefined ra");
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

  arg = __builtin_va_arg(r, int);

  return ({ unsigned long __tmp; __tmp = 123; __tmp; });
}

void rv_utils_set_cycle_count(uint32_t ccount)
{
  ({ __asm ("csrw " "0x7e2" ", %0" :: "rK"(ccount) : "abc"(0x00000008)); });
}

_Static_assert (sizeof(efuse_dev_t) == 0x200, "Invalid size of efuse_dev_t structure");

void func88(void) {
  _Static_assert(
    sizeof(result->ssid) == sizeof(record->ssid),
    "source and destination should be of same size"
  );
}

typedef enum {
  E123 __attribute__((deprecated("please use 456"))) = 123,
} depr_t;

siginfo_t *s_slots[123] = {};

typedef _Atomic int atomic_int;

void intr_handler_set(int int_no, intr_handler_t fn, void *arg)
{
    intr_handler_item_t* item = intr_get_item(int_no);

    *item = (intr_handler_item_t) {
        .handler = fn,
        .arg = arg,
        [0 ... 64-1] = 123
    };
}

typedef struct __attribute__((packed)) socks_request {
  uint8_t version;
} socks_request_t;

static int lwip_ioctl_r_wrapper(int fd, int cmd, va_list args)
{
  return lwip_ioctl(fd, cmd, __builtin_va_arg(args, void*));
}

void hostapd_cleanup(struct hostapd_data *hapd)
{
  tmp = __builtin_offsetof (struct hostapd_sae_commit_queue, list);
  extern uint32_t __global_pointer$;

  __asm(
    "sw %1, 0(%0)\n"
    "beqz t0, .Lwaitsleep\n"
    :
    : "r" ((0x600c0000 + 0x048)),
      "r" ((CRC_START_ADDR << 8) | (CRC_LEN << 20)),
      "r" (((1UL << (8)))),
      "r" (((1UL << (1))) | ((1UL << (0))))
    : "t0",
    "t1"
  );
}
