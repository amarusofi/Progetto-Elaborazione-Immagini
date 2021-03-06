%{
    PLACEMENT

    Posiziona i tetramini sull'immagine dello schema.
    Assumiamo che le immagini di input abbiano le stesse dimensioni.

    input:

        - immagine dei tetramini (scene)
        - immagine dello schema (scheme)
        - maschera del tetramino in questione (mask_scene)
        - maschera dello schema del tetramino (mask_scheme)
    
    algoritmo:

        1. calcoliamo le aree degli oggetti delle maschere (a_scene, a_scheme)

        2. troviamo il rapporto tra a_scene e a_scheme (scale)
           ridimensioniamo scene e mask_scene

        3. calcoliamo gli angoli di rotazione degli oggetti delle maschere
           calcoliamo i possibili angoli di rotazione di mask_scene

        4. troviamo quale delle maschere di scena ruotatate fitta meglio
           ruotiamo scene e mask_scene

        4. calcoliamo la distanza c_scene - c_scheme (d)
           trasliamo scene e mask_scene

        5. rotazione

        6. copiamo e incolliamo il tetramino sull'immagine
%}

function out = placement(scene,scheme,scene_mask,scheme_mask)

% calcoliamo le aree degli oggetti delle maschere
a_scene = sum(scene_mask, 'all');
a_scheme = sum(scheme_mask, 'all');

% ridimensionamento
scale = a_scheme/a_scene;
scene = imresize(scene,sqrt(scale));
scene_mask = imresize(scene_mask,sqrt(scale));

% controlli ridemensioni e crop
if scale < 1 % controllo su scena più piccola dello schema 
    
    tmp_scene = zeros(size(scheme));
    tmp_mask_scene = zeros(size(scheme_mask));

    tmp_scene(1:size(scene,1),1:size(scene,2),1:size(scene,3)) = scene;
    tmp_mask_scene(1:size(scene_mask,1),1:size(scene_mask,2)) = scene_mask;
    
    scene = tmp_scene;
    scene_mask = logical(tmp_mask_scene);
    
elseif scale > 1   
    [scene,scene_mask] = centroid_crop(scene,scene_mask,size(scheme_mask));
end

% calcoliamo gli angoli
scene_props = bwferet(scene_mask,'MaxFeretProperties');
scheme_props = bwferet(scheme_mask,'MaxFeretProperties');

scene_angle = scene_props.MaxAngle;
scheme_angle = scheme_props.MaxAngle;

angle = scheme_angle - scene_angle; 

% calcoliamo la rotazione
c_scheme = int32(compute_centroid(scheme_mask));

rotations = zeros(72,1);

for i = 0:71
    
    tmp = imrotate(scene_mask,-angle-(5*i),'crop');
    c_tmp = int32(compute_centroid(tmp));
    d = c_scheme - c_tmp;
    tmp = imtranslate(tmp,d);

    rotations(i+1) = sum(sum(scheme_mask | not(tmp)));

end

i = find(rotations == max(rotations))-1;

scene_mask = imrotate(scene_mask,-angle-(5*i),'crop');
scene = imrotate(scene,-angle-(5*i),'crop');

% traslazione
c_scene = int32(compute_centroid(scene_mask));

d = c_scheme - c_scene;
scene_mask = imtranslate(scene_mask,d);
scene = imtranslate(scene,d);

% copia e incolla
red = scene(:,:,1) .* scene_mask; 
green = scene(:,:,2) .* scene_mask;
blue = scene(:,:,3) .* scene_mask;

tetromino = cat(3,red,green,blue); % singolo tetramino

mask_scene_neg = not(scene_mask); % maschera singolo tetramino - negativo

red = scheme(:,:,1) .* mask_scene_neg + tetromino(:,:,1);
green = scheme(:,:,2) .* mask_scene_neg + tetromino(:,:,2);
blue = scheme(:,:,3) .* mask_scene_neg + tetromino(:,:,3);

out = cat(3,red,green,blue);

end

%{
    VISUALIZZARE LE IMMAGINI CON I CENTROIDI

    imshow(img);
    hold(imgca,'on');
    plot(centroid(:,1), centroid(:,2), 'r*');

    
    
    VISUALIZZARE LE IMMAGINI CON GLI ASSI
    
    maxLabel = max(mask(:));

    h = imshow(mask,[]);
    axis = h.Parent;
    for labelvalues = 1:maxLabel
        xmax = [props.MaxCoordinates{labelvalues}(1,1) props.MaxCoordinates{labelvalues}(2,1)];
        ymax = [props.MaxCoordinates{labelvalues}(1,2) props.MaxCoordinates{labelvalues}(2,2)];
        imdistline(axis,xmax,ymax);
    end
    title(axis,'Maximum Feret Diameter of Objects');
    colorbar('Ticks',1:maxLabel)  

%}