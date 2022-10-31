function overlap = compute_overlap(ann, det)

if (~sum(ann)) && (~sum(det))
    overlap = 1;
elseif xor(sum(ann),sum(det))
    overlap = 0;
else
    ann_x1 = ann(1);
    ann_y1 = ann(2);
    ann_x2 = ann(3);
    ann_y2 = ann(4);

    annPoly.x = [ann_x1 ann_x2 ann_x2 ann_x1];
    annPoly.y = [ann_y1 ann_y1 ann_y2 ann_y2];
    annArea = polyarea(annPoly.x, annPoly.y);

    can_x1 = det(1);
    can_y1 = det(2);
    can_x2 = det(3);
    can_y2 = det(4);

    canPoly.x = [can_x1 can_x2 can_x2 can_x1];
    canPoly.y = [can_y1 can_y1 can_y2 can_y2];
    trackedArea = polyarea(canPoly.x, canPoly.y);

    sharedArea = polygonIntersectionArea(annPoly, canPoly);
    sharedArea = sum(sharedArea);
    overlap = sharedArea / (annArea + trackedArea - sharedArea);
end