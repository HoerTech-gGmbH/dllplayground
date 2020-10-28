#ifndef RESAMPLEBUFFER_H
#define RESAMPLEBUFFER_H

#include <stddef.h> // for size_t
#include <chrono>

// preliminary type definitions
struct dll_cfg_t{};
struct resampler_cfg_t{};

/**
  Class for adaptive resampling and buffering.  This class will receive incoming
  sound samples received from the network, and provide adaptively resampled
  sound samples to the sound card to be used for playback.
*/
class resamplebuffer_t {
public:
  /// Constructor initializes a new adaptive resampler.  For filtering the time
  /// stamps, the implementation needs to know the audio block sizes for both
  /// input (network) and output (sound card).
  /// @param channels      Number of audio channels to resample.
  /// @param writefragsize Audio block size of audio signal arriving via
  ///                      network, in samples per channel.  writefragsize is
  ///                      determined by the audio blocks used in the sender to
  ///                      receive samples from their sound card.
  /// @param readfragsize  Audio block size of the playback sound card, in samples
  ///                      per channel.
  /// @param nominal_writer_rate_hz Sampling rate of the sender's sound card, in Hz
  /// @param nominal_reader_rate_hz Sampling rate of the playback sound card, in Hz
  /// @param desireddelay_s Target delay between receiving a sound sample from the
  ///                      network and when it is played back.  The target delay
  ///                      should be large enough to cover network jitter and
  ///                      the resampling delay.  If chosen too small, then gaps
  ///                      in the output will result.
  /// @param expected_max_jitter_s Maximum jitter in seconds expected.
  /// @param dllcfg        Configuration of the delay-locked loops used to smooth
  ///                      time stamps.
  /// @param resamplecfg   Configuration of the resampling.
  resamplebuffer_t(size_t channels, size_t writefragsize, size_t readfragsize,
                   double nominal_writer_rate_hz, double nominal_reader_rate_hz,
                   double desireddelay_s, double expected_max_jitter_s,
                   dll_cfg_t dllcfg, resampler_cfg_t resamplecfg);

  /// Destructor deallocates memory.
  ~resamplebuffer_t();

  /// @return Number of channels as specified in constructor.
  size_t get_channels() const;

  /// @return Number samples per channel for audio blocks written to the resampler.
  size_t get_writefragsize() const;

  /// @return Number samples per channel for audio blocks read from the resampler.
  size_t get_readfragsize() const;

  /// write() must only be called from the writer thread, i.e. the thread which
  /// receives audio data from the network.
  /// @param block_index Because network packets may be received out-of-order, 
  ///                    block_index contains the index of this audio block as
  ///                    it was sent from the sender.  Wrap-around because of
  ///                    numeric overflow of data type size_t is supported.
  /// @param samples     Pointer to buffer containing exactly
  ///                    get_channels()*get_writefragsize() audio samples. write()
  ///                    reads these samples and copies their values into an
  ///                    internal buffer before returning.  The samples must be
  ///                    stored in interleaved order:
  ///                    [channel0sample0, channel1sample0, channel0sample1, ...].
  /// @param arrivaltime Time when the network packet was received.  The time stamp
  ///                    is filtered by a delay-locked loop before it is used by
  ///                    the resampler.  Together with block_index, arrivaltime is
  ///                    used to detect dropouts on the sender's side heuristically
  template <class Clock>
  void write(size_t block_index, const float* samples,
             const std::chrono::time_point<Clock>& arrivaltime);

  /// read() must only be called from the reader thread, i.e. the thread that
  /// writes resampled output sound samples to the local sound card.
  /// It computes these resamples output sound samples on the fly before returning
  /// from read().
  /// @param samples     Pointer to memory owned by the caller.  The read() method
  ///                    will write exactly get_channels()*get_readfragsize() audio
  ///                    samples to this memory, in interleaved order:
  ///                    [channel0sample0, channel1sample0, channel0sample1, ...].
  /// @param playbacktime Time when the sound card woke up to request new samples.
  ///                    playbacktime is filtered by a delay-locked loop before it
  ///                    is used by the resampler.  arrivaltime is also used to
  ///                    detect dropouts on the playback side heuristically
  template <class Clock>
  void read(float* samples, const std::chrono::time_point<Clock>& playbacktime);

  /// A low-pass filtered indicator for the health of the adaptive resampling.
  /// Time constant is approximately 4 seconds.
  /// @return 1.0 when all packets arrive within the expected_max_jitter time
  ///             and no dropouts occur.
  /// @return 0.0 when 10% or more of the output samples cannot be computed
  ///             from input data due to late or lost packets or dropouts.
  float get_health() const;

  /// Return number of late packages, i.e., packages which arrived,
  /// but were too late to be used in the buffer.
  /// @return number of late packages since instanciation
  size_t get_num_late_packages() const;

  /// Return number of lost packages, i.e., packages were presumably
  /// sent but never arrived.
  /// @return number of lost packages since instanciation
  size_t get_num_lost_packages() const;
private:
  // dll stuff
  // ringbuffer stuff
  unsigned channels;
  unsigned writefragsize;
  unsigned readfragsize;
  // resampler stuff
};

#endif
/*
 * Local Variables:
 * mode: c++
 * indent-tabs-mode: nil
 * coding: utf-8-unix
 * c-basic-offset: 2
 * End:
 */
