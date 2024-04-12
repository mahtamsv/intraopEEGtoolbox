from fooof import FOOOF
import scipy as sp
import numpy as np


def extract_power_features(data_in, srate):
    """
    Extract features from power spectral density
    :param EEG_in: EEG time series (channel x time samples x number of epochs)
    :param srate: sampling rate
    :return:
    """
    # estimate power spectral density on every channel
    num_chans, num_time, num_epochs = np.shape(data_in)
    PSD_epoch = np.zeros([num_chans, srate * int(np.floor(num_time / (srate * 2))) + 1, num_epochs])
    freqs = []

    for idx_epoch in range(np.size(PSD_epoch, 2)):
        freqs, temp = sp.signal.welch(data_in[:, :, idx_epoch], fs=srate, nperseg=num_time, noverlap=0,
                                      axis=1, detrend=False)
        PSD_epoch[:, :, idx_epoch] = temp / np.mean(temp)  # normalized power

    spectrum = np.mean(PSD_epoch, axis=2)
    spectrum = np.mean(spectrum, axis=0)

    # estimate SEF and MF
    integrated_spectrum = sp.integrate.cumtrapz(freqs, spectrum, initial=0)
    interp_func = sp.interpolate.interp1d(integrated_spectrum, freqs, kind='linear')
    SEF = interp_func(0.95 * integrated_spectrum[-1])
    # MF = interp_func(0.5 * integrated_spectrum[-1])

    print(np.shape(integrated_spectrum))
    # FOOOF
    # Initialize a FOOOF object
    fm = FOOOF(peak_width_limits=[1, 5], max_n_peaks=2)
    fm.print_settings(description=True)

    # note that the data should be in linear spacing
    freq_range = [5, 15]
    fm.add_data(freqs, spectrum, freq_range)

    # Fit a power spectrum model to the loaded data
    fm.fit()

    # Print out model fit results
    print('aperiodic params: \t', fm.aperiodic_params_)
    print('peak params: \t', fm.peak_params_)
    print('number of peaks: \t', fm.n_peaks_)
    # print('fit error: \t', fm.error_)

    # if more than one peak, take the maximum (usually second)
    if len(fm.peak_params_) > 0.:
        idx_max = np.argmax(fm.peak_params_[:, 0])
        print(idx_max)
        peak_val = fm.peak_params_[idx_max, 0]
        width_val = fm.peak_params_[idx_max, 2]
        print(peak_val)
        print(width_val)

    else:
        peak_val = 0.
        width_val = 0.

    # aperiodic parameters
    aper_off = fm.aperiodic_params_[0]
    aper_exp = fm.aperiodic_params_[1]

    return peak_val, width_val, aper_exp, aper_off, SEF
