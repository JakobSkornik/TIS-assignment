function [izhod, R, kodBela, kodCrna] = naloga2(vhod)

  warning ("off", "all");
  izhod = [];
  RLE_bele = [];
  RLE_crne = [];

  for i = 1:rows(vhod)

    RLE = runlength(vhod(i,:));
    
    if vhod(i,1) == 0

      RLE = [0,RLE];

    endif

    RLE_bele = [RLE_bele, RLE(1:2:end)];
    RLE_crne = [RLE_crne,RLE(2:2:end)];

  endfor

  crne = [0, 0];
  crne_dolzine = 0;

  bele_ponovitve = histc(RLE_bele, unique(RLE_bele));
  bele_dolzine = unique(RLE_bele);
  bele = sortrows([bele_dolzine; bele_ponovitve ./ numel(RLE_bele)]', [-2, 1]);

  if numel(RLE_crne) > 0

    crne_ponovitve = histc(RLE_crne, unique(RLE_crne));
    crne_dolzine = unique(RLE_crne);
    crne = sortrows([crne_dolzine; crne_ponovitve ./ numel(RLE_crne)]', [-2, 1]);

  endif
  
  bele = [bele, zeros(size(bele))];
  bele = build_HTree(bele);
  crne = [crne, zeros(size(crne))];
  crne = build_HTree(crne);

  kodBela = sortrows(bele([1:numel(bele_dolzine)], [1, 5]), [2, 1]);

  if numel(RLE_crne) == 0

    kodCrna = [];

  else 

    kodCrna = sortrows(crne([1:numel(crne_dolzine)], [1, 5]), [2, 1]);

  endif
  
  code_white = create_dec_code(kodBela); 
  code_black = create_dec_code(kodCrna);

  izhod = [izhod, generate_output(code_white, code_black, vhod)];

  R = length(izhod) ./ (rows(vhod) * 1728);

end

function [input] = build_HTree(input)

  max_recursion_depth (100000000, "local");

  if rows(input) > 1

    [najmanjsi, row] = min(min(input(:,2),[],2));

    i = row;
    input(i,2) = input(i,2) + 1;

    [najmanjsi, row] = min(min(input(:,2),[],2));
    j = row;
    input(j,2) = input(j,2) + 1;

    vsota = input(i,2) .+ input(j,2) .- 1.999999;

    input = [input; [0,vsota,i,j]];

    if vsota < 0.9999

      input = build_HTree(input);

    else 

      input = [input, zeros(rows(input), 1)];
      k = rows(input);
      i = input(k, 3);
      j = input(k, 4);

      while i .+ j > 0

        input(i, 5) = input(i, 5) + 1 + input(k,5);
        input(j, 5) = input(j, 5) + 1 + input(k,5);
        k--;
        i = input(k, 3);
        j = input(k, 4);

      endwhile

    endif

  else

    input = [input, ones(rows(input), 1)];

  endif

end

function [code] = create_dec_code(code)
  
  code = [code, zeros(size(code), 1)];
  i = 2;

  while i <= rows(code)

    code(i,3) = code(i - 1, 3) + 1;

    if code(i,2) > code(i - 1, 2)

      code(i,3) = bitshift(code(i,3), (code(i, 2) - (code(i - 1, 2))));

    endif

    i++;

  endwhile

end

function [output] = generate_output(white_code, black_code, vhod)
  
  x = [];

  for j = 1:rows(vhod)
    
    RLE = runlength(vhod(j,:));
    
    if vhod(j,1) == 0
      RLE = [0,RLE];
    endif

    for i = 1:length(RLE)

      if mod(i,2) == 0

        [vrstica, y] = find(RLE(i) == black_code(:, 1));
        x = [x, dec2bin(black_code(vrstica, 3), black_code(vrstica, 2))];
        
      else

        [vrstica, y] = find(RLE(i) == white_code(:, 1));
        x = [x, dec2bin(white_code(vrstica, 3), white_code(vrstica, 2))];

      endif

    endfor
    
  endfor

  output = str2double(regexp(num2str(x),'\d','match'));
end