function [xy,xz,yz] = corrCoefficients(x,y,z)
    % calculates correlation coefficients among signals
    R1 = corrcoef(x,y);
    xy = R1(1,2);
    R2 = corrcoef(z,x);
    xz = R2(1,2);
    R3 = corrcoef(y,z);
    yz = R3(1,2);
end