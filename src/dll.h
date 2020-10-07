#ifndef DLL_H
#define DLL_H

#include <string>

/** Runtime configuration class of MHA plugin which implements the time
        smoothing filter described in
        Fons Adriensen: Using a DLL to filter time. 2005.
        http://kokkinizita.linuxaudio.org/papers/usingdll.pdf */
class cfg_t {
public:
  cfg_t(const double srate, const double fragsize, const double bandwidth, const std::string& clock_source_name,
        const double adjustment = 0);
  virtual ~cfg_t() = default;
  /** Block update rate / Hz */
  const double F;

  /** Bandwidth of block update rate */
  const double B;

  /** 0th order parameter, always 0 */
  static constexpr double a = 0.0f;

  /** 1st order parameter, sqrt(2)2piB/F */
  const double b;

  /** 2nd order parameter, (2piB/F)^2 */
  const double c;

  /** number of samples per block */
  const uint64_t nper;

  /** nominal duration of 1 block in seconds */
  const double tper;

  /** Adjustment added to the filtered time stamps (in seconds) */
  const double adjustment;

  /** which clock clock_gettime should use */
  clockid_t clock_source;

  /** actual duration of 1 block of audio, in seconds.
   * Initialized to nominal block duration at startup and after
   * dropouts, then adapted to measured duration by the dll. */
  double e2;

  /** start time of the current block as predicted by the dll. */
  double t0;

  /** start time of the next block as predicted by the dll. */
  double t1;

  /** Total sample index of first sample in current block.
   * Reset to zero for every dropout. */
  uint64_t n0 = {0U};

  /** Total sample index of first sample in next block.
   * Reset to zero for every dropout. */
  uint64_t n1 = {0U};

  /** Difference between measured and predicted time. Adapts loop.*/
  double e;

  /** Queries the clock. Invokes filter_time.
   * @return the filtered start times of this and the next buffer
   *         in seconds  */
  virtual std::pair<double, double> process();

  /** Filters the input time */
  virtual double filter_time(double unfiltered_time);

  /** Filter the time for the first time: Initialize the loop state.
   * @return unmodified input time */
  virtual double dll_init(double unfiltered_time);

  /** Filter the time regularly: Update the loop state.
   * @return the prediction from last invocation. */
  virtual double dll_update(double unfiltered_time);
};

#endif

/*
 * Local Variables:
 * mode: c++
 * compile-command: "make -C .."
 * End:
 */
