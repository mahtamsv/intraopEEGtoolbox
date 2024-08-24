from fooof import FOOOF
import scipy as sp
import numpy as np
import mne_connectivity
import mne
import mne_features


def estimate_spectrum(data_in, srate):
    """
    Turn time series into power spectral density and fit FOOOF model
    :param data_in: EEG_in: EEG time series (channel x time samples x number of epochs)
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

    # FOOOF
    # Initialize a FOOOF object
    fm = FOOOF(peak_width_limits=[1, 5], max_n_peaks=1)
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

    return spectrum, freqs, fm


def extract_power_features(data_in, srate):
    """
    Extract features from power spectral density
    :param data_in: EEG time series (channel x time samples x number of epochs)
    :param srate: sampling rate
    :return:
    """

    spectrum, freqs, fm = estimate_spectrum(data_in, srate)

    # estimate SEF
    integrated_spectrum = sp.integrate.cumtrapz(freqs, spectrum, initial=0)
    interp_func = sp.interpolate.interp1d(integrated_spectrum, freqs, kind='linear')
    SEF = interp_func(0.95 * integrated_spectrum[-1])

    print(np.shape(integrated_spectrum))

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


def extract_connectivity_features(data_epochs, srate):
    """
    Extract connectivity features
    :param data_epochs: EEG time series (channel x time samples x number of epochs)
    :param srate: sampling rate
    :return:
    """

    spectrum, freqs, fm = estimate_spectrum(data_epochs, srate)

    # if more than one peak, take the maximum (usually second)
    if len(fm.peak_params_) > 0.:
        idx_max = np.argmax(fm.peak_params_[:, 0])
        print(idx_max)

        l_frequency = fm.peak_params_[idx_max, 0] - fm.peak_params_[idx_max, 2] / 2
        h_frequency = fm.peak_params_[idx_max, 0] + fm.peak_params_[idx_max, 2] / 2
    else:
        # if no peak is found, take the general alpha band
        l_frequency = 8.
        h_frequency = 12.

    # ------------------
    # estimate connectivity
    # explicit re-shaping
    [m, n, p] = np.shape(data_epochs)
    data_epochs_r = np.zeros([p, m, n])
    for ij in range(p):
        data_epochs_r[ij, :, :] = data_epochs[:, :, ij]

    print(np.shape(data_epochs_r))

    # filter the data in narrowband
    data_epochs_filt = mne.filter.filter_data(data_epochs_r, sfreq=60, l_freq=l_frequency
                                              , h_freq=h_frequency, pad='reflect')
    print(np.shape(data_epochs_filt))

    # real and imaginary coherency
    cohy_e = mne_connectivity.spectral_connectivity_epochs(data_epochs_filt, method='cohy', sfreq=60, fmin=l_frequency,
                                                           fmax=h_frequency, faverage=True, mode='fourier')
    cohy_e = cohy_e.get_data()
    iCOH_e = np.abs(np.imag(cohy_e))
    rCOH_e = np.abs(np.real(cohy_e))

    # take the average of the absolute and non-zeros
    iCOH = np.mean(iCOH_e[iCOH_e != 0])
    rCOH = np.mean(rCOH_e[rCOH_e != 0])

    # pairwise phase consistency
    ppc_e = mne_connectivity.spectral_connectivity_epochs(data_epochs_filt, method='ppc', sfreq=60, fmin=l_frequency,
                                                          fmax=h_frequency, faverage=True, mode='fourier')
    ppc_e = ppc_e.get_data()
    PPC = np.mean(ppc_e[ppc_e != 0])

    # envelope correlation
    AAc_e = mne_connectivity.envelope_correlation(data_epochs_filt)
    # print(np.shape(AAc_e.get_data()))
    res_m = np.squeeze(np.mean(AAc_e.get_data(), axis=0))
    # average over non-zero values
    AA_c = np.mean(res_m[np.tril_indices(4, k=-1)])
    return rCOH, iCOH, PPC, AA_c


def extract_complexity_features(data_epochs, srate):
    """
    Estimate complexity measures
    :param data_epochs: EEG time series (channel x time samples x number of epochs)
    :param srate: sampling rate
    :return:
    """

    [m, n, p] = np.shape(data_epochs)
    # explicit reshaping
    data_epochs_r = np.zeros([p, m, n])
    for ij in range(p):
        data_epochs_r[ij, :, :] = data_epochs[:, :, ij]

    print(np.shape(data_epochs_r))

    # estimate complexity
    HD = np.zeros([p, 4])
    AE = np.zeros([p, 4])
    SE = np.zeros([p, 4])
    HC = np.zeros([p, 4])
    for ij in range(p):
        temp = data_epochs_r[ij, :, :]
        HD[ij, :] = mne_features.univariate.compute_higuchi_fd(temp, kmax=10)
        AE[ij, :] = mne_features.univariate.compute_app_entropy(temp, emb=2, metric='chebyshev')
        SE[ij, :] = mne_features.univariate.compute_spect_entropy(srate, temp, psd_method='welch', psd_params=None)
        HC[ij, :] = mne_features.univariate.compute_hjorth_complexity(temp)

    HD = np.mean(HD)
    SE = np.mean(SE)
    AE = np.mean(AE)
    HC = np.mean(HC)

    return HD, SE, AE, HC

