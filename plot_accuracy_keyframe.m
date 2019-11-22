function plot_accuracy_keyframe
opt = globals();

leng = {'PoseCNN', 'PoseCNN+ICP', 'PoseCNN+Multiview', 'PoseCNN+ICP+Multiview'};
leng = [leng opt.methods]; % additional methods
aps = zeros(length(leng), 1);
lengs = cell(length(leng), 1);
color = jet(length(leng));
close all;

% load results
object = load('results_keyframe.mat');
distances_sys = object.distances_sys;
distances_non = object.distances_non;
rotations = object.errors_rotation;
translations = object.errors_translation;
cls_ids = object.results_cls_id;

index_plot = (1:length(leng)); %[4, 2, 5, 3, 1];
fprintf('object, ');
for i = index_plot
    fprintf('%s, ', leng{i});
end 
fprintf('\n');

% read class names
fid = fopen('classes.txt', 'r');
C = textscan(fid, '%s');
classes = C{1};
classes{end+1} = 'All 21 objects';
fclose(fid);

hf = figure('units','normalized','outerposition',[0 0 1 1]);
font_size = 12;
max_distance = 0.1;
LineWidth = 2;

% for each class
for k = 1:numel(classes)
    index = find(cls_ids == k);
    if isempty(index)
        index = 1:size(distances_sys,1);
    end
    fprintf('%s, ', classes{k});

    % distance symmetry
    subplot(2, 2, 1);
    for i = index_plot
        D = distances_sys(index, i);
        D(D > max_distance) = inf;
        d = sort(D);
        n = numel(d);
        accuracy = cumsum(ones(1, n)) / n;        
        plot(d, accuracy, 'Color', color(i, :), 'LineWidth', LineWidth);
        aps(i) = VOCap(d, accuracy);
        lengs{i} = sprintf('%s (%.2f)', leng{i}, aps(i) * 100);
        fprintf('%.1f, ', aps(i) * 100);
        hold on;
    end    
    fprintf('\n');
    
    hold off;
    %h = legend('network', 'refine tranlation only', 'icp', 'stereo translation only', 'stereo full', '3d coordinate');
    %set(h, 'FontSize', 16);
    h = legend(lengs(index_plot), 'Location', 'southeast');
    set(h, 'FontSize', font_size);
    h = xlabel('Average distance threshold in meter (symmetry)');
    set(h, 'FontSize', font_size);
    h = ylabel('accuracy');
    set(h, 'FontSize', font_size);
    h = title(classes{k}, 'Interpreter', 'none');
    set(h, 'FontSize', font_size);
    xt = get(gca, 'XTick');
    set(gca, 'FontSize', font_size)

    % distance non-symmetry
    subplot(2, 2, 2);
    for i = index_plot
        D = distances_non(index, i);
        D(D > max_distance) = inf;
        d = sort(D);
        n = numel(d);
        accuracy = cumsum(ones(1, n)) / n;
        plot(d, accuracy, 'Color', color(i, :), 'LineWidth', LineWidth);
        aps(i) = VOCap(d, accuracy);
        lengs{i} = sprintf('%s (%.2f)', leng{i}, aps(i) * 100);        
        hold on;
    end
    hold off;
    %h = legend('network', 'refine tranlation only', 'icp', 'stereo translation only', 'stereo full', '3d coordinate');
    %set(h, 'FontSize', 16);
    h = legend(lengs(index_plot), 'Location', 'southeast');
    set(h, 'FontSize', font_size);
    h = xlabel('Average distance threshold in meter (non-symmetry)');
    set(h, 'FontSize', font_size);
    h = ylabel('accuracy');
    set(h, 'FontSize', font_size);
    h = title(classes{k}, 'Interpreter', 'none');
    set(h, 'FontSize', font_size);    
    xt = get(gca, 'XTick');
    set(gca, 'FontSize', font_size)
    
    % rotation
    subplot(2, 2, 3);
    for i = index_plot
        D = rotations(index, i);
        d = sort(D);
        n = numel(d);
        accuracy = cumsum(ones(1, n)) / n;
        plot(d, accuracy, 'Color', color(i, :), 'LineWidth', LineWidth);
        hold on;
    end
    hold off;
    %h = legend('network', 'refine tranlation only', 'icp', 'stereo translation only', 'stereo full', '3d coordinate');
    %set(h, 'FontSize', 16);
    h = legend(leng(index_plot), 'Location', 'southeast');
    set(h, 'FontSize', font_size);
    h = xlabel('Rotation angle threshold');
    set(h, 'FontSize', font_size);
    h = ylabel('accuracy');
    set(h, 'FontSize', font_size);
    h = title(classes{k}, 'Interpreter', 'none');
    set(h, 'FontSize', font_size);
    xt = get(gca, 'XTick');
    set(gca, 'FontSize', font_size)

    % translation
    subplot(2, 2, 4);
    for i = index_plot
        D = translations(index, i);
        D(D > max_distance) = inf;
        d = sort(D);
        n = numel(d);
        accuracy = cumsum(ones(1, n)) / n;
        plot(d, accuracy, 'Color', color(i, :), 'LineWidth', LineWidth);
        hold on;
    end
    hold off;
    h = legend(leng(index_plot), 'Location', 'southeast');
    set(h, 'FontSize', font_size);
    h = xlabel('Translation threshold in meter');
    set(h, 'FontSize', font_size);
    h = ylabel('accuracy');
    set(h, 'FontSize', font_size);
    h = title(classes{k}, 'Interpreter', 'none');
    set(h, 'FontSize', font_size);
    xt = get(gca, 'XTick');
    set(gca, 'FontSize', font_size)
    
    filename = sprintf('plots/%s.png', classes{k});
    hgexport(hf, filename, hgexport('factorystyle'), 'Format', 'png');
end

function ap = VOCap(rec, prec)

index = isfinite(rec);
rec = rec(index);
prec = prec(index)';

mrec=[0 ; rec ; 0.1];
mpre=[0 ; prec ; prec(end)];
for i = 2:numel(mpre)
    mpre(i) = max(mpre(i), mpre(i-1));
end
i = find(mrec(2:end) ~= mrec(1:end-1)) + 1;
ap = sum((mrec(i) - mrec(i-1)) .* mpre(i)) * 10;