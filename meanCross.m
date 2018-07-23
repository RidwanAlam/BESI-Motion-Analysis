function mxr = meanCross(x)
    % calculates mean-crossing-rate of input signal
    zcd = dsp.ZeroCrossingDetector;
    x1 = x - mean(x);
    if size(x1,1)>size(x1,2)
        mxr = step(zcd,x1);
    else
        mxr = step(zcd,x1');
    end
    release(zcd);
end