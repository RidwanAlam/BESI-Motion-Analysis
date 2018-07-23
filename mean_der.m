function [mndz,mxdz] = mean_der(z)
    % calculate mean and max of derivatives 
    dz = diff(z);
    mndz = mean(dz);
    mxdz = max(dz);
end