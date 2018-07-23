function [PY1mean,PY1max,PY2mean,PY2max,PY3mean,PY3max] = fftpower(X,FS)

    % calculates the FFT of the signal X with sampling rate FS
    % outputs the mean and max power of the FFT spectrum in 3 frequency bands
    % band-1: 0-0.5 Hz, band-2: 0.5-3 Hz, band-3: 3-10 Hz;
    
    %FS = 50;              % Sampling frequency
    %T = 1/Fs;             % Sampling period
    L = length(X);        % Length of signal
    %t = (0:L-1)*T;
    if (mod(L,2)==0)
        f = FS*(-(L/2):(L/2)-1)/L; % when L is even
    else
        f = FS*(-(L-1)/2:(L-1)/2)/L; % since L is odd
    end
    Y = abs(fftshift(fft(X)));
    PY = ((Y(f>=0)).^2)/(L*FS);
    PY(2:end) = 2*PY(2:end);
    Pf = f(f>=0);
    PY1 = PY(Pf>0.1 & Pf<=0.5);
    PY1mean = max(mean(PY1(PY1>0)),0.0001);
    PY1max = max(max(PY1(PY1>0)),0.0001);
    PY2 = PY(Pf>0.5 & Pf<=3);
    PY2mean = max(mean(PY2(PY2>0)),0.0001);
    PY2max = max(max(PY2(PY2>0)),0.0001);
    PY3 = PY(Pf>3 & Pf<=10);
    PY3mean = max(mean(PY3(PY3>0)),0.0001);
    PY3max = max(max(PY3(PY3>0)),0.0001);
    %PY3 = max(mean(PY(Pf>3 & Pf<=10)),0.0001);
    % power in 0.1-0.5, 0.5-3, and >3 Hz
    %fvals = [PY1,PY2,PY3]; % mean values for that range
end