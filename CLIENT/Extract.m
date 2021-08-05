function ext_str = Extract(mat,nchar)
    [x,y,z] = size(mat);
    imgpix = x*y*z;
    permutmat = permute(mat,[3 1 2]);
    matbin = cellstr(dec2bin(permutmat)); % Embedded image matrix converted to array of the corresponding binary values
    strbin = strings(nchar,1); % Empty array of characters to store retrieved binary value of embedded characters
    idx1 = nchar*4; 
    idx2 = nchar;
    switch true % To set the extraction from appropriate block based on the size of input text
        case ismember(nchar*4, 1:ceil(imgpix/4))
            idx3 = ceil(imgpix/4)+(nchar*4);
        case ismember(nchar*4, ceil(imgpix/4)+1:ceil(imgpix/4)*2)
            idx3 = ceil(imgpix/4)*3+((nchar*4)-ceil(imgpix/4));
        case ismember(nchar*4, ceil(imgpix/4)*2+1:ceil(imgpix/4)*3)
            idx3 = (nchar*4)-(ceil(imgpix/4)*2);
        case ismember(nchar*4, ceil(imgpix/4)*3+1:ceil(imgpix/4)*4)
            idx3 = ceil(imgpix/4)*2+((nchar*4)-(ceil(imgpix/4)*3));
    end
    while idx1 >= 1 || idx2 > 0  
        val = char(matbin(idx3)); 
        strbin(idx2) = strcat(strbin(idx2),val(7:8)); % Extraction of embedded bits
        idx1 = idx1-1;
        if rem(idx1,4)==0
            idx2 = idx2-1; 
        end
        switch true % Maintain control to remain in the same block or to move to the next block
            case idx3 == ceil(imgpix/4)*2+1
                idx3 = ceil(imgpix/4);
            case idx3 == 1
                idx3 = ceil(imgpix/4)*4;
            case idx3 == ceil(imgpix/4)*3+1
                idx3 = ceil(imgpix/4)*2;
            otherwise
                idx3 = idx3-1;
        end
    end
    ext_str = char(bin2dec(strbin)); % Binary values of extracted characters converted to char values and returned
end