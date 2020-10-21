#ifndef RESAMPLEBUFFER_H
#define RESAMPLEBUFFER_H

/*
  class for adaptive resampling and buffering
*/

class resamplebuffer_t {
public:
  // minimal interface
  // channel number may not change, to make live easier:
  resamplebuffer_t(size_t channels, size_t writefragsize, size_t readfragsize,
                   double nominal_writer_rate_hz, double nominal_reader_rate_hz,
                   double desireddelay_s, double expected_max_jitter_s,
                   dll_cfg_t dllcfg, resampler_cfg_t resamplecfg);
  ~resamplebuffer_t();
  // write can be called out of order from any thread. n is the sample index of
  // the first sample.
  void write(size_t n, const float* samples,
             const std::chrono::time_point& arrivaltime_of_first_sample);
  // read can be called in order(?) from any thread:
  void read(size_t n, float* samples,
            const std::chrono::time_point& playbacktime_of_first_sample);

  // report a packet which was too late, n would have been the sample index:
  virtual void packet_is_late(size_t n){};

  // report a packet which was lost, n would have been the sample index:
  virtual void packet_is_lost(size_t n){};

  // report a reader xrun, n would have been the sample index:
  virtual void reader_xrun(size_t n){};

  // it needs to be discussed in which thread the reporting methods
  // can be called. I would propose an asynchronous thread to avoid
  // blocking of the writer or reader threads.

private:
  // dll stuff
  // ringbuffer stuff
  // resampler stuff
};

#endif
/*
 * Local Variables:
 * mode: c++
 * End:
 */
