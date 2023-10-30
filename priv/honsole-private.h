typedef __UINT64_TYPE__ ui64; 
typedef  __INT64_TYPE__ si64;

long CGSDefaultConnectionForThread(void);
long CGSSetWindowBackgroundBlurRadius(long cid, long wid, long blur);
si64 sandbox_check(int pid, const char * operation, ui64 filter);
