server_ip = input("Enter the server IP address: ", 's');
port = input("Enter the port no. to extablish connection: ");
t = tcpip(server_ip, port, 'NetworkRole', 'client',"Timeout",60);
t.InputBufferSize = 5000000;
t.OutputBufferSize = 5000000;
fopen(t);
disp("Connected to server running on port "+port+newline);
menu_len = fread(t, 1,'uint16');
menu = string(char(fread(t, menu_len)));
menu = append(menu{:});
menu = replace(menu,',',newline);
disp(menu);
option=0;
while option~=10
    option = input(newline+"Enter the option: ");
    fwrite(t,option,'uint8');
    if option == 1
       cur_dir_len = fread(t, 1,'uint16');
       cur_dir = string(char(fread(t, cur_dir_len)));
       cur_dir = append(cur_dir{:});
       disp(newline+"Current Directory: "+cur_dir);
    end
    if option == 2
       path = input("Enter the path: ",'s');
       fwrite(t, length(path), 'uint16');
       fwrite(t, path);
       status = fread(t, 1,'uint8');
       if status == 1
           disp("Given path doesn't exist");
       end
    end
    if option == 3
       list_len = fread(t, 1,'uint16');
       list = string(char(fread(t, list_len)));
       list = append(list{:});
       list = replace(list,',',newline);
       disp(newline+"Contents of the directory:"+newline+list);
    end
    if option == 4
        directory = input("Enter the name/path of the directory to be deleted: ", 's');
        fwrite(t, length(directory), 'uint16');
        fwrite(t, directory);
        status = fread(t, 1,'uint8');
        if status == 1
            disp("Given path doesn't exist");
        end
    end
    if option == 5
        filename = input("Enter the name of the file to be deleted: ", 's');
        fwrite(t, length(filename), 'uint32');
        fwrite(t, filename);
        status = fread(t, 1,'uint8');
        if status == 1
            disp("Given file doesn't exist");
        end
    end
    if option == 6
        filename = input("Enter the name of the file: ", 's');
        fwrite(t, length(filename), 'uint32');
        fwrite(t, filename);
        if isfile(filename)
            data = fileread(filename);
            len = length(data);
            fwrite(t, len, 'uint32');
            fwrite(t, data);
            disp("File Transferred(no embedding)");
        else 
            disp("Given file doesn't exist");
        end
    end
    if option == 7
        filename = input("Enter the name of the file: ", 's');
        fwrite(t, length(filename), 'uint32');
        fwrite(t, filename);
        if isfile(filename)
            img = input("Enter the image file name: ",'s');
            mat = imread(img);
            [x,y,z] = size(mat);
            data = fileread(filename);
            len = length(data);
            if len*4 >= x*y*z
                error("Smaller image to embed text file");
            end
            disp("Embedding the file...");
            embed_mat = Embed(mat,data);
            embed_mat = reshape(embed_mat,[1 x*y*z]);
            fwrite(t, [len x y z], 'uint32');
            fwrite(t, embed_mat,'uint8');
            disp("Image embedded with contents of the file is sent");
        else 
            disp("Given file doesn't exist");
        end
    end
    if option == 8
        filename = input("Enter the name of the file: ", 's');
        fwrite(t, length(filename), 'uint32');
        fwrite(t, filename);
        status = fread(t, 1,'uint8');
        if status == 1
            disp("Given file doesn't exist");
        else
            data_len = fread(t, 1,'uint32');
            data = char(fread(t, data_len));
            newfile = input("Enter the name for the recieved file(with extension): ",'s');
            fid = fopen(newfile,"w");
            fwrite(fid,data);
            fclose(fid);
            disp("File Received");
        end
    end
    if option == 9
        disp("Waiting for server...");
        response = fread(t, 1, 'uint8');
        filename = input("Enter the name of the file: ", 's');
        fwrite(t, length(filename), 'uint32');
        fwrite(t, filename);
        status = fread(t, 1,'uint8');
        if status == 1
            disp("Given file doesn't exist");
        else
            attr = fread(t, 4,'uint32');
            len = attr(1);
            x = attr(2);
            y = attr(3);
            z = attr(4);
            embed_mat = char(fread(t,x*y*z));
            embed_mat = reshape(embed_mat,[x,y,z]);
            disp("Embedded image received, Extraction in process...");
            extracted_str = Extract(embed_mat, len);
            disp("File contents extracted");
            newfile = input("Enter the name to save the recieved file(with extension): ",'s');
            fid = fopen(newfile,"w");
            fwrite(fid,extracted_str);
            fclose(fid);
            disp("File saved");
        end
    end
    if option == 11
        disp(menu);
    end
end
if option == 10
    fclose(t);
    disp("Connection closed");
end