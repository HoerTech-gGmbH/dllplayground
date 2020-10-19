#ifndef RESAMPLEBUFFER_H
#define RESAMPLEBUFFER_H

/*
  class for adaptive resampling and buffering
 */

class resamplebuffer_t {
public:
  // minimal interface
  // channel number may not change, to make live easier:
  resamplebuffer_t( size_t channels, size_t bufferlen, double nominal_writer_rate, double nominal_reader_rate, double desireddelay );
  ~resamplebuffer_t();
  // all following methods should be allowed to be called any time from any thread:
  void write( size_t n, float* samples );
  void read( size_t n, float* samples );
  void set_nominal_writer_rate( double fs_in_hz );
  void set_nominal_reader_rate( double fs_in_hz );
  void set_desired_delay( double delay_in_seconds );
private:
};

#endif
/*
 * Local Variables:
 * mode: c++
 * End:
 */
