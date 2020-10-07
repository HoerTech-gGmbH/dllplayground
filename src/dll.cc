#include "dll.h"
#include <time.h>
#include <cmath>
#include <limits>

#ifndef M_PI
#define M_PI 3.141592653589793115997963468544185161591
#endif

cfg_t::cfg_t(const double srate, const double fragsize, const double bandwidth,
                  const std::string& clock_source_name, const double adjustment)
    : F(srate / fragsize),
      B(bandwidth), b(sqrt(8) * M_PI * B / F), c(b * b / 2),
      nper(fragsize),
      tper(fragsize / srate),
      adjustment(adjustment)
{
#define checkassignclocksource(whichclock)                                     \
  if(clock_source_name == #whichclock)                                         \
    clock_source = whichclock;
#ifdef CLOCK_REALTIME
  checkassignclocksource(CLOCK_REALTIME);
#endif
#ifdef CLOCK_REALTIME_COARSE
  checkassignclocksource(CLOCK_REALTIME_COARSE);
#endif
#ifdef CLOCK_MONOTONIC
  checkassignclocksource(CLOCK_MONOTONIC);
#endif
#ifdef CLOCK_MONOTONIC_COARSE
  checkassignclocksource(CLOCK_MONOTONIC_COARSE);
#endif
#ifdef CLOCK_MONOTONIC_RAW
  checkassignclocksource(CLOCK_MONOTONIC_RAW);
#endif
#ifdef CLOCK_BOOTTIME
  checkassignclocksource(CLOCK_BOOTTIME);
#endif
#ifdef CLOCK_PROCESS_CPUTIME_ID
  checkassignclocksource(CLOCK_PROCESS_CPUTIME_ID);
#endif
#ifdef CLOCK_THREAD_CPUTIME_ID
  checkassignclocksource(CLOCK_THREAD_CPUTIME_ID);
#endif
}

std::pair<double, double> cfg_t::process()
{
  struct timespec timespec = {.tv_sec = 0, .tv_nsec = 0};
  double unfiltered_time = std::numeric_limits<double>::quiet_NaN();
  if(clock_gettime(clock_source, &timespec) == 0)
    unfiltered_time = timespec.tv_sec + timespec.tv_nsec * 1e-9;
  filter_time(unfiltered_time);
  return {t0 + adjustment, t1 + adjustment};
}

double cfg_t::filter_time(double unfiltered_time)
{
  if(n1 == 0U)
    return dll_init(unfiltered_time);
  return dll_update(unfiltered_time);
}

double cfg_t::dll_init(double unfiltered_time)
{
  e2 = tper;
  t0 = unfiltered_time;
  t1 = t0 + e2;
  n0 = 0;
  n1 = nper;
  return t0;
}

double cfg_t::dll_update(double unfiltered_time)
{
  e = unfiltered_time - t1;
  t0 = t1;
  t1 += b * e + e2;
  e2 += c * e;
  n0 = n1;
  n1 += nper;
  return t0;
}

// Local variables:
// compile-command: "make -C .."
// c-basic-offset: 4
// indent-tabs-mode: nil
// coding: utf-8-unix
// End:
