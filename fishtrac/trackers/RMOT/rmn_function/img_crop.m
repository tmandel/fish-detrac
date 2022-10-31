function d_bbox = img_crop(ss,img, hei, wid)
 
ss = fix(ss);
A = max(ss(2),1);
B = min(ss(2)+ss(4),size(img,1));
C = max(ss(1),1);
D = min(ss(1)+ss(3),size(img,2));



d_bbox = imresize(img(A:B, C:D,:),[hei wid]);
