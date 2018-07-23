function qqr = interQrange(z)
    % calculates inter-quartile range
    qqr = quantile(z,0.75) - quantile(z,0.25);
end