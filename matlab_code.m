
%% convolution 2d manual code
clc
kernel_size =3;

% img = imread('/MATLAB Drive/OIP-4089906361.jpg', 'jpg');
% I = int32(img)

I = [100, 200, 50, 75, 25, 125, 175, 225; 
     30, 60, 90, 120, 150, 180, 210, 240; 
     15, 45, 75, 105, 135, 165, 195, 225; 
     5, 10, 20, 30, 40, 50, 60, 70; 
     80, 90, 100, 110, 120, 130, 140, 150; 
     160, 170, 180, 190, 200, 210, 220, 230; 
     5, 15, 25, 35, 45, 55, 65, 75; 
     255, 240, 225, 210, 195, 180, 165, 150];

% I = rgb2gray(I);
r = size(I, 1)
c = size(I, 2);
pad_I = [];
pad_r = r + 2; % size of padded fixed as a parameter for further use
pad_c = c + 2; % value is 10 here
%% Making of a padded version of I matrix
for q = 1 : pad_r  % Used for loop for this process as it will be easier to import it to verilog(no functions needed)
    for n = 1 : pad_c
        if (q>= 2) && (q<= pad_r-1) && (n>=2) && (n<= pad_c-1)
            pad_I(q, n) = I(q-1, n-1);
        
        else
            pad_I(q, n) = 0;
        end

    end
end

K = [1 2 1;
     2 4 2;
     1 2 1];
sum(K, 'all')
linebuff_kernel_window = zeros(kernel_size,kernel_size); % temporary matrix used in MAC operation to pick up from line buffer

counter_var_line_buff_fill=1;
Line_buff = zeros(kernel_size, pad_c);
done_var_line_buff= 0; % just like a fsm with states

% pending declaration of 2
row_image_index= 1;
col_image_index= 1;
insert_buff_col=1;
insert_buff_row= kernel_size+1;
temp_var_row = 1; % this is fine
temp_var_col = 1; % this is fine

output_I = zeros(size(I, 1), size(I, 2));
for i= 1: (size(I, 1) * size(I, 2)) 
    %% First we wait for the line buffer to get filled
    if (done_var_line_buff==0)
        for counter_var_line_buff_fill=1:(kernel_size*pad_c)
            Line_buff(temp_var_row, temp_var_col) = pad_I(temp_var_row, temp_var_col);
            if (temp_var_col<pad_c)
                temp_var_col=temp_var_col+1;
    
            else 
                temp_var_col=1;
                temp_var_row = temp_var_row+1;
            end

        end
        done_var_line_buff=1;
    end
    
    

    
    index_shift_linbuff_row = 1; % Used to shift the line buffer matrix which resets every loop for an element to 1
    index_shift_linbuff_col = 1;

    %% This is done to skip the invalid stageof the border columns. It can be implemented using counter/fsm like an inner pipeline inside the bigger pipeline(mips32)
    if (insert_buff_col == (pad_c-1)) || (insert_buff_col == (pad_c))
    for k = 1:2 
    for j = 1:(numel(Line_buff) - 1) % the value is 29. to shift the entire current line buffer matrix one bit towards the left for the next operation
        if index_shift_linbuff_col< pad_c
        Line_buff(index_shift_linbuff_row, index_shift_linbuff_col)= Line_buff(index_shift_linbuff_row, index_shift_linbuff_col+1);
        index_shift_linbuff_col=index_shift_linbuff_col +1;
        else  
        Line_buff(index_shift_linbuff_row, index_shift_linbuff_col)= Line_buff(index_shift_linbuff_row+1, 1);
        index_shift_linbuff_row = index_shift_linbuff_row+1; index_shift_linbuff_col = 1;
        end
    end
     if insert_buff_row <= pad_r && insert_buff_col <= pad_c  % difficult part here
     Line_buff(kernel_size,pad_c) = pad_I(insert_buff_row, insert_buff_col);
     end

     if (insert_buff_col< pad_c)
        insert_buff_col=insert_buff_col+1;
     else 
       insert_buff_col=1;
       insert_buff_row = insert_buff_row+1;
     end

     index_shift_linbuff_row = 1;
     index_shift_linbuff_col = 1;

    end

    end

    % no need of this temp matrix. Directly use 0 to 2 line_buff

    linebuff_kernel_window = Line_buff(1:kernel_size, 1:kernel_size);
    

    % no need of this matrix. simply sum = 0; sum = sum + (k[i] * linebuff[i]) in
    % for loop then divide by sum of all elements of K kernel. Sum needs to
    % be of 20bits
    temp_mul_matrix= K.*linebuff_kernel_window;
    pixel_summed= sum(temp_mul_matrix,"all")/sum(K, "all"); % MAC operation that is multiply, addition then average.
    
   
    output_I(row_image_index, col_image_index) =  pixel_summed;

    if (col_image_index< c)
        col_image_index = col_image_index+1;
    
    else 
       col_image_index= 1;
       row_image_index = row_image_index+1;
    end
   

    for j = 1:(numel(Line_buff) - 1) % the value is 29. to shift the entire current line buffer matrix one bit towards the left for the next operation
        if index_shift_linbuff_col< pad_c
        Line_buff(index_shift_linbuff_row, index_shift_linbuff_col)= Line_buff(index_shift_linbuff_row, index_shift_linbuff_col+1);
        index_shift_linbuff_col=index_shift_linbuff_col +1;
        else  
        Line_buff(index_shift_linbuff_row, index_shift_linbuff_col)= Line_buff(index_shift_linbuff_row+1, 1);
        index_shift_linbuff_row = index_shift_linbuff_row+1; index_shift_linbuff_col = 1;
        end
    end
     if insert_buff_row <= pad_r && insert_buff_col <= pad_c  % difficult part here
     Line_buff(kernel_size,pad_c) = pad_I(insert_buff_row, insert_buff_col);
     end

     if (insert_buff_col< pad_c)
        insert_buff_col=insert_buff_col+1;
     else 
       insert_buff_col=1;
       insert_buff_row = insert_buff_row+1;
     end

    
end

pad_I
output_I

Kn = K / sum(K(:));
out = conv2(I, Kn, 'same')

% possible if I pick up directly from the line_buffer matrix instead of
% making a new temp matrix. From line_buffer we can keep the index constant
% that is (1,1) as the line_buff shifts every index to the left so the (1,
% 1) is always updated regardless and pick up the surrounding 3*3 matrix
% and keeping the (1,1) as the centre like (1:1-1, 1:1+1)
% Display the original and processed images for comparison


% figure;
% subplot(1, 2, 1);
% imshow(I, []);
% title('Original Image');
% 
% subplot(1, 2, 2);
% imshow(output_I, []);
% title('Processed Image');
