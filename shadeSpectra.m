function shadeSpectra( f, p, err, c, takelog )

if(size(err,2) < size(err,1))
    err = err';
end
if(size(f,2) < size(f,1))
    f = f';
end
if(size(p,2) < size(p,1))
    p = p';
end

if(~exist('takelog','var'))
    takelog = 1;
end

upper = err(2,:);
lower = err(1,:);

if(takelog)
    upper = 10*log10(upper);
    lower = 10*log10(lower);
    p = 10*log10(p);
end

jbfill(f, upper, lower, ...
    c, [1 1 1], 1, 0.5);
hold on
plot(f, p, '-', 'Color', c, 'LineWidth', 1);

end

