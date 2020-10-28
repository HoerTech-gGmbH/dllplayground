#include "resamplebuffer.h"
#include <gtest/gtest.h>

TEST(resamplebuffer_t, initial_state)
{
  const unsigned channels = 2U;
  const unsigned writefragsize = 512U;
  const unsigned readfragsize = 196U;
  const double nominal_writer_rate_hz = 48000.0;
  const double nominal_reader_rate_hz = 48000.0;
  const double desireddelay_s = 0.030;
  const double expected_max_jitter_s = 0.029;
  const dll_cfg_t dllcfg = {};
  const resampler_cfg_t resamplercfg = {};

  resamplebuffer_t resampler = {channels, writefragsize, readfragsize,
                                nominal_writer_rate_hz, nominal_reader_rate_hz,
                                desireddelay_s, expected_max_jitter_s,
                                dllcfg, resamplercfg};

  EXPECT_EQ(channels,      resampler.get_channels());
  EXPECT_EQ(writefragsize, resampler.get_writefragsize());
  EXPECT_EQ(readfragsize,  resampler.get_readfragsize());

  // initially the health should be fine, no late or lost packages
  EXPECT_EQ(1.0f,          resampler.get_health());
  EXPECT_EQ(0U,            resampler.get_num_late_packages());
  EXPECT_EQ(0U,            resampler.get_num_lost_packages());
}

/*
 * Local Variables:
 * mode: c++
 * indent-tabs-mode: nil
 * coding: utf-8-unix
 * c-basic-offset: 2
 * End:
 */
