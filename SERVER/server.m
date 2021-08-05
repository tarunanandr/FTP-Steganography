menu = "Services:,1. Current Directory,2. Change Directory,3. List Directory,4. Remove Directory,5. Delete File,6. Send File,7. Send File(secured),8. Recieve File,9. Recieve file(secured),10. Close connection,11. Display menu once again";
t = tcpip('127.0.0.1', 30000, 'NetworkRole', 'server',"Timeout",60);
t.InputBufferSize = 5000000;
t.OutputBufferSize = 5000000;
disp("Server running on port 30000"+newline);
fopen(t);
disp("Client connected.."+newline);
fwrite(t, strlength(menu), 'uint16');
fwrite(t, menu);
option=0;
while option~=10
    option = fread(t,1,'uint8');
    if option == 1
        cur_dir = cd;
        fwrite(t, length(cur_dir), 'uint16');
        fwrite(t, cur_dir);
    end
    if option == 2
        dir_len = fread(t,1,'uint16');
        path = string(char(fread(t,dir_len)));
        path = char(append(path{:}));
        if isfolder(string(path))
            fwrite(t, 0, 'uint8');
            cd(path);
        else
            fwrite(t, 1, 'uint8');
        end
    end
    if option == 3
        list = ls;
        list = strjoin(string(list),',');
        fwrite(t, strlength(list), 'uint16');
        fwrite(t, list);
    end
    if option == 4
        dir_len = fread(t,1,'uint16');
        path = string(char(fread(t,dir_len)));
        path = append(path{:});
        if isfolder(string(path))
            fwrite(t, 0, 'uint8');
            rmdir(path,'s');
            disp("Removed the directory: "+path);
        else
            fwrite(t, 1, 'uint8');
        end
    end
    if option == 5
        filename_len = fread(t,1,'uint32');
        filename = string(char(fread(t, filename_len)));
        filename = append(filename{:});
        if isfile(filename)
            fwrite(t, 0, 'uint8');
            delete(filename);
            disp(newline+"Deleted file: "+filename);
        else
            fwrite(t, 1, 'uint8');
        end
    end
    if option == 6
        filename_len = fread(t,1,'uint32');
        filename = string(char(fread(t, filename_len)));
        filename = append(filename{:});
        if contains(filename,"\")
            filename = string(split(filename,"\"));
            filename = filename(length(filename));
        end
        disp(newline+"Receiving file from client...");
        data_len = fread(t, 1,'uint32');
        data = char(fread(t, data_len));
        fid = fopen(filename,"w");
        fwrite(fid,data);
        fclose(fid);
        disp("File Received");
    end
    if option == 7
        filename_len = fread(t,1,'uint32');
        filename = string(char(fread(t, filename_len)));
        filename = append(filename{:});
        if contains(filename,"\")
            filename = string(split(filename,"\"));
            filename = filename(length(filename));
        end
        attr = fread(t, 4,'uint32');
        len = attr(1);
        x = attr(2);
        y = attr(3);
        z = attr(4);
        disp(newline+"Receiving file from client...");
        embed_mat = char(fread(t,x*y*z));
        embed_mat = reshape(embed_mat,[x,y,z]);
        disp("Embedded image received, Extraction in process...");
        extracted_str = Extract(embed_mat, len);
        fid = fopen(filename,"w");
        fwrite(fid,extracted_str);
        fclose(fid);
        disp("File extracted and saved");
    end
    if option == 8
        filename_len = fread(t,1,'uint32');
        filename = string(char(fread(t, filename_len)));
        filename = append(filename{:});
        if isfile(filename)
            fwrite(t, 0, 'uint8');
            data = fileread(filename);
            len = length(data);
            fwrite(t, len, 'uint32');
            fwrite(t, data);
            disp("File Transferred(no embedding)");
        else
            fwrite(t, 1, 'uint8');
        end
    end
    if option == 9
        img = input(newline+"Enter the image file name: ",'s');
        mat = imread(img);
        figure(1); image(mat);
        [x,y,z] = size(mat);
        fwrite(t, 1,'uint8');
        filename_len = fread(t,1,'uint32');
        filename = string(char(fread(t, filename_len)));
        filename = append(filename{:});
        if isfile(filename)
            fwrite(t, 0, 'uint8');
            data = fileread(filename);
            len = length(data);
            if len*4 >= x*y*z
                error("Smaller image to embed text file");
            end
            disp("Embedding the file...");
            embed_mat = Embed(mat,data);
            figure(2); image(embed_mat);
            embed_mat = reshape(embed_mat,[1 x*y*z]);
            fwrite(t, [len x y z], 'uint32');
            fwrite(t, embed_mat,'uint8');
            disp("Image embedded with contents of the file is sent");
        else
            fwrite(t, 1, 'uint8');
        end
    end
end
if option == 10
    fclose(t);
    disp(newline+"Connection closed");
end